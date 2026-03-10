# Smart window flash/focus utility
# Detects VSCode vs terminal and acts on the correct window
param(
    [Parameter(Mandatory)]
    [ValidateSet('flash', 'check-focus')]
    [string]$Action,

    [string]$ProjectName,

    # Pre-resolved terminal window handle (optional, avoids re-detection)
    [long]$TermHwnd = 0
)

$helper = Join-Path $PSScriptRoot "claude-win-helper.exe"
$isVSCode = ($null -ne $env:VSCODE_PID) -or ($null -ne $env:VSCODE_IPC_HOOK_CLI) -or ($env:TERM_PROGRAM -eq 'vscode')

if ($isVSCode) {
    if ($Action -eq 'flash') {
        & $helper flash $ProjectName 2>$null
    } else {
        & $helper check-focus $ProjectName 2>$null | Out-Null
        exit $LASTEXITCODE
    }
    exit 0
}

# --- Terminal mode ---

Add-Type -ErrorAction SilentlyContinue @"
using System;
using System.Runtime.InteropServices;

public class WinApi {
    [StructLayout(LayoutKind.Sequential)]
    public struct FLASHWINFO {
        public uint cbSize;
        public IntPtr hwnd;
        public uint dwFlags;
        public uint uCount;
        public uint dwTimeout;
    }

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool FlashWindowEx(ref FLASHWINFO pwfi);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    public static void Flash(IntPtr hwnd) {
        if (hwnd == IntPtr.Zero) return;
        FLASHWINFO fw = new FLASHWINFO();
        fw.cbSize = (uint)Marshal.SizeOf(typeof(FLASHWINFO));
        fw.hwnd = hwnd;
        fw.dwFlags = 14; // FLASHW_ALL | FLASHW_TIMERNOFG
        fw.uCount = 5;
        fw.dwTimeout = 0;
        FlashWindowEx(ref fw);
    }

    public static bool IsFocused(IntPtr hwnd) {
        return GetForegroundWindow() == hwnd;
    }
}
"@

# Resolve terminal window handle if not pre-supplied
if ($TermHwnd -eq 0) {
    $currentPid = $PID
    for ($i = 0; $i -lt 15; $i++) {
        try {
            $proc = Get-Process -Id $currentPid -ErrorAction Stop
            if ($proc.MainWindowHandle -ne [IntPtr]::Zero) {
                $TermHwnd = $proc.MainWindowHandle.ToInt64()
                break
            }
            $parentPid = (Get-CimInstance Win32_Process -Filter "ProcessId = $currentPid" -ErrorAction Stop).ParentProcessId
            if (-not $parentPid -or $parentPid -eq $currentPid -or $parentPid -eq 0) { break }
            $currentPid = $parentPid
        } catch { break }
    }
}

if ($TermHwnd -eq 0) { exit 1 }

$hwndPtr = [IntPtr]::new($TermHwnd)

if ($Action -eq 'flash') {
    if (-not [WinApi]::IsFocused($hwndPtr)) {
        [WinApi]::Flash($hwndPtr)
    }
} else {
    # check-focus: exit 0 if focused, exit 1 if not
    if ([WinApi]::IsFocused($hwndPtr)) { exit 0 } else { exit 1 }
}
