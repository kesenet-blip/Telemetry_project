class TelemetryData {
  const TelemetryData({
    required this.speed,
    required this.rpm,
    required this.gear,
    required this.throttle,
    required this.brake,
    required this.delta,
    required this.vehicle,
    required this.vehicleModel,
    required this.track,
    required this.lap,
    required this.sector,
    required this.fuel,
    required this.fuelCapacity,
    required this.tc,
    required this.tcMax,
    required this.tcActive,
    required this.abs,
    required this.absMax,
    required this.absActive,
    required this.stateOfCharge,
    required this.regenKw,
    required this.virtualEnergy,
    required this.lapInvalidated,
    required this.gapAhead,
    required this.gapBehind,
    required this.activeVehicles,
  });

  // Basic telemetry
  final double speed;
  final int rpm;
  final String gear;

  final double throttle;
  final double brake;
  final double delta;

  // Vehicle / track
  final String vehicle;
  final String vehicleModel;
  final String track;

  // Lap
  final int lap;
  final int sector;

  // Fuel
  final double fuel;
  final double fuelCapacity;

  // Traction control
  final int tc;
  final int tcMax;
  final bool tcActive;

  // ABS
  final int abs;
  final int absMax;
  final bool absActive;

  // Hybrid / energy
  final double stateOfCharge;
  final double regenKw;
  final double virtualEnergy;

  // Lap status
  final bool lapInvalidated;

  // Traffic
  final double gapAhead;
  final double gapBehind;

  // Session
  final int activeVehicles;

  const TelemetryData.empty()
      : speed = 0,
        rpm = 0,
        gear = 'N',
        throttle = 0,
        brake = 0,
        delta = 0,
        vehicle = '',
        vehicleModel = '',
        track = '',
        lap = 0,
        sector = 0,
        fuel = 0,
        fuelCapacity = 0,
        tc = 0,
        tcMax = 0,
        tcActive = false,
        abs = 0,
        absMax = 0,
        absActive = false,
        stateOfCharge = 0,
        regenKw = 0,
        virtualEnergy = 0,
        lapInvalidated = false,
        gapAhead = 0,
        gapBehind = 0,
        activeVehicles = 0;
}