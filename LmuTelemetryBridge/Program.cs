using System.Globalization;
using System.Net;
using System.Text.Json;
using LmuTelemetryBridge;

Console.OutputEncoding = System.Text.Encoding.UTF8;

var options = AppOptions.Parse(args);

using var shutdown = new CancellationTokenSource();

Console.CancelKeyPress += (_, eventArgs) =>
{
    eventArgs.Cancel = true;
    shutdown.Cancel();
};

await using ITelemetrySource source = options.Mock
    ? new MockTelemetrySource(options.FrequencyHz)
    : new LmuSharedMemorySource();

await using var server = new WebSocketBroadcastServer(
    options.BindAddress,
    options.Port);

try
{
    await source.InitializeAsync(shutdown.Token);
    await server.StartAsync(shutdown.Token);

    Console.WriteLine(
        "LMU Telemetry Bridge (.NET 8 / Windows x64)");

    Console.WriteLine($"Forrás: {source.Name}");

    Console.WriteLine(
        $"Bind cím: {server.DisplayAddress}:{server.Port}");

    Console.WriteLine(
        $"WebSocket: ws://{server.DisplayAddress}:{server.Port}/telemetry");

    Console.WriteLine(
        $"Health: http://{server.DisplayAddress}:{server.Port}/health");

    if (server.BindAddress is "*" or "+")
    {
        Console.WriteLine(
            "Hálózati mód aktív. A kliensben a játékos PC tényleges LAN IP-címét használd.");
    }

    Console.WriteLine("Ctrl+C: kilépés\n");

    while (!shutdown.IsCancellationRequested)
    {
        var snapshot = await source.ReadNextAsync(
            shutdown.Token);

        if (snapshot is null)
            continue;

        await server.BroadcastAsync(
            snapshot,
            shutdown.Token);

        if (options.Json)
        {
            Console.WriteLine(
                JsonSerializer.Serialize(snapshot));
        }
        else if (options.Console)
        {
            PrintDashboard(
                snapshot,
                server.ClientCount);
        }
    }
}
catch (OperationCanceledException)
{
}
catch (HttpListenerException exception)
{
    Console.Error.WriteLine(
        $"HÁLÓZATI HIBA: {exception.Message}");

    Console.Error.WriteLine(
        "Ha --bind * használatakor Access is denied hiba jelenik meg, indítsd a terminált rendszergazdaként.");

    return 2;
}
catch (Exception exception)
{
    Console.Error.WriteLine(
        $"HIBA: {exception.Message}");

    return 1;
}

return 0;

static void PrintDashboard(
    TelemetrySnapshot snapshot,
    int clients)
{
    Console.Clear();

    Console.WriteLine("LMU TELEMETRY BRIDGE");
    Console.WriteLine(new string('=', 58));

    Console.WriteLine(
        $"Forrás: {snapshot.Source} | WebSocket kliensek: {clients}");

    Console.WriteLine(
        $"Autó: {snapshot.Vehicle} ({snapshot.Model}) [ID {snapshot.VehicleId}]");

    Console.WriteLine(
        $"Pálya: {snapshot.Track} | Aktív autók: {snapshot.ActiveVehicles}");

    Console.WriteLine(
        $"Kör/szektor: {snapshot.Lap}/{snapshot.Sector + 1}");

    Console.WriteLine(
        $"Sebesség: {snapshot.SpeedKmh,7:F1} km/h | fokozat: {Gear(snapshot.Gear)}");

    Console.WriteLine(
        $"RPM: {snapshot.Rpm,7:F0}/{snapshot.MaxRpm:F0}");

    Console.WriteLine(
        $"Gáz: {snapshot.Throttle,6:P1} | fék: {snapshot.Brake,6:P1} | kormány: {snapshot.Steering,7:P1}");

    Console.WriteLine(
        $"Üzemanyag: {snapshot.Fuel,7:F2}/{snapshot.FuelCapacity:F2} l | delta: {snapshot.DeltaBest,+7:0.000;-7:0.000;0.000} s");

    Console.WriteLine(
        $"TC: {snapshot.Tc}/{snapshot.TcMax} aktív={snapshot.TcActive} | ABS: {snapshot.Abs}/{snapshot.AbsMax} aktív={snapshot.AbsActive}");

    Console.WriteLine(
        $"SoC: {snapshot.StateOfCharge,6:P1} | regen: {snapshot.RegenKw,7:F1} kW | virtuális energia: {snapshot.VirtualEnergy:F2}");

    Console.WriteLine(
        $"Gap előtt/mögött: {snapshot.GapAhead:F3}/{snapshot.GapBehind:F3} s | invalid lap: {snapshot.LapInvalidated}");

    Console.WriteLine("\nCtrl+C: kilépés");
}

static string Gear(int gear) => gear switch
{
    -1 => "R",
    0 => "N",
    _ => gear.ToString(
        CultureInfo.InvariantCulture)
};