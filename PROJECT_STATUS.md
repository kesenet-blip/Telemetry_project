# Racing Data Analyzer - Project Status

## Jelenlegi architektúra

```text
Le Mans Ultimate
  -> LMU_Data shared memory
  -> .NET 8 LmuTelemetryBridge
  -> WebSocket: ws://127.0.0.1:8181/telemetry
  -> Flutter + Riverpod
  -> Windows dashboard
```

## Elkészült

- .NET 8 Windows x64 shared-memory olvasó az LMU hivatalos interfészéhez.
- Mock telemetria az LMU nélküli fejlesztéshez.
- Lokális WebSocket bridge és `/health` végpont.
- Flutter WebSocket kliens és Riverpod provider.
- Kibővített `TelemetryData` modell.
- Kibővített, görgethető dashboard.
- Működő mock -> WebSocket -> Flutter adatfolyam.
- Hordozható Release build a bridge-ből és a dashboardból.

## Következő teszt

1. LMU indítása, session betöltése, autóba ülés.
2. `LmuTelemetryBridge.exe` indítása `--mock` nélkül.
3. Flutter dashboard indítása.
4. `LIVE LMU` gomb megnyomása.
5. Elsőként ellenőrizendő: Speed, RPM, Gear, Throttle, Brake.
6. Utána: Vehicle, Track, Lap, Sector, Fuel, Delta, TC, ABS, SoC, Regen, Gap és Lap Status.

## Következő fejlesztési mérföldkő

A valódi LMU adatkapcsolat ellenőrzése után:

```text
Session -> Laps -> Telemetry samples -> SQLite
```

Ezután következhet a kör- és szektorösszehasonlítás, féktáv-, minimumsebesség-, kigyorsítás- és időveszteség-elemzés.
