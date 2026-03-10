$hookInput = $input | ConvertFrom-Json
$id = $hookInput.tool_use_id
$timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$tempFile = "$env:TEMP\claude_hook_$id.tmp"
$timestamp | Out-File $tempFile -Encoding utf8

$scriptPath = "C:\Users\Axioo Pongo\.claude\hooks\flash_taskbar.ps1"
$projectDir = $hookInput.cwd

# Pre-resolve terminal window handle for non-VSCode environments
# (must be done here because the background watcher process loses the process tree)
$termHwnd = 0
$isVSCode = ($null -ne $env:VSCODE_PID) -or ($null -ne $env:VSCODE_IPC_HOOK_CLI) -or ($env:TERM_PROGRAM -eq 'vscode')
if (-not $isVSCode) {
    $currentPid = $PID
    for ($i = 0; $i -lt 10; $i++) {
        try {
            $proc = Get-Process -Id $currentPid -ErrorAction Stop
            if ($proc.MainWindowHandle -ne [IntPtr]::Zero) {
                $termHwnd = $proc.MainWindowHandle.ToInt64()
                break
            }
            $parentPid = (Get-CimInstance Win32_Process -Filter "ProcessId = $currentPid" -ErrorAction Stop).ParentProcessId
            if (-not $parentPid -or $parentPid -eq $currentPid -or $parentPid -eq 0) { break }
            $currentPid = $parentPid
        } catch { break }
    }
}

Start-Process powershell -ArgumentList "-NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File ""$scriptPath"" -TempFile ""$tempFile"" -ProjectDir ""$projectDir"" -TermHwnd $termHwnd" -WindowStyle Hidden -ErrorAction SilentlyContinue
