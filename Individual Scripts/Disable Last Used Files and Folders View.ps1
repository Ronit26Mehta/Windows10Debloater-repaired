$Keys = @(
    # Deactivate showing of last used files
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HomeFolderDesktop\NameSpace\DelegateFolders\{3134ef9c-6b18-4996-ad04-ed5912e00eb5}",
    
    # Deactivate showing of last used folders
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HomeFolderDesktop\NameSpace\DelegateFolders\{3936E9E4-D92C-4EEE-A85A-BC16D5EA0819}"
)

ForEach ($Key in $Keys) {
    Write-Host "Attempting to remove $Key from registry" -ForegroundColor Cyan
    try {
        Remove-Item -Path $Key -Recurse -Force
        Write-Host "Successfully removed $Key" -ForegroundColor Green
    }
    catch {
        Write-Host "Error removing $Key: $_" -ForegroundColor Red
    }
}
