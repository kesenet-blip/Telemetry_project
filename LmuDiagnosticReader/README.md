# LMU .NET 8 diagnosztikai olvasó

Windows x64 konzolalkalmazás a Le Mans Ultimate hivatalos `LMU_Data` shared-memory interfészéhez.

## Fordítás és futtatás

```powershell
dotnet restore
dotnet build -c Release
dotnet run -c Release
```

Az LMU legyen futásban, legyen betöltött session, és a játékos üljön autóban.

JSON napló 100 ms-os kiírással:

```powershell
dotnet run -c Release -- --json --interval 100
```

Önálló EXE:

```powershell
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true
```

## Mit implementál

- `LMU_Data` read-only mapping
- `LMU_Data_HoldEvent` majd `LMU_Data_DataEvent` sorrend
- hivatalos `LMU_SharedMemoryLockData` és `LMU_SharedMemoryLockEvent` lock
- `#pragma pack(4)` szerinti Windows x64 ABI-offsetek
- maximum 104 autó és játékosindex ellenőrzése
- konzolos és soronkénti JSON kimenet

## Fontos

A projektet Linux környezetben csomagoltuk, ahol a .NET SDK nem volt telepítve, ezért itt nem lehetett lefordítani. Windows alatt a fenti `dotnet build -c Release` paranccsal fordítsd. Az ABI-konstansok a bemásolt 2025-ös Studio 397 headerekből származnak.
