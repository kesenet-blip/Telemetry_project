using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

namespace LmuTelemetryBridge;

internal sealed unsafe class LmuSharedMemorySource : ITelemetrySource
{
    private SafeKernelHandle? _mapping;
    private SafeKernelHandle? _holdEvent;
    private SafeKernelHandle? _dataEvent;
    private SafeKernelHandle? _lockMapping;
    private SafeKernelHandle? _lockEvent;
    private nint _view;
    private nint _lockView;

    private struct LockData
    {
        public int Waiters;
        public int Busy;
    }

    public string Name => "lmu-shared-memory";

    public Task InitializeAsync(CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();

        _mapping = Native.OpenFileMappingW(Native.FileMapRead, false, "LMU_Data");
        Ensure(_mapping, "LMU_Data mapping");

        _view = Native.MapViewOfFile(_mapping!, Native.FileMapRead, 0, 0, LmuAbi.LayoutSize);
        if (_view == 0) ThrowLastError("MapViewOfFile(LMU_Data)");

        _holdEvent = Native.OpenEventA(Native.Synchronize, false, "LMU_Data_HoldEvent");
        Ensure(_holdEvent, "LMU_Data_HoldEvent");

        _dataEvent = Native.OpenEventA(Native.Synchronize, false, "LMU_Data_DataEvent");
        Ensure(_dataEvent, "LMU_Data_DataEvent");

        _lockMapping = Native.CreateFileMappingA(
            -1, 0, Native.PageReadWrite, 0, (uint)sizeof(LockData), "LMU_SharedMemoryLockData");
        Ensure(_lockMapping, "LMU_SharedMemoryLockData");

        var alreadyExists = Marshal.GetLastWin32Error() == 183;
        _lockView = Native.MapViewOfFile(
            _lockMapping!, Native.FileMapAllAccess, 0, 0, (nuint)sizeof(LockData));
        if (_lockView == 0) ThrowLastError("MapViewOfFile(LMU_SharedMemoryLockData)");

        if (!alreadyExists)
        {
            ((LockData*)_lockView)->Waiters = 0;
            ((LockData*)_lockView)->Busy = 0;
        }

        _lockEvent = Native.CreateEventA(0, false, false, "LMU_SharedMemoryLockEvent");
        Ensure(_lockEvent, "LMU_SharedMemoryLockEvent");

        return Task.CompletedTask;
    }

    public Task<TelemetrySnapshot?> ReadNextAsync(
    CancellationToken cancellationToken)
    {
        return Task.Run(() =>
        {
            while (!cancellationToken.IsCancellationRequested)
            {
                if (!WaitForFrame(200, cancellationToken))
                    continue;

                return ReadSnapshot();
            }

            return null;
        }, cancellationToken);
    }

    private bool WaitForFrame(uint timeoutMs, CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        if (Native.WaitForSingleObject(_holdEvent!, timeoutMs) != Native.WaitObject0) return false;
        cancellationToken.ThrowIfCancellationRequested();
        return Native.WaitForSingleObject(_dataEvent!, timeoutMs) == Native.WaitObject0;
    }

