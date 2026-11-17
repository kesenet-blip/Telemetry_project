using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
namespace LmuDiagnosticReader;
internal static class Native {
 internal const uint SYNCHRONIZE=0x00100000, FILE_MAP_READ=4, FILE_MAP_ALL_ACCESS=0x001f, PAGE_READWRITE=4, WAIT_OBJECT_0=0;
 [DllImport("kernel32.dll",SetLastError=true,CharSet=CharSet.Unicode)] internal static extern SafeKernelHandle OpenFileMappingW(uint a,bool i,string n);
 [DllImport("kernel32.dll",SetLastError=true,CharSet=CharSet.Ansi)] internal static extern SafeKernelHandle CreateFileMappingA(nint f,nint sa,uint p,uint hi,uint lo,string n);
 [DllImport("kernel32.dll",SetLastError=true)] internal static extern nint MapViewOfFile(SafeKernelHandle h,uint a,uint hi,uint lo,nuint bytes);
 [DllImport("kernel32.dll",SetLastError=true)] [return:MarshalAs(UnmanagedType.Bool)] internal static extern bool UnmapViewOfFile(nint p);
 [DllImport("kernel32.dll",SetLastError=true,CharSet=CharSet.Ansi)] internal static extern SafeKernelHandle OpenEventA(uint a,bool i,string n);
 [DllImport("kernel32.dll",SetLastError=true,CharSet=CharSet.Ansi)] internal static extern SafeKernelHandle CreateEventA(nint sa,bool manual,bool initial,string n);
 [DllImport("kernel32.dll",SetLastError=true)] internal static extern uint WaitForSingleObject(SafeKernelHandle h,uint ms);
 [DllImport("kernel32.dll",SetLastError=true)] [return:MarshalAs(UnmanagedType.Bool)] internal static extern bool SetEvent(SafeKernelHandle h);
 [DllImport("kernel32.dll")] internal static extern int InterlockedCompareExchange(ref int d,int e,int c);
 [DllImport("kernel32.dll")] internal static extern int InterlockedExchange(ref int d,int v);
 [DllImport("kernel32.dll")] internal static extern int InterlockedIncrement(ref int d);
 [DllImport("kernel32.dll")] internal static extern int InterlockedDecrement(ref int d);
}
internal sealed class SafeKernelHandle:SafeHandleZeroOrMinusOneIsInvalid {
 private SafeKernelHandle():base(true){} protected override bool ReleaseHandle()=>CloseHandle(handle);
 [DllImport("kernel32.dll",SetLastError=true)] [return:MarshalAs(UnmanagedType.Bool)] static extern bool CloseHandle(nint h);
}
