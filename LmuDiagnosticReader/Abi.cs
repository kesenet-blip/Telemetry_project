namespace LmuDiagnosticReader;
internal static class Abi {
 // Studio 397 headers: Windows x64, #pragma pack(push,4).
 internal const int MaxVehicles=104, TelemSize=1888, WheelSize=260, VehicleScoringSize=584, ScoringInfoSize=548;
 internal const int ApplicationStateSize=260, GenericSize=336, PathsSize=1300;
 internal const int ScoringSize=ScoringInfoSize+8+MaxVehicles*VehicleScoringSize+65536;
 internal const int TelemetryOffset=GenericSize+PathsSize+ScoringSize; // 128464
 internal const int LayoutSize=TelemetryOffset+4+MaxVehicles*TelemSize; // 324820
 // TelemInfoV01 field offsets, generated from the supplied header with Pack=4.
 internal const int Id=0, Lap=20, VehicleName=32, TrackName=96, LocalVel=184, Gear=352;
 internal const int EngineRpm=356, MaxRpm=532, InputThrottle=388, InputBrake=396, InputSteering=404, InputClutch=412;
 internal const int Fuel=524, FuelCapacity=608, DeltaBest=696, LapInvalidated=746, AbsActive=747, TcActive=748;
 internal const int Tc=752, TcMax=753, Abs=758, AbsMax=759, Regen=768, Soc=772, VirtualEnergy=776;
 internal const int GapAhead=780, GapBehind=784, VehicleModel=796, CurrentSector=588;
}