    private TelemetrySnapshot? ReadSnapshot()
    {
        if (!AcquireLock(100)) return null;

        try
        {
            var root = (byte*)_view;
            var telemetry = root + LmuAbi.TelemetryOffset;
            var activeVehicles = Math.Min((int)telemetry[0], LmuAbi.MaxVehicles);
            var playerIndex = (int)telemetry[1];
            var playerHasVehicle = telemetry[2] != 0;

            if (!playerHasVehicle || playerIndex >= activeVehicles) return null;

            var player = telemetry + 4 + playerIndex * LmuAbi.TelemetryInfoSize;
            var velocityX = ReadDouble(player, LmuAbi.LocalVelocity);
            var velocityY = ReadDouble(player, LmuAbi.LocalVelocity + 8);
            var velocityZ = ReadDouble(player, LmuAbi.LocalVelocity + 16);
            var speedKmh = Math.Sqrt(
                velocityX * velocityX + velocityY * velocityY + velocityZ * velocityZ) * 3.6;

            var elapsedTime = ReadDouble(
                player,
                LmuAbi.ElapsedTime);

            var lapStartEt = ReadDouble(
                player,
                LmuAbi.LapStartEt);

            double? currentLapTimeSeconds = null;

            if (elapsedTime >= 0 &&
                lapStartEt >= 0 &&
                elapsedTime >= lapStartEt)
            {
                currentLapTimeSeconds =
                    elapsedTime - lapStartEt;
            }

            return new TelemetrySnapshot(
                DateTimeOffset.UtcNow,
                Name,
                ReadInt32(player, LmuAbi.Id),
                activeVehicles,
                ReadString(player, LmuAbi.VehicleName, 64),
                ReadString(player, LmuAbi.VehicleModel, 30),
                ReadString(player, LmuAbi.TrackName, 64),
                ReadInt32(player, LmuAbi.Lap),
                ReadInt32(player, LmuAbi.CurrentSector) & 0x7fffffff,
                speedKmh,
                ReadInt32(player, LmuAbi.Gear),
                ReadDouble(player, LmuAbi.EngineRpm),
                ReadDouble(player, LmuAbi.EngineMaxRpm),
                ReadDouble(player, LmuAbi.Throttle),
                ReadDouble(player, LmuAbi.Brake),
                ReadDouble(player, LmuAbi.Steering),
                ReadDouble(player, LmuAbi.Clutch),
                ReadDouble(player, LmuAbi.Fuel),
                ReadDouble(player, LmuAbi.FuelCapacity),
                ReadDouble(player, LmuAbi.DeltaBest),
                player[LmuAbi.Tc],
                player[LmuAbi.TcMax],
                player[LmuAbi.TcActive] != 0,
                player[LmuAbi.Abs],
                player[LmuAbi.AbsMax],
                player[LmuAbi.AbsActive] != 0,
                ReadSingle(player, LmuAbi.StateOfCharge),
                ReadSingle(player, LmuAbi.Regen),
                ReadSingle(player, LmuAbi.VirtualEnergy),
                player[LmuAbi.LapInvalidated] != 0,
                ReadSingle(player, LmuAbi.GapAhead),
                ReadSingle(player, LmuAbi.GapBehind),

                // A valódi lapidők a scoring adatblokkból érkeznek majd.
                // Addig nem találunk ki LMU offseteket.
                currentLapTimeSeconds,
                null,
                null,
                null,
                null,
                null);
        }
        finally
        {
            ReleaseLock();
        }
    }

    private bool AcquireLock(uint timeoutMs)
    {
        var data = (LockData*)_lockView;

        for (var spin = 0; spin < 4000; spin++)
        {
            if (Interlocked.CompareExchange(ref data->Busy, 1, 0) == 0) return true;
            Thread.SpinWait(4);
        }

        Interlocked.Increment(ref data->Waiters);
        try
        {
            var started = Environment.TickCount64;
            while (true)
            {
                if (Interlocked.CompareExchange(ref data->Busy, 1, 0) == 0) return true;

                var elapsed = (uint)Math.Min(uint.MaxValue, Environment.TickCount64 - started);
                if (elapsed >= timeoutMs) return false;
                if (Native.WaitForSingleObject(_lockEvent!, timeoutMs - elapsed) != Native.WaitObject0) return false;
            }
        }
        finally
        {
            Interlocked.Decrement(ref data->Waiters);
        }
    }

    private void ReleaseLock()
    {
        var data = (LockData*)_lockView;
        Interlocked.Exchange(ref data->Busy, 0);
        if (Volatile.Read(ref data->Waiters) > 0) Native.SetEvent(_lockEvent!);
    }

    private static int ReadInt32(byte* pointer, int offset) => *(int*)(pointer + offset);
    private static double ReadDouble(byte* pointer, int offset) => *(double*)(pointer + offset);
    private static float ReadSingle(byte* pointer, int offset) => *(float*)(pointer + offset);

    private static string ReadString(byte* pointer, int offset, int maxLength)
    {
        var length = 0;
        while (length < maxLength && pointer[offset + length] != 0) length++;
        return Encoding.UTF8.GetString(pointer + offset, length);
    }

    private static void Ensure(SafeKernelHandle? handle, string operation)
    {
        if (handle is null || handle.IsInvalid) ThrowLastError(operation);
    }

    private static void ThrowLastError(string operation) =>
        throw new Win32Exception(Marshal.GetLastWin32Error(), operation);

    public ValueTask DisposeAsync()
    {
        if (_lockView != 0) Native.UnmapViewOfFile(_lockView);
        if (_view != 0) Native.UnmapViewOfFile(_view);
        _lockEvent?.Dispose();
        _lockMapping?.Dispose();
        _dataEvent?.Dispose();
        _holdEvent?.Dispose();
        _mapping?.Dispose();
        return ValueTask.CompletedTask;
    }
}
