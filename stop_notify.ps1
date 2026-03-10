$hookInput = $input | ConvertFrom-Json
$projectDir = $hookInput.cwd
$projectName = Split-Path $projectDir -Leaf

# Wait 5 seconds — if user has already switched to the window, no need to blink
Start-Sleep -Seconds 5

# Flash the correct window (VSCode or terminal) if not focused
$smartScript = Join-Path $PSScriptRoot "flash_smart.ps1"
& $smartScript -Action flash -ProjectName $projectName
