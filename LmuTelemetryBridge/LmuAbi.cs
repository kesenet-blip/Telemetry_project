namespace LmuTelemetryBridge;

internal static class LmuAbi
{
    internal const int MaxVehicles = 104;
    internal const int TelemetryInfoSize = 1888;
    internal const int VehicleScoringInfoSize = 584;
    internal const int ScoringInfoSize = 548;
    internal const int ApplicationStateSize = 260;
    internal const int GenericSize = 336;
    internal const int PathsSize = 1300;
    internal const int ScoringSize = ScoringInfoSize + 8 + MaxVehicles * VehicleScoringInfoSize + 65536;
    internal const int TelemetryOffset = GenericSize + PathsSize + ScoringSize;
    internal const int LayoutSize = TelemetryOffset + 4 + MaxVehicles * TelemetryInfoSize;

    internal const int Id = 0;
    internal const int ElapsedTime = 12;
    internal const int Lap = 20;
    internal const int LapStartEt = 24;
    internal const int VehicleName = 32;
    internal const int TrackName = 96;
    internal const int LocalVelocity = 184;
    internal const int Gear = 352;
    internal const int EngineRpm = 356;
    internal const int Throttle = 388;
    internal const int Brake = 396;
    internal const int Steering = 404;
    internal const int Clutch = 412;
    internal const int Fuel = 524;
    internal const int EngineMaxRpm = 532;
    internal const int CurrentSector = 588;
    internal const int FuelCapacity = 608;
    internal const int DeltaBest = 696;
    internal const int LapInvalidated = 746;
    internal const int AbsActive = 747;
    internal const int TcActive = 748;
    internal const int Tc = 752;
    internal const int TcMax = 753;
    internal const int Abs = 758;
    internal const int AbsMax = 759;
    internal const int Regen = 768;
    internal const int StateOfCharge = 772;
    internal const int VirtualEnergy = 776;
    internal const int GapAhead = 780;
    internal const int GapBehind = 784;
    internal const int VehicleModel = 796;
}
