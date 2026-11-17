namespace LmuTelemetryBridge;

internal sealed record AppOptions(bool Mock, bool Json, bool Console, int Port, int FrequencyHz)
{
    public static AppOptions Parse(string[] args)
    {
        var mock = args.Contains("--mock");
        var json = args.Contains("--json");
        var console = !args.Contains("--no-console");
        var port = ReadInt(args, "--port", 8181, 1024, 65535);
        var frequency = ReadInt(args, "--hz", 20, 1, 100);
        return new AppOptions(mock, json, console, port, frequency);
    }

    private static int ReadInt(string[] args, string name, int fallback, int min, int max)
    {
        for (var i = 0; i < args.Length - 1; i++)
        {
            if (args[i] == name && int.TryParse(args[i + 1], out var value))
                return Math.Clamp(value, min, max);
        }
        return fallback;
    }
}
