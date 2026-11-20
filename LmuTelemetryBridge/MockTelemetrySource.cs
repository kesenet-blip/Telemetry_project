namespace LmuTelemetryBridge;

internal sealed class MockTelemetrySource : ITelemetrySource
{
    private readonly TimeSpan _interval;
    private readonly DateTimeOffset _started = DateTimeOffset.UtcNow;

    public MockTelemetrySource(int frequencyHz)
    {
        _interval = TimeSpan.FromMilliseconds(1000.0 / Math.Clamp(frequencyHz, 1, 100));
    }

    public string Name => "mock";

    public Task InitializeAsync(CancellationToken cancellationToken) => Task.CompletedTask;

    public async Task<TelemetrySnapshot?> ReadNextAsync(CancellationToken cancellationToken)
    {
        await Task.Delay(_interval, cancellationToken);
        var seconds = (DateTimeOffset.UtcNow - _started).TotalSeconds;
        var phase = seconds % 35.0;
        var throttle = phase < 19 ? Math.Min(1.0, phase / 3.0) : Math.Max(0.0, 1.0 - (phase - 19) / 2.0);
        var brake = phase is > 20 and < 24 ? Math.Sin((phase - 20) / 4.0 * Math.PI) : 0.0;
        var speed = Math.Clamp(55 + phase * 12 - brake * 145, 45, 335);
        var gear = speed switch { < 75 => 2, < 120 => 3, < 170 => 4, < 220 => 5, < 275 => 6, _ => 7 };
        var rpm = 4200 + (speed % 55) / 55.0 * 4300;
        var mockLapDuration = 15.0;
        var currentLapTime = seconds % mockLapDuration;

        const double lastLapTime = 207.842;
        const double bestLapTime = 205.327;

        const double sector1Time = 64.812;
        const double sector2Time = 74.221;
        const double sector3Time = 68.809;

        return new TelemetrySnapshot(
            DateTimeOffset.UtcNow, Name, 1, 37, "Mock Hypercar", "LMH Test Model", "Circuit de la Sarthe",
            3 + (int)(seconds / mockLapDuration), 1 + (int)(phase / 12) % 3, speed, gear, rpm, 9000,
            throttle, brake, Math.Sin(seconds * 0.7) * 0.35, 0, 62.4 - seconds * 0.015, 90,
            Math.Sin(seconds * 0.25) * 0.8, 4, 10, throttle > 0.9 && speed < 120,
            3, 8, brake > 0.55, 0.71 - seconds * 0.0003, brake * 180, 47.2,
            false, 1.842, 2.117,currentLapTime, lastLapTime, bestLapTime, sector1Time, sector2Time, sector3Time);
    }

    public ValueTask DisposeAsync() => ValueTask.CompletedTask;
}
