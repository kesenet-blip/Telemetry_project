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

    // SharedMemoryScoringData:
    // ScoringInfoV01
    // size_t scoringStreamSize (Windows x64: 8 byte)
    // VehicleScoringInfoV01[104]
    // scoringStream[65536]
    internal const int ScoringStreamSizeFieldSize = 8;

    internal const int ScoringOffset =
        GenericSize + PathsSize;

    internal const int ScoringVehiclesOffset =
        ScoringOffset +
        ScoringInfoSize +
        ScoringStreamSizeFieldSize;

    internal const int ScoringSize =
        ScoringInfoSize +
        ScoringStreamSizeFieldSize +
        MaxVehicles * VehicleScoringInfoSize +
        65536;

    internal const int TelemetryOffset =
        GenericSize +
        PathsSize +
        ScoringSize;

    internal const int LayoutSize =
        TelemetryOffset +
        4 +
        MaxVehicles * TelemetryInfoSize;

    // ---------------------------------------------------------
    // ScoringInfoV01 offsets
    // ---------------------------------------------------------

    internal const int ScoringTrackName = 0;
    internal const int ScoringSession = 64;
    internal const int ScoringCurrentEt = 68;
    internal const int ScoringEndEt = 76;
    internal const int ScoringMaxLaps = 84;
    internal const int ScoringTrackLength = 88;
    internal const int ScoringResultsStreamPointer = 96;
    internal const int ScoringNumVehicles = 104;

    // ---------------------------------------------------------
    // VehicleScoringInfoV01 offsets
    // ---------------------------------------------------------

    internal const int ScoringVehicleId = 0;
    internal const int ScoringDriverName = 4;
    internal const int ScoringVehicleName = 36;
    internal const int ScoringTotalLaps = 100;
    internal const int ScoringSector = 102;
    internal const int ScoringFinishStatus = 103;
    internal const int ScoringLapDistance = 104;
    internal const int ScoringPathLateral = 112;
    internal const int ScoringTrackEdge = 120;

    // Sector 2 values are cumulative:
    // sector 1 + sector 2.
    internal const int ScoringBestSector1 = 128;
    internal const int ScoringBestSector2Cumulative = 136;
    internal const int ScoringBestLapTime = 144;

    internal const int ScoringLastSector1 = 152;
    internal const int ScoringLastSector2Cumulative = 160;
    internal const int ScoringLastLapTime = 168;

    internal const int ScoringCurrentSector1 = 176;
    internal const int ScoringCurrentSector2Cumulative = 184;

    // ---------------------------------------------------------
    // TelemInfoV01 offsets
    // ---------------------------------------------------------

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