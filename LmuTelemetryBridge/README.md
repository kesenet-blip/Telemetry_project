# LMU Telemetry Bridge

A diagnosztikai olvasó következő, tesztelhető rétege:

- valódi `LMU_Data` shared-memory forrás;
- LMU nélküli mock telemetria;
- lokális WebSocket API a későbbi Flutter klienshez;
- konzolos vagy JSON diagnosztika.

## Visual Studio 2022

Nyisd meg a `LmuTelemetryBridge.csproj` fájlt, majd válaszd az `x64` platformot.

## Teszt LMU nélkül

Project Properties -> Debug -> Open debug launch profiles UI, majd az argumentum:

```text
--mock
```

Parancssorból:

```powershell
dotnet run -- --mock
```

A mock forrás 20 Hz-cel generál életszerűen változó sebesség-, RPM-, gáz-, fék-, TC-, ABS- és energiaadatokat.

## WebSocket

```text
ws://127.0.0.1:8181/telemetry
```

Minden üzenet egy teljes JSON `TelemetrySnapshot`.

Állapotellenőrzés böngészőből:

```text
http://127.0.0.1:8181/health
```

Várt válasz:

```json
{"status":"ok","clients":0}
```

## Kapcsolók

```text
--mock          LMU helyett szimulált adat
--json          konzolos dashboard helyett JSON sorok
--no-console    nincs telemetria-kiírás, csak WebSocket
--port 8181     WebSocket/HTTP port
--hz 20         mock mintavétel 1..100 Hz
```

## Valódi LMU teszt

```powershell
dotnet run
```

A játék legyen sessionben, a játékos üljön autóban. Az alkalmazás előbb megnyitja az `LMU_Data` mappinget, majd a Hold/Data események és az LMU lock használatával olvas.

## Publish

```powershell
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true
```

## Első ellenőrzés

1. Indítsd `--mock` módban.
2. Nyisd meg a `http://127.0.0.1:8181/health` címet.
3. Nézd meg, hogy a konzolon változik a sebesség, RPM, gáz és fék.
4. Este ugyanazt az EXE-t indítsd `--mock` nélkül az LMU mellett.
