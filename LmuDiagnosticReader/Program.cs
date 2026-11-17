using System.Globalization;
using System.Text.Json;
using LmuDiagnosticReader;
Console.OutputEncoding=System.Text.Encoding.UTF8;
bool json=args.Contains("--json"); int interval=250; for(int i=0;i<args.Length-1;i++)if(args[i]=="--interval"&&int.TryParse(args[i+1],out var v))interval=Math.Clamp(v,50,5000);
if(args.Contains("--help")||args.Contains("-h")){Console.WriteLine("LmuDiagnosticReader [--json] [--interval 250]");return 0;}
Console.WriteLine($"LMU .NET 8 diagnosztikai olvasó | ABI: {Abi.LayoutSize} bájt, telemetry offset: {Abi.TelemetryOffset}");
using var cts=new CancellationTokenSource();Console.CancelKeyPress+=(_,e)=>{e.Cancel=true;cts.Cancel();};
try{using var r=new Reader();r.Connect();Console.WriteLine("Kapcsolódva. Ctrl+C: kilépés.");long last=0;while(!cts.IsCancellationRequested){if(!r.Wait(200,cts.Token))continue;long now=Environment.TickCount64;if(now-last<interval)continue;var s=r.Snapshot();if(s is null)continue;last=now;if(json)Console.WriteLine(JsonSerializer.Serialize(s));else Print(s);}}
catch(OperationCanceledException){}catch(Exception ex){Console.Error.WriteLine($"HIBA: {ex.Message}");return 1;}return 0;
static void Print(Snapshot s){Console.Clear();Console.WriteLine("LMU LIVE TELEMETRIA\n"+new string('=',52));Console.WriteLine($"Autó: {s.Vehicle} ({s.Model}) [ID {s.VehicleId}]\nPálya: {s.Track} | aktív autók: {s.ActiveVehicles}\nKör/szektor: {s.Lap}/{s.Sector+1}\nSebesség: {s.SpeedKmh:F1} km/h | fokozat: {Gear(s.Gear)} | RPM: {s.Rpm:F0}/{s.MaxRpm:F0}\nGáz: {s.Throttle:P1} | fék: {s.Brake:P1} | kormány: {s.Steering:P1} | kuplung: {s.Clutch:P1}\nÜzemanyag: {s.Fuel:F2}/{s.FuelCapacity:F2} l | delta: {s.DeltaBest:+0.000;-0.000;0.000} s\nTC: {s.Tc}/{s.TcMax} aktív={s.TcActive} | ABS: {s.Abs}/{s.AbsMax} aktív={s.AbsActive}\nSoC: {s.StateOfCharge:P1} | regen: {s.RegenKw:F1} kW | virt. energia: {s.VirtualEnergy:F2}\nGap előtt/mögött: {s.GapAhead:F3}/{s.GapBehind:F3} s | invalid lap: {s.LapInvalidated}\n\nCtrl+C: kilépés");}
static string Gear(int g)=>g switch{-1=>"R",0=>"N",_=>g.ToString(CultureInfo.InvariantCulture)};
