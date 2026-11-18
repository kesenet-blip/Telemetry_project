using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;

namespace LmuTelemetryBridge;

internal static class Native
{
    internal const uint Synchronize = 0x00100000;
    internal const uint FileMapRead = 0x0004;
    internal const uint FileMapAllAccess = 0x001f;
    internal const uint PageReadWrite = 0x04;
    internal const uint WaitObject0 = 0;

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    internal static extern SafeKernelHandle OpenFileMappingW(
        uint access,
        bool inheritHandle,
        string name);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Ansi)]
    internal static extern SafeKernelHandle CreateFileMappingA(
        nint file,
        nint attributes,
        uint protect,
        uint maximumSizeHigh,
        uint maximumSizeLow,
        string name);

    [DllImport("kernel32.dll", SetLastError = true)]
    internal static extern nint MapViewOfFile(
        SafeKernelHandle mapping,
        uint access,
        uint offsetHigh,
        uint offsetLow,
        nuint numberOfBytesToMap);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern bool UnmapViewOfFile(nint baseAddress);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Ansi)]
    internal static extern SafeKernelHandle OpenEventA(
        uint desiredAccess,
        bool inheritHandle,
        string name);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Ansi)]
    internal static extern SafeKernelHandle CreateEventA(
        nint eventAttributes,
        bool manualReset,
        bool initialState,
        string name);

    [DllImport("kernel32.dll", SetLastError = true)]
    internal static extern uint WaitForSingleObject(
        SafeKernelHandle handle,
        uint milliseconds);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern bool SetEvent(SafeKernelHandle handle);
}

internal sealed class SafeKernelHandle : SafeHandleZeroOrMinusOneIsInvalid
{
    private SafeKernelHandle() : base(true)
    {
    }

    protected override bool ReleaseHandle() => CloseHandle(handle);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool CloseHandle(nint handle);
}