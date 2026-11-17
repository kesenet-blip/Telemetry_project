namespace LmuTelemetryBridge;

internal interface ITelemetrySource : IAsyncDisposable
{
    string Name { get; }
    Task InitializeAsync(CancellationToken cancellationToken);
    Task<TelemetrySnapshot?> ReadNextAsync(CancellationToken cancellationToken);
}
