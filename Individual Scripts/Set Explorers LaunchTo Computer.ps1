Write-Host "Setting Explorer's Entry Point to 'Computer'" -ForegroundColor Cyan

$LaunchTo = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

try {
    Set-ItemProperty -Path $LaunchTo -Name LaunchTo -Value 1 -Force -ErrorAction Stop
    Write-Host "Explorer's entry point successfully set to 'Computer' (Harddrives, Network, etc.)." -ForegroundColor Green
}
catch {
    Write-Host "Error setting Explorer's entry point: $_" -ForegroundColor Red
}
