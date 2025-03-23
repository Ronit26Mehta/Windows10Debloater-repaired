Write-Host "Clear last used files and folders"
Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations\*.automaticDestinations-ms" -Force -ErrorAction SilentlyContinue
