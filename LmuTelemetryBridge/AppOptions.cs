namespace LmuTelemetryBridge;

internal sealed record AppOptions(
    bool Mock,
    bool Json,
    bool Console,
    string BindAddress,
    int Port,
    int FrequencyHz)
{
    public static AppOptions Parse(string[] args)
    {
        var mock = args.Contains("--mock");
        var json = args.Contains("--json");
        var console = !args.Contains("--no-console");

        var bindAddress = ReadString(
            args,
            "--bind",
            "127.0.0.1");

        var port = ReadInt(
            args,
            "--port",
            8181,
            1024,
            65535);

        var frequency = ReadInt(
            args,
            "--hz",
            20,
            1,
            100);

        return new AppOptions(
            mock,
            json,
            console,
            bindAddress,
            port,
            frequency);
    }

    private static string ReadString(
        string[] args,
        string name,
        string fallback)
    {
        for (var i = 0; i < args.Length - 1; i++)
        {
            if (args[i].Equals(name, StringComparison.OrdinalIgnoreCase))
            {
                var value = args[i + 1].Trim();

                if (!string.IsNullOrWhiteSpace(value))
                    return value;
            }
        }

        return fallback;
    }

    private static int ReadInt(
        string[] args,
        string name,
        int fallback,
        int min,
        int max)
    {
        for (var i = 0; i < args.Length - 1; i++)
        {
            if (args[i].Equals(name, StringComparison.OrdinalIgnoreCase) &&
                int.TryParse(args[i + 1], out var value))
            {
                return Math.Clamp(value, min, max);
            }
        }

        return fallback;
    }
}