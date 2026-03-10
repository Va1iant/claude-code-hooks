param(
    [string]$TempFile,
    [string]$ProjectDir,
    [long]$TermHwnd = 0
)

# Wait 5 seconds — if the tool completes quickly (auto-approved), the temp file
# will already be removed by post_tool_notify.ps1 and we exit silently.
Start-Sleep -Seconds 5

if (-not (Test-Path $TempFile)) { exit 0 }

$projectName = Split-Path $ProjectDir -Leaf
$smartScript = Join-Path $PSScriptRoot "flash_smart.ps1"
& $smartScript -Action flash -ProjectName $projectName -TermHwnd $TermHwnd
