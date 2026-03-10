using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;

/// <summary>
/// Small helper for Claude Code hooks to avoid dynamic Add-Type compilation
/// which triggers antivirus false positives.
///
/// Usage:
///   claude-win-helper.exe check-focus &lt;projectName&gt;
///     Exit 0 = VSCode with project is the foreground window
///     Exit 1 = it is not
///
///   claude-win-helper.exe flash &lt;projectName&gt;
///     Flashes the VSCode taskbar for the matching project window.
///     Exit 0 = flashed (or window already focused), Exit 1 = window not found
/// </summary>
class ClaudeWinHelper
{
    [DllImport("user32.dll")]
    static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll")]
    static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    static extern bool FlashWindowEx(ref FLASHWINFO pwfi);

    [StructLayout(LayoutKind.Sequential)]
    struct FLASHWINFO
    {
        public uint cbSize;
        public IntPtr hwnd;
        public uint dwFlags;
        public uint uCount;
        public uint dwTimeout;
    }

    const uint FLASHW_ALL = 3;
    const uint FLASHW_TIMERNOFG = 12;

    static string GetWindowTitle(IntPtr hwnd)
    {
        var sb = new StringBuilder(512);
        GetWindowText(hwnd, sb, sb.Capacity);
        return sb.ToString();
    }

    /// <summary>
    /// Check if VSCode with the given project name is the foreground window.
    /// </summary>
    static int CheckFocus(string projectName)
    {
        IntPtr hwnd = GetForegroundWindow();
        if (hwnd == IntPtr.Zero) return 1;

        uint pid;
        GetWindowThreadProcessId(hwnd, out pid);

        try
        {
            var proc = Process.GetProcessById((int)pid);
            if (proc.ProcessName.IndexOf("Code", StringComparison.OrdinalIgnoreCase) < 0)
                return 1;

            string title = GetWindowTitle(hwnd);
            if (title.IndexOf(projectName, StringComparison.OrdinalIgnoreCase) >= 0)
                return 0; // focused on this project
        }
        catch { }

        return 1; // not focused
    }

    /// <summary>
    /// Find the VSCode window for the given project and flash its taskbar.
    /// </summary>
    static int Flash(string projectName)
    {
        IntPtr targetHwnd = IntPtr.Zero;

        foreach (var proc in Process.GetProcessesByName("Code"))
        {
            if (proc.MainWindowHandle == IntPtr.Zero) continue;

            string title = GetWindowTitle(proc.MainWindowHandle);
            if (title.IndexOf(projectName, StringComparison.OrdinalIgnoreCase) >= 0)
            {
                targetHwnd = proc.MainWindowHandle;
                break;
            }
        }

        if (targetHwnd == IntPtr.Zero) return 1;

        // Don't flash if already foreground
        if (GetForegroundWindow() == targetHwnd) return 0;

        var fi = new FLASHWINFO();
        fi.cbSize = (uint)Marshal.SizeOf(typeof(FLASHWINFO));
        fi.hwnd = targetHwnd;
        fi.dwFlags = FLASHW_ALL | FLASHW_TIMERNOFG;
        fi.uCount = 0;
        fi.dwTimeout = 0;
        FlashWindowEx(ref fi);

        return 0;
    }

    static int Main(string[] args)
    {
        if (args.Length < 2)
        {
            Console.Error.WriteLine("Usage: claude-win-helper.exe <check-focus|flash> <projectName>");
            return 1;
        }

        string command = args[0];
        string projectName = args[1];

        switch (command)
        {
            case "check-focus":
                return CheckFocus(projectName);
            case "flash":
                return Flash(projectName);
            default:
                Console.Error.WriteLine("Unknown command: " + command);
                return 1;
        }
    }
}
