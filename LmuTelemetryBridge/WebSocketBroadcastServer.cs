using System.Collections.Concurrent;
using System.Net;
using System.Net.WebSockets;
using System.Text;
using System.Text.Json;

namespace LmuTelemetryBridge;

internal sealed class WebSocketBroadcastServer : IAsyncDisposable
{
    private readonly HttpListener _listener = new();
    private readonly ConcurrentDictionary<Guid, WebSocket> _clients = new();
    private readonly JsonSerializerOptions _jsonOptions =
        new(JsonSerializerDefaults.Web);

    private CancellationTokenSource? _serverCts;
    private Task? _acceptLoop;

    public WebSocketBroadcastServer(string bindAddress, int port)
    {
        BindAddress = NormalizeBindAddress(bindAddress);
        Port = port;

        _listener.Prefixes.Add(
            $"http://{BindAddress}:{Port}/");
    }

    public string BindAddress { get; }

    public int Port { get; }

    public int ClientCount => _clients.Count;

    public string DisplayAddress =>
        BindAddress is "*" or "+"
            ? "0.0.0.0"
            : BindAddress;

    public Task StartAsync(CancellationToken cancellationToken)
    {
        _serverCts =
            CancellationTokenSource.CreateLinkedTokenSource(
                cancellationToken);

        _listener.Start();

        _acceptLoop = AcceptLoopAsync(_serverCts.Token);

        return Task.CompletedTask;
    }

    private async Task AcceptLoopAsync(
        CancellationToken cancellationToken)
    {
        while (!cancellationToken.IsCancellationRequested)
        {
            HttpListenerContext context;

            try
            {
                context = await _listener
                    .GetContextAsync()
                    .WaitAsync(cancellationToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (HttpListenerException)
                when (cancellationToken.IsCancellationRequested)
            {
                break;
            }

            if (context.Request.Url?.AbsolutePath == "/health")
            {
                await WriteHealthResponseAsync(
                    context,
                    cancellationToken);

                continue;
            }

            if (context.Request.Url?.AbsolutePath != "/telemetry" ||
                !context.Request.IsWebSocketRequest)
            {
                context.Response.StatusCode =
                    (int)HttpStatusCode.NotFound;

                context.Response.Close();
                continue;
            }

            try
            {
                var webSocketContext =
                    await context.AcceptWebSocketAsync(null);

                var id = Guid.NewGuid();

                _clients[id] = webSocketContext.WebSocket;

                _ = ObserveClientAsync(
                    id,
                    webSocketContext.WebSocket,
                    cancellationToken);
            }
            catch (WebSocketException)
            {
                context.Response.StatusCode =
                    (int)HttpStatusCode.BadRequest;

                context.Response.Close();
            }
        }
    }

    private async Task WriteHealthResponseAsync(
        HttpListenerContext context,
        CancellationToken cancellationToken)
    {
        var health = new
        {
            status = "ok",
            clients = ClientCount,
            bindAddress = DisplayAddress,
            port = Port,
            timestamp = DateTimeOffset.UtcNow
        };

        var body = JsonSerializer.SerializeToUtf8Bytes(
            health,
            _jsonOptions);

        context.Response.StatusCode =
            (int)HttpStatusCode.OK;

        context.Response.ContentType =
            "application/json; charset=utf-8";

        context.Response.ContentLength64 =
            body.Length;

        await context.Response.OutputStream.WriteAsync(
            body,
            cancellationToken);

        context.Response.Close();
    }

    private async Task ObserveClientAsync(
        Guid id,
        WebSocket socket,
        CancellationToken cancellationToken)
    {
        var buffer = new byte[256];

        try
        {
            while (socket.State == WebSocketState.Open &&
                   !cancellationToken.IsCancellationRequested)
            {
                var result = await socket.ReceiveAsync(
                    buffer,
                    cancellationToken);

                if (result.MessageType ==
                    WebSocketMessageType.Close)
                {
                    break;
                }
            }
        }
        catch (OperationCanceledException)
        {
        }
        catch (WebSocketException)
        {
        }
        finally
        {
            _clients.TryRemove(id, out _);

            if (socket.State is
                WebSocketState.Open or
                WebSocketState.CloseReceived)
            {
                try
                {
                    await socket.CloseAsync(
                        WebSocketCloseStatus.NormalClosure,
                        "closed",
                        CancellationToken.None);
                }
                catch
                {
                }
            }

            socket.Dispose();
        }
    }

    public async Task BroadcastAsync(
        TelemetrySnapshot snapshot,
        CancellationToken cancellationToken)
    {
        if (_clients.IsEmpty)
            return;

        var payload = JsonSerializer.SerializeToUtf8Bytes(
            snapshot,
            _jsonOptions);

        var segment = new ArraySegment<byte>(payload);

        foreach (var pair in _clients.ToArray())
        {
            try
            {
                if (pair.Value.State == WebSocketState.Open)
                {
                    await pair.Value.SendAsync(
                        segment,
                        WebSocketMessageType.Text,
                        true,
                        cancellationToken);
                }
            }
            catch (WebSocketException)
            {
                _clients.TryRemove(pair.Key, out _);
                pair.Value.Dispose();
            }
        }
    }

    public async ValueTask DisposeAsync()
    {
        _serverCts?.Cancel();
        _listener.Stop();

        if (_acceptLoop is not null)
        {
            try
            {
                await _acceptLoop;
            }
            catch
            {
            }
        }

        foreach (var socket in _clients.Values)
            socket.Dispose();

        _clients.Clear();
        _listener.Close();
        _serverCts?.Dispose();
    }

    private static string NormalizeBindAddress(string value)
    {
        var normalized = value.Trim();

        if (normalized.Equals(
                "0.0.0.0",
                StringComparison.OrdinalIgnoreCase) ||
            normalized.Equals(
                "all",
                StringComparison.OrdinalIgnoreCase))
        {
            return "*";
        }

        if (normalized.Contains("://", StringComparison.Ordinal))
        {
            throw new ArgumentException(
                "--bind esetén csak hostnevet, IP-címet vagy * karaktert adj meg.");
        }

        if (normalized.Contains('/') ||
            normalized.Contains('\\'))
        {
            throw new ArgumentException(
                "Érvénytelen --bind cím.");
        }

        return normalized;
    }
}