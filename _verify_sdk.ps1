$sdk = "C:\Users\Halloul\AppData\Local\Android\Sdk"
Write-Output "=== SDK root ==="
Get-ChildItem -LiteralPath $sdk -Force | Select-Object Name
Write-Output "=== build-tools ==="
Get-ChildInfo "build-tools" | Select-Object Name
Write-Output "=== platforms ==="
Get-ChildItem "$sdk\platforms" | Select-Object Name
Write-Output "=== ndk ==="
Get-ChildItem "$sdk\ndk" | Select-Object Name
Write-Output "=== apksigner.ms ==="
Test-Path "$sdk\build-tools\35.0.1\apksigner.bat"
Write- "=== licenses ==="
Get-ChildItem "$sdk\licenses" | Select-Object Name