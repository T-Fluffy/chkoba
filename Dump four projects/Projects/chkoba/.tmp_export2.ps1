$mono = "D:\Godot projects\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64_console.exe"
$proj = "D:\Godot projects\Projects\chkoba"
$out = "D:\Godot projects\Projects\chkoba\ExportedVersions\android\Chkoba_debug.apk"
New-Item -ItemType Directory -Path (Split-Path $out) -Force | Out-Null
Write-Output "=== exporting DEBUG (uses debug keystore) ==="
& $mono --export-debug "Android" "$out" --path $proj 2>&1 | Select-Object -First 80
Write-Output "EXIT=$LASTEXITCODE"
Write-Output "=== output exists and size? ==="
if (Test24Path -LiteralPath $out) { (Get-Item -LiteralPath $out).Length } else { Write-Output "MISSING" }