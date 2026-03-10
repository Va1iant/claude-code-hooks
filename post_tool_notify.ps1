$hookInput = $input | ConvertFrom-Json
$id = $hookInput.tool_use_id
$tempFile = "$env:TEMP\claude_hook_$id.tmp"

if (-not (Test-Path $tempFile)) { exit 0 }

$startTime = [long](Get-Content $tempFile -Raw).Trim()
$endTime = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$elapsed = ($endTime - $startTime) / 1000
Remove-Item $tempFile -Force

if ($elapsed -le 15) { exit 0 }

# Check if the correct window (VSCode or terminal) is focused
$projectDir = $hookInput.cwd
$projectName = Split-Path $projectDir -Leaf
$smartScript = Join-Path $PSScriptRoot "flash_smart.ps1"
& $smartScript -Action check-focus -ProjectName $projectName
if ($LASTEXITCODE -eq 0) { exit 0 }

$toolName = $hookInput.tool_name
$seconds = [math]::Round($elapsed)
$title = "Claude Task Complete"
$body = "$toolName finished in ${seconds}s"

# Try BurntToast first, fall back to msg
$btAvailable = Get-Module -ListAvailable -Name BurntToast -ErrorAction SilentlyContinue
if ($btAvailable) {
    Import-Module BurntToast -ErrorAction SilentlyContinue
    New-BurntToastNotification -Text $title, $body -ErrorAction SilentlyContinue
} else {
    msg * "$title`: $body" 2>$null
}
