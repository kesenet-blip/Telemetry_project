using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;
namespace LmuDiagnosticReader;
internal sealed unsafe class Reader:IDisposable {
 SafeKernelHandle? map,hold,data,lockMap,lockEvent; nint view,lockView;
 struct LockData { public int Waiters,Busy; }
 public void Connect(){
  map=Native.OpenFileMappingW(Native.FILE_MAP_READ,false,"LMU_Data"); Check(map,"LMU_Data mapping");
  view=Native.MapViewOfFile(map!,Native.FILE_MAP_READ,0,0,Abi.LayoutSize); if(view==0) Fail("MapViewOfFile(LMU_Data)");
  hold=Native.OpenEventA(Native.SYNCHRONIZE,false,"LMU_Data_HoldEvent"); Check(hold,"LMU_Data_HoldEvent");
  data=Native.OpenEventA(Native.SYNCHRONIZE,false,"LMU_Data_DataEvent"); Check(data,"LMU_Data_DataEvent");
  lockMap=Native.CreateFileMappingA(-1,0,Native.PAGE_READWRITE,0,8,"LMU_SharedMemoryLockData"); Check(lockMap,"lock mapping");
  var existed=Marshal.GetLastWin32Error()==183; lockView=Native.MapViewOfFile(lockMap!,Native.FILE_MAP_ALL_ACCESS,0,0,8); if(lockView==0) Fail("MapViewOfFile(lock)");
  if(!existed){((LockData*)lockView)->Waiters=0;((LockData*)lockView)->Busy=0;}
  lockEvent=Native.CreateEventA(0,false,false,"LMU_SharedMemoryLockEvent"); Check(lockEvent,"lock event");
 }
 public bool Wait(uint ms,CancellationToken t){t.ThrowIfCancellationRequested();if(Native.WaitForSingleObject(hold!,ms)!=0)return false;t.ThrowIfCancellationRequested();return Native.WaitForSingleObject(data!,ms)==0;}
 public Snapshot? Snapshot(){if(!Acquire(100))return null;try{
  byte* root=(byte*)view; byte* tm=root+Abi.TelemetryOffset; int active = Math.Min((int)tm[0], Abi.MaxVehicles); int idx=tm[1]; if(tm[2]==0||idx>=active)return null;
  byte* p=tm+4+idx*Abi.TelemSize;
  double vx=D(p,Abi.LocalVel),vy=D(p,Abi.LocalVel+8),vz=D(p,Abi.LocalVel+16);
  return new Snapshot(I(p,Abi.Id),active,S(p,Abi.VehicleName,64),S(p,Abi.VehicleModel,30),S(p,Abi.TrackName,64),I(p,Abi.Lap),I(p,Abi.CurrentSector)&0x7fffffff,Math.Sqrt(vx*vx+vy*vy+vz*vz)*3.6,I(p,Abi.Gear),D(p,Abi.EngineRpm),D(p,Abi.MaxRpm),D(p,Abi.InputThrottle),D(p,Abi.InputBrake),D(p,Abi.InputSteering),D(p,Abi.InputClutch),D(p,Abi.Fuel),D(p,Abi.FuelCapacity),D(p,Abi.DeltaBest),p[Abi.Tc],p[Abi.TcMax],p[Abi.TcActive]!=0,p[Abi.Abs],p[Abi.AbsMax],p[Abi.AbsActive]!=0,F(p,Abi.Soc),F(p,Abi.Regen),F(p,Abi.VirtualEnergy),p[Abi.LapInvalidated]!=0,F(p,Abi.GapAhead),F(p,Abi.GapBehind));
 }finally{Release();}}
 bool Acquire(uint timeout){var l=(LockData*)lockView;for(int i=0;i<4000;i++){if(Native.InterlockedCompareExchange(ref l->Busy,1,0)==0)return true;Thread.SpinWait(4);}Native.InterlockedIncrement(ref l->Waiters);try{long start=Environment.TickCount64;while(true){if(Native.InterlockedCompareExchange(ref l->Busy,1,0)==0)return true;uint e=(uint)Math.Min(uint.MaxValue,Environment.TickCount64-start);if(e>=timeout)return false;if(Native.WaitForSingleObject(lockEvent!,timeout-e)!=0)return false;}}finally{Native.InterlockedDecrement(ref l->Waiters);}}
 void Release(){var l=(LockData*)lockView;Native.InterlockedExchange(ref l->Busy,0);if(Volatile.Read(ref l->Waiters)>0)Native.SetEvent(lockEvent!);}
 static int I(byte*p,int o)=>*(int*)(p+o);static double D(byte*p,int o)=>*(double*)(p+o);static float F(byte*p,int o)=>*(float*)(p+o);
 static string S(byte*p,int o,int n){int l=0;while(l<n&&p[o+l]!=0)l++;return Encoding.UTF8.GetString(p+o,l);}
 static void Check(SafeKernelHandle? h,string op){if(h is null||h.IsInvalid)Fail(op);}static void Fail(string op)=>throw new Win32Exception(Marshal.GetLastWin32Error(),op);
 public void Dispose(){if(lockView!=0)Native.UnmapViewOfFile(lockView);if(view!=0)Native.UnmapViewOfFile(view);lockEvent?.Dispose();lockMap?.Dispose();data?.Dispose();hold?.Dispose();map?.Dispose();}
}
internal sealed record Snapshot(int VehicleId,int ActiveVehicles,string Vehicle,string Model,string Track,int Lap,int Sector,double SpeedKmh,int Gear,double Rpm,double MaxRpm,double Throttle,double Brake,double Steering,double Clutch,double Fuel,double FuelCapacity,double DeltaBest,byte Tc,byte TcMax,bool TcActive,byte Abs,byte AbsMax,bool AbsActive,double StateOfCharge,double RegenKw,double VirtualEnergy,bool LapInvalidated,double GapAhead,double GapBehind);
