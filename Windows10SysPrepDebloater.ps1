param (
    [switch]$Debloat,
    [switch]$SysPrep
)

################################################################################
# Function: Begin-SysPrep
# Purpose: Run system preparation fixes (used for silent MDT deployments).
################################################################################
function Begin-SysPrep {
    param([switch]$SysPrep)
    Write-Verbose "Starting Sysprep Fixes"
    # (Optional block: disable Windows Store Automatic Updates and stop InstallService)
    <#
    Write-Verbose "Adding Registry key to disable Windows Store Automatic Updates"
    $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
    if (-not (Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
        New-ItemProperty -Path $registryPath -Name AutoDownload -Value 2 -Force | Out-Null
    } else {
        Set-ItemProperty -Path $registryPath -Name AutoDownload -Value 2 -Force
    }
    Write-Verbose "Stopping InstallService"
    Stop-Service InstallService -ErrorAction SilentlyContinue
    #>
}

# Create a PSDrive for the HKEY_CLASSES_ROOT hive
New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -ErrorAction SilentlyContinue | Out-Null

################################################################################
# Function: Start-Debloat
# Purpose: Remove AppX packages that are not in the whitelist.
################################################################################
function Start-Debloat {
    param([switch]$Debloat)
    # Define the list of apps to keep (whitelist) as a single-line regex.
    $WhitelistedApps = 'Microsoft.ScreenSketch|Microsoft.Paint3D|Microsoft.WindowsCalculator|Microsoft.WindowsStore|Microsoft.Windows.Photos|CanonicalGroupLimited.UbuntuonWindows|Microsoft.MicrosoftStickyNotes|Microsoft.MSPaint|Microsoft.WindowsCamera|\.NET|Framework|Microsoft.HEIFImageExtension|Microsoft.ScreenSketch|Microsoft.StorePurchaseApp|Microsoft.VP9VideoExtensions|Microsoft.WebMediaExtensions|Microsoft.WebpImageExtension|Microsoft.DesktopAppInstaller'
    # Remove AppX packages for all users not matching the whitelist.
    Get-AppxPackage -AllUsers | Where-Object { $_.Name -notmatch $WhitelistedApps } | Remove-AppxPackage -ErrorAction SilentlyContinue
    # Run a second time to ensure cleanup on systems like 1803.
    Get-AppxPackage -AllUsers | Where-Object { $_.Name -notmatch $WhitelistedApps } | Remove-AppxPackage -ErrorAction SilentlyContinue
    # Remove provisioned packages not in the whitelist.
    $AppxRemoval = Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -notmatch $WhitelistedApps }
    foreach ($App in $AppxRemoval) {
        Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName -ErrorAction SilentlyContinue
    }
}

################################################################################
# Function: Remove-Keys
# Purpose: Remove leftover registry keys for bloatware.
################################################################################
function Remove-Keys {
    param([switch]$Debloat)
    $Keys = @(
        # Background Tasks
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y",
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0",
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe",
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy",
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy",
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy",
        # Windows File association
        "HKCR:\Extensions\ContractId\Windows.File\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0",
        # Launch keys
        "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y",
        "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0",
        "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy",
        "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy",
        "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy",
        # Scheduled Task key
        "HKCR:\Extensions\ContractId\Windows.PreInstalledConfigTask\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe",
        # Protocol keys
        "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0",
        "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy",
        "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy",
        "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy",
        # Share Target key
        "HKCR:\Extensions\ContractId\Windows.ShareTarget\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
    )
    foreach ($Key in $Keys) {
        Write-Output "Removing registry key: $Key"
        Remove-Item $Key -Recurse -Force -ErrorAction SilentlyContinue
    }
}

################################################################################
# Function: Protect-Privacy
# Purpose: Disable telemetry, feedback, Cortana, live tiles, and prevent bloatware return.
################################################################################
function Protect-Privacy {
    param([switch]$Debloat)
    # Ensure HKCR drive is available.
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -ErrorAction SilentlyContinue | Out-Null

    Write-Output "Disabling Windows Feedback Experience..."
    $Advertising = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo'
    if (Test-Path $Advertising) {
        Set-ItemProperty $Advertising -Name Enabled -Value 0 -Force -ErrorAction SilentlyContinue
    }

    Write-Output "Stopping Cortana in Windows Search..."
    $Search = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
    if (Test-Path $Search) {
        Set-ItemProperty $Search -Name AllowCortana -Value 0 -Force -ErrorAction SilentlyContinue
    }

    Write-Output "Disabling Bing Search in Start Menu..."
    $WebSearch = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name BingSearchEnabled -Value 0 -Force -ErrorAction SilentlyContinue
    if (-not (Test-Path $WebSearch)) {
        New-Item $WebSearch -Force | Out-Null
    }
    Set-ItemProperty $WebSearch -Name DisableWebSearch -Value 1 -Force -ErrorAction SilentlyContinue

    Write-Output "Stopping Feedback Experience data collection..."
    $Period = 'HKCU:\Software\Microsoft\Siuf\Rules'
    if (-not (Test-Path $Period)) {
        New-Item $Period -Force | Out-Null
    }
    Set-ItemProperty $Period -Name PeriodInNanoSeconds -Value 0 -Force -ErrorAction SilentlyContinue

    Write-Output "Preventing bloatware apps from returning..."
    $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    if (-not (Test-Path $registryPath)) {
        New-Item $registryPath -Force | Out-Null
        New-ItemProperty $registryPath -Name DisableWindowsConsumerFeatures -Value 1 -Force | Out-Null
    } else {
        Set-ItemProperty $registryPath -Name DisableWindowsConsumerFeatures -Value 1 -Force -ErrorAction SilentlyContinue
    }

    Write-Output "Setting Mixed Reality Portal value to 0..."
    $Holo = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Holographic'
    if (Test-Path $Holo) {
        Set-ItemProperty $Holo -Name FirstRunSucceeded -Value 0 -Force -ErrorAction SilentlyContinue
    }

    Write-Output "Disabling live tiles..."
    $Live = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications'
    if (-not (Test-Path $Live)) {
        New-Item $Live -Force | Out-Null
        New-ItemProperty $Live -Name NoTileApplicationNotification -Value 1 -Force | Out-Null
    } else {
        Set-ItemProperty $Live -Name NoTileApplicationNotification -Value 1 -Force -ErrorAction SilentlyContinue
    }

    Write-Output "Turning off Data Collection..."
    $DataCollection = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'
    if (Test-Path $DataCollection) {
        Set-ItemProperty $DataCollection -Name AllowTelemetry -Value 0 -Force -ErrorAction SilentlyContinue
    }

    Write-Output "Disabling People icon on Taskbar..."
    $People = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People'
    if (Test-Path $People) {
        Set-ItemProperty $People -Name PeopleBand -Value 0 -Force -ErrorAction SilentlyContinue
    }

    Write-Output "Disabling Start Menu suggestions..."
    $Suggestions = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    if (Test-Path $Suggestions) {
        Set-ItemProperty $Suggestions -Name SystemPaneSuggestionsEnabled -Value 0 -Force -ErrorAction SilentlyContinue
    }

    Write-Output "Removing CloudStore registry key if it exists..."
    $CloudStore = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore'
    if (Test-Path $CloudStore) {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Remove-Item $CloudStore -Recurse -Force -ErrorAction SilentlyContinue
        Start-Process Explorer.exe -Wait -ErrorAction SilentlyContinue
    }

    Write-Output "Loading default user registry settings to prevent bloatware return..."
    reg load HKU\Default_User "C:\Users\Default\NTUSER.DAT" | Out-Null
    Set-ItemProperty -Path "Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name SystemPaneSuggestionsEnabled -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name PreInstalledAppsEnabled -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name OemPreInstalledAppsEnabled -Value 0 -ErrorAction SilentlyContinue
    reg unload HKU\Default_User | Out-Null

    Write-Output "Disabling scheduled tasks..."
    Get-ScheduledTask -TaskName XblGameSaveTask | Disable-ScheduledTask -ErrorAction SilentlyContinue
    Get-ScheduledTask -TaskName Consolidator | Disable-ScheduledTask -ErrorAction SilentlyContinue
    Get-ScheduledTask -TaskName UsbCeip | Disable-ScheduledTask -ErrorAction SilentlyContinue
    Get-ScheduledTask -TaskName DmClient | Disable-ScheduledTask -ErrorAction SilentlyContinue
    Get-ScheduledTask -TaskName DmClientOnScenarioDownload | Disable-ScheduledTask -ErrorAction SilentlyContinue
}

################################################################################
# Function: FixWhitelistedApps
# Purpose: Reinstall any whitelisted apps if they were removed.
################################################################################
function FixWhitelistedApps {
    param([switch]$Debloat)
    $whitelist = @("Microsoft.Paint3D", "Microsoft.MSPaint", "Microsoft.WindowsCalculator", "Microsoft.WindowsStore", "Microsoft.MicrosoftStickyNotes", "Microsoft.WindowsSoundRecorder", "Microsoft.Windows.Photos")
    # Check if any of the whitelisted apps are missing.
    if (-not (Get-AppxPackage -AllUsers | Where-Object { $whitelist -contains $_.Name })) {
        Write-Output "Reinstalling whitelisted apps..."
        foreach ($app in $whitelist) {
            Get-AppxPackage -AllUsers -Name $app -ErrorAction SilentlyContinue | ForEach-Object {
                Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction SilentlyContinue
            }
        }
    }
}

################################################################################
# Function: CheckDMWService
# Purpose: Ensure that the dmwappushservice (WAP Push) is running.
################################################################################
function CheckDMWService {
    param([switch]$Debloat)
    $svc = Get-Service -Name dmwappushservice -ErrorAction SilentlyContinue
    if ($svc -and $svc.StartType -eq "Disabled") {
        Set-Service -Name dmwappushservice -StartupType Automatic -ErrorAction SilentlyContinue
    }
    if ($svc -and $svc.Status -eq "Stopped") {
        Start-Service -Name dmwappushservice -ErrorAction SilentlyContinue
    }
}

################################################################################
# Function: CheckInstallService
# Purpose: Ensure that the InstallService is running.
################################################################################
function CheckInstallService {
    param([switch]$Debloat)
    $svc = Get-Service -Name InstallService -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq "Stopped") {
        Start-Service -Name InstallService -ErrorAction SilentlyContinue
        Set-Service -Name InstallService -StartupType Automatic -ErrorAction SilentlyContinue
    }
}

################################################################################
# Main Execution Flow
################################################################################
Write-Output "Initiating Sysprep"
Begin-SysPrep
Write-Output "Removing bloatware apps..."
Start-Debloat
Write-Output "Removing leftover registry keys..."
Remove-Keys
Write-Output "Checking and reinstalling missing whitelisted apps..."
FixWhitelistedApps
Write-Output "Applying privacy protections and disabling telemetry..."
Protect-Privacy
Write-Output "Ensuring dmwappushservice is running..."
CheckDMWService
Write-Output "Ensuring InstallService is running..."
CheckInstallService
Write-Output "Finished all tasks."
