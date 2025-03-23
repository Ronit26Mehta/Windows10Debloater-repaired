# Self–elevation: if not run as administrator, re–launch with elevated privileges.
If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host "You didn't run this script as an Administrator. This script will self–elevate to run as an Administrator and continue."
    Start-Sleep 1
    Write-Host "                                               3"
    Start-Sleep 1
    Write-Host "                                               2"
    Start-Sleep 1
    Write-Host "                                               1"
    Start-Sleep 1
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    Exit
}

# Ensure that errors do not halt execution unnecessarily.
$ErrorActionPreference = 'SilentlyContinue'

# Create folder for logs if it does not exist.
$DebloatFolder = "C:\Temp\Windows10Debloater"
If (Test-Path $DebloatFolder) {
    Write-Output "$DebloatFolder exists. Skipping."
} Else {
    Write-Output "The folder '$DebloatFolder' doesn't exist. This folder will be used for storing logs created after the script runs. Creating now."
    Start-Sleep 1
    New-Item -Path $DebloatFolder -ItemType Directory -Force | Out-Null
    Write-Output "The folder $DebloatFolder was successfully created."
}

# Start transcript logging.
Start-Transcript -OutputDirectory "$DebloatFolder"

# Load required assemblies for MessageBox functionality.
Add-Type -AssemblyName PresentationCore, PresentationFramework

### FUNCTIONS ###

# --- Debloat functions ---
Function DebloatAll {
    # Remove AppXPackages using a whitelist and a non–removable list.
    $WhitelistedApps = 'Microsoft.ScreenSketch|Microsoft.Paint3D|Microsoft.WindowsCalculator|Microsoft.WindowsStore|Microsoft.Windows.Photos|CanonicalGroupLimited.UbuntuonWindows|Microsoft.XboxGameCallableUI|Microsoft.XboxGamingOverlay|Microsoft.Xbox.TCUI|Microsoft.XboxGamingOverlay|Microsoft.XboxIdentityProvider|Microsoft.MicrosoftStickyNotes|Microsoft.MSPaint|Microsoft.WindowsCamera|.NET|Framework|Microsoft.HEIFImageExtension|Microsoft.ScreenSketch|Microsoft.StorePurchaseApp|Microsoft.VP9VideoExtensions|Microsoft.WebMediaExtensions|Microsoft.WebpImageExtension|Microsoft.DesktopAppInstaller|WindSynthBerry|MIDIBerry|Slack'
    
    $NonRemovable = '1527c705-839a-4832-9118-54d4Bd6a0c89|c5e2524a-ea46-4f67-841f-6a9465d9d515|E2A4F912-2574-4A75-9BB0-0D023378592B|F46D4000-FD22-4DB4-AC8E-4E1DDDE828FE|InputApp|Microsoft.AAD.BrokerPlugin|Microsoft.AccountsControl|Microsoft.BioEnrollment|Microsoft.CredDialogHost|Microsoft.ECApp|Microsoft.LockApp|Microsoft.MicrosoftEdgeDevToolsClient|Microsoft.MicrosoftEdge|Microsoft.PPIProjection|Microsoft.Win32WebViewHost|Microsoft.Windows.Apprep.ChxApp|Microsoft.Windows.AssignedAccessLockApp|Microsoft.Windows.CapturePicker|Microsoft.Windows.CloudExperienceHost|Microsoft.Windows.ContentDeliveryManager|Microsoft.Windows.Cortana|Microsoft.Windows.NarratorQuickStart|Microsoft.Windows.ParentalControls|Microsoft.Windows.PeopleExperienceHost|Microsoft.Windows.PinningConfirmationDialog|Microsoft.Windows.SecHealthUI|Microsoft.Windows.SecureAssessmentBrowser|Microsoft.Windows.ShellExperienceHost|Microsoft.Windows.XGpuEjectDialog|Microsoft.XboxGameCallableUI|Windows.CBSPreview|windows.immersivecontrolpanel|Windows.PrintDialog|Microsoft.VCLibs.140.00|Microsoft.Services.Store.Engagement|Microsoft.UI.Xaml.2.0|*Nvidia*'

    Get-AppxPackage -AllUsers | Where-Object { $_.Name -notmatch $WhitelistedApps -and $_.Name -notmatch $NonRemovable } | Remove-AppxPackage
    Get-AppxPackage | Where-Object { $_.Name -notmatch $WhitelistedApps -and $_.Name -notmatch $NonRemovable } | Remove-AppxPackage
    Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -notmatch $WhitelistedApps -and $_.PackageName -notmatch $NonRemovable } | Remove-AppxProvisionedPackage -Online
}

Function DebloatBlacklist {
    $Bloatware = @(
        # Unnecessary Windows 10 AppX Apps
        "Microsoft.BingNews"
        "Microsoft.GetHelp"
        "Microsoft.Getstarted"
        "Microsoft.Messaging"
        "Microsoft.Microsoft3DViewer"
        "Microsoft.MicrosoftOfficeHub"
        "Microsoft.MicrosoftSolitaireCollection"
        "Microsoft.NetworkSpeedTest"
        "Microsoft.News"
        "Microsoft.Office.Lens"
        "Microsoft.Office.OneNote"
        "Microsoft.Office.Sway"
        "Microsoft.OneConnect"
        "Microsoft.People"
        "Microsoft.Print3D"
        "Microsoft.RemoteDesktop"
        "Microsoft.SkypeApp"
        "Microsoft.StorePurchaseApp"
        "Microsoft.Office.Todo.List"
        "Microsoft.Whiteboard"
        "Microsoft.WindowsAlarms"
        #"Microsoft.WindowsCamera"
        "microsoft.windowscommunicationsapps"
        "Microsoft.WindowsFeedbackHub"
        "Microsoft.WindowsMaps"
        "Microsoft.WindowsSoundRecorder"
        "Microsoft.Xbox.TCUI"
        "Microsoft.XboxApp"
        "Microsoft.XboxGameOverlay"
        "Microsoft.XboxIdentityProvider"
        "Microsoft.XboxSpeechToTextOverlay"
        "Microsoft.ZuneMusic"
        "Microsoft.ZuneVideo"

        # Sponsored Windows 10 AppX Apps (using wildcards)
        "*EclipseManager*"
        "*ActiproSoftwareLLC*"
        "*AdobeSystemsIncorporated.AdobePhotoshopExpress*"
        "*Duolingo-LearnLanguagesforFree*"
        "*PandoraMediaInc*"
        "*CandyCrush*"
        "*BubbleWitch3Saga*"
        "*Wunderlist*"
        "*Flipboard*"
        "*Twitter*"
        "*Facebook*"
        "*Spotify*"
        "*Minecraft*"
        "*Royal Revolt*"
        "*Sway*"
        "*Speed Test*"
        "*Dolby*"
    )
    foreach ($Bloat in $Bloatware) {
        Get-AppxPackage -Name $Bloat | Remove-AppxPackage
        Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $Bloat } | Remove-AppxProvisionedPackage -Online
        Write-Output "Trying to remove $Bloat."
    }
}

# --- Registry keys removal ---
Function Remove-Keys {
    # List of registry keys to remove.
    $Keys = @(
        # Remove Background Tasks
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y",
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0",
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe",
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy",
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy",
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy",
        # Windows File
        "HKCR:\Extensions\ContractId\Windows.File\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0",
        # Registry keys to delete if not removed by AppX removal
        "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y",
        "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0",
        "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy",
        "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy",
        "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy",
        # Scheduled Tasks to delete
        "HKCR:\Extensions\ContractId\Windows.PreInstalledConfigTask\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe",
        # Windows Protocol Keys
        "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0",
        "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy",
        "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy",
        "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy",
        # Windows Share Target
        "HKCR:\Extensions\ContractId\Windows.ShareTarget\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
    )
    ForEach ($Key in $Keys) {
        Write-Output "Removing $Key from registry"
        Remove-Item $Key -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# --- Privacy and telemetry settings ---
Function Protect-Privacy {
    # Disables Windows Feedback Experience.
    Write-Output "Disabling Windows Feedback Experience program"
    $Advertising = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    If (Test-Path $Advertising) {
        Set-ItemProperty $Advertising -Name Enabled -Value 0
    }
    
    # Stops Cortana from being used as part of Windows Search.
    Write-Output "Stopping Cortana from being used as part of your Windows Search Function"
    $Search = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    If (Test-Path $Search) {
        Set-ItemProperty $Search -Name AllowCortana -Value 0
    }
    
    # Disables Web (Bing) Search in the Start Menu.
    Write-Output "Disabling Bing Search in Start Menu"
    $WebSearch = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name BingSearchEnabled -Value 0
    If (-not (Test-Path $WebSearch)) {
        New-Item $WebSearch -Force | Out-Null
    }
    Set-ItemProperty $WebSearch -Name DisableWebSearch -Value 1
    
    # Stops the Windows Feedback Experience from sending anonymous data.
    Write-Output "Stopping the Windows Feedback Experience program"
    $Period = "HKCU:\Software\Microsoft\Siuf\Rules"
    If (-not (Test-Path $Period)) {
        New-Item $Period -Force | Out-Null
    }
    Set-ItemProperty $Period -Name PeriodInNanoSeconds -Value 0
    
    # Prevents bloatware applications from returning and removes Start Menu suggestions.
    Write-Output "Adding Registry key to prevent bloatware apps from returning"
    $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    $registryOEM = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    If (-not (Test-Path $registryPath)) {
        New-Item $registryPath -Force | Out-Null
    }
    Set-ItemProperty $registryPath -Name DisableWindowsConsumerFeatures -Value 1
    
    If (-not (Test-Path $registryOEM)) {
        New-Item $registryOEM -Force | Out-Null
    }
    Set-ItemProperty $registryOEM -Name ContentDeliveryAllowed -Value 0
    Set-ItemProperty $registryOEM -Name OemPreInstalledAppsEnabled -Value 0
    Set-ItemProperty $registryOEM -Name PreInstalledAppsEnabled -Value 0
    Set-ItemProperty $registryOEM -Name PreInstalledAppsEverEnabled -Value 0
    Set-ItemProperty $registryOEM -Name SilentInstalledAppsEnabled -Value 0
    Set-ItemProperty $registryOEM -Name SystemPaneSuggestionsEnabled -Value 0          
    
    # Prepping Mixed Reality Portal for removal.
    Write-Output "Setting Mixed Reality Portal value to 0 so that you can uninstall it in Settings"
    $Holo = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Holographic"
    If (Test-Path $Holo) {
        Set-ItemProperty $Holo -Name FirstRunSucceeded -Value 0
    }
    
    # Disables Wi-Fi Sense.
    Write-Output "Disabling Wi-Fi Sense"
    $WifiSense1 = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting"
    $WifiSense2 = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots"
    $WifiSense3 = "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config"
    If (-not (Test-Path $WifiSense1)) { New-Item $WifiSense1 -Force | Out-Null }
    Set-ItemProperty $WifiSense1 -Name Value -Value 0
    If (-not (Test-Path $WifiSense2)) { New-Item $WifiSense2 -Force | Out-Null }
    Set-ItemProperty $WifiSense2 -Name Value -Value 0
    Set-ItemProperty $WifiSense3 -Name AutoConnectAllowedOEM -Value 0
    
    # Disables live tiles.
    Write-Output "Disabling live tiles"
    $Live = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"
    If (-not (Test-Path $Live)) { New-Item $Live -Force | Out-Null }
    Set-ItemProperty $Live -Name NoTileApplicationNotification -Value 1
    
    # Turns off Data Collection via the AllowTelemetry key.
    Write-Output "Turning off Data Collection"
    $DataCollection1 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
    $DataCollection2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    $DataCollection3 = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
    If (Test-Path $DataCollection1) { Set-ItemProperty $DataCollection1 -Name AllowTelemetry -Value 0 }
    If (Test-Path $DataCollection2) { Set-ItemProperty $DataCollection2 -Name AllowTelemetry -Value 0 }
    If (Test-Path $DataCollection3) { Set-ItemProperty $DataCollection3 -Name AllowTelemetry -Value 0 }
    
    # Disables Location Tracking.
    Write-Output "Disabling Location Tracking"
    $SensorState = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"
    $LocationConfig = "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration"
    If (-not (Test-Path $SensorState)) { New-Item $SensorState -Force | Out-Null }
    Set-ItemProperty $SensorState -Name SensorPermissionState -Value 0
    If (-not (Test-Path $LocationConfig)) { New-Item $LocationConfig -Force | Out-Null }
    Set-ItemProperty $LocationConfig -Name Status -Value 0
    
    # Disables People icon on Taskbar.
    Write-Output "Disabling People icon on Taskbar"
    $People = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People'
    If (Test-Path $People) { Set-ItemProperty $People -Name PeopleBand -Value 0 }
    
    # Disables scheduled tasks considered unnecessary.
    Write-Output "Disabling scheduled tasks"
    Get-ScheduledTask -TaskName XblGameSaveTaskLogon | Disable-ScheduledTask
    Get-ScheduledTask -TaskName XblGameSaveTask | Disable-ScheduledTask
    Get-ScheduledTask -TaskName Consolidator | Disable-ScheduledTask
    Get-ScheduledTask -TaskName UsbCeip | Disable-ScheduledTask
    Get-ScheduledTask -TaskName DmClient | Disable-ScheduledTask
    Get-ScheduledTask -TaskName DmClientOnScenarioDownload | Disable-ScheduledTask

    # Disables Diagnostics Tracking Service.
    Write-Output "Stopping and disabling Diagnostics Tracking Service"
    DisableDiagTrack

    Write-Output "Removing CloudStore from registry if it exists"
    $CloudStore = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore'
    If (Test-Path $CloudStore) {
        Stop-Process -Name Explorer -Force
        Remove-Item $CloudStore -Recurse -Force
        Start-Process Explorer -Wait
    }
}

# --- Functions for Cortana control ---
Function DisableCortana {
    Write-Host "Disabling Cortana"
    $Cortana1 = "HKCU:\SOFTWARE\Microsoft\Personalization\Settings"
    $Cortana2 = "HKCU:\SOFTWARE\Microsoft\InputPersonalization"
    $Cortana3 = "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore"
    If (-not (Test-Path $Cortana1)) { New-Item $Cortana1 -Force | Out-Null }
    Set-ItemProperty $Cortana1 -Name AcceptedPrivacyPolicy -Value 0
    If (-not (Test-Path $Cortana2)) { New-Item $Cortana2 -Force | Out-Null }
    Set-ItemProperty $Cortana2 -Name RestrictImplicitTextCollection -Value 1
    Set-ItemProperty $Cortana2 -Name RestrictImplicitInkCollection -Value 1
    If (-not (Test-Path $Cortana3)) { New-Item $Cortana3 -Force | Out-Null }
    Set-ItemProperty $Cortana3 -Name HarvestContacts -Value 0
}

Function EnableCortana {
    Write-Host "Re-enabling Cortana"
    $Cortana1 = "HKCU:\SOFTWARE\Microsoft\Personalization\Settings"
    $Cortana2 = "HKCU:\SOFTWARE\Microsoft\InputPersonalization"
    $Cortana3 = "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore"
    If (-not (Test-Path $Cortana1)) { New-Item $Cortana1 -Force | Out-Null }
    Set-ItemProperty $Cortana1 -Name AcceptedPrivacyPolicy -Value 1
    If (-not (Test-Path $Cortana2)) { New-Item $Cortana2 -Force | Out-Null }
    Set-ItemProperty $Cortana2 -Name RestrictImplicitTextCollection -Value 0
    Set-ItemProperty $Cortana2 -Name RestrictImplicitInkCollection -Value 0
    If (-not (Test-Path $Cortana3)) { New-Item $Cortana3 -Force | Out-Null }
    Set-ItemProperty $Cortana3 -Name HarvestContacts -Value 1
}

# --- Edge PDF control ---
Function Stop-EdgePDF {
    # Stops Edge from taking over as the default .PDF viewer.
    Write-Output "Stopping Edge from taking over as the default .PDF viewer"
    $NoPDF = "HKCR:\.pdf"
    $NoProgids = "HKCR:\.pdf\OpenWithProgids"
    $NoWithList = "HKCR:\.pdf\OpenWithList"
    If (-not (Get-ItemProperty -Path $NoPDF -Name NoOpenWith -ErrorAction SilentlyContinue)) {
        New-ItemProperty -Path $NoPDF -Name NoOpenWith -Value "" -Force | Out-Null
    }
    If (-not (Get-ItemProperty -Path $NoPDF -Name NoStaticDefaultVerb -ErrorAction SilentlyContinue)) {
        New-ItemProperty -Path $NoPDF -Name NoStaticDefaultVerb -Value "" -Force | Out-Null
    }
    If (-not (Get-ItemProperty -Path $NoProgids -Name NoOpenWith -ErrorAction SilentlyContinue)) {
        New-ItemProperty -Path $NoProgids -Name NoOpenWith -Value "" -Force | Out-Null
    }
    If (-not (Get-ItemProperty -Path $NoProgids -Name NoStaticDefaultVerb -ErrorAction SilentlyContinue)) {
        New-ItemProperty -Path $NoProgids -Name NoStaticDefaultVerb -Value "" -Force | Out-Null
    }
    If (-not (Get-ItemProperty -Path $NoWithList -Name NoOpenWith -ErrorAction SilentlyContinue)) {
        New-ItemProperty -Path $NoWithList -Name NoOpenWith -Value "" -Force | Out-Null
    }
    If (-not (Get-ItemProperty -Path $NoWithList -Name NoStaticDefaultVerb -ErrorAction SilentlyContinue)) {
        New-ItemProperty -Path $NoWithList -Name NoStaticDefaultVerb -Value "" -Force | Out-Null
    }
    
    # Append an underscore to the Registry key for Edge.
    $Edge = "HKCR:\AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723_"
    If (Test-Path $Edge) {
        Set-Item $Edge -Name "(default)" -Value "AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723_"
    }
}

Function Enable-EdgePDF {
    Write-Output "Setting Edge back to default"
    $NoPDF = "HKCR:\.pdf"
    $NoProgids = "HKCR:\.pdf\OpenWithProgids"
    $NoWithList = "HKCR:\.pdf\OpenWithList"
    If (Get-ItemProperty -Path $NoPDF -Name NoOpenWith -ErrorAction SilentlyContinue) {
        Remove-ItemProperty -Path $NoPDF -Name NoOpenWith -Force
    }
    If (Get-ItemProperty -Path $NoPDF -Name NoStaticDefaultVerb -ErrorAction SilentlyContinue) {
        Remove-ItemProperty -Path $NoPDF -Name NoStaticDefaultVerb -Force
    }
    If (Get-ItemProperty -Path $NoProgids -Name NoOpenWith -ErrorAction SilentlyContinue) {
        Remove-ItemProperty -Path $NoProgids -Name NoOpenWith -Force
    }
    If (Get-ItemProperty -Path $NoProgids -Name NoStaticDefaultVerb -ErrorAction SilentlyContinue) {
        Remove-ItemProperty -Path $NoProgids -Name NoStaticDefaultVerb -Force
    }
    If (Get-ItemProperty -Path $NoWithList -Name NoOpenWith -ErrorAction SilentlyContinue) {
        Remove-ItemProperty -Path $NoWithList -Name NoOpenWith -Force
    }
    If (Get-ItemProperty -Path $NoWithList -Name NoStaticDefaultVerb -ErrorAction SilentlyContinue) {
        Remove-ItemProperty -Path $NoWithList -Name NoStaticDefaultVerb -Force
    }
    
    # Remove underscore from the Registry key for Edge.
    $Edge2 = "HKCR:\AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723_"
    If (Test-Path $Edge2) {
        Set-Item $Edge2 -Name "(default)" -Value "AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723"
    }
}

# --- Reinstall whitelisted apps if missing ---
Function FixWhitelistedApps {
    $whitelist = @("Microsoft.Paint3D", "Microsoft.WindowsCalculator", "Microsoft.WindowsStore", "Microsoft.Windows.Photos")
    foreach ($app in $whitelist) {
        if (-not (Get-AppxPackage -AllUsers -Name $app -ErrorAction SilentlyContinue)) {
            Write-Output "Reinstalling $app..."
            Get-AppxPackage -AllUsers -Name $app -ErrorAction SilentlyContinue | ForEach-Object {
                Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"
            }
        }
    }
}

# --- OneDrive removal ---
Function UninstallOneDrive {
    Write-Host "Checking for pre-existing files and folders in the OneDrive folder..."
    Start-Sleep 1
    If (Test-Path "$env:USERPROFILE\OneDrive\*") {
        Write-Host "Files found in the OneDrive folder! Checking if a folder named 'OneDriveBackupFiles' exists on your desktop."
        Start-Sleep 1
        $backupPath = "$env:USERPROFILE\Desktop\OneDriveBackupFiles"
        If (-not (Test-Path $backupPath)) {
            Write-Host "Creating folder 'OneDriveBackupFiles' on your desktop."
            New-Item -Path $env:USERPROFILE\Desktop -Name "OneDriveBackupFiles" -ItemType Directory -Force | Out-Null
            Write-Host "Folder created."
        } Else {
            Write-Host "Folder 'OneDriveBackupFiles' already exists."
        }
        Start-Sleep 1
        Move-Item -Path "$env:USERPROFILE\OneDrive\*" -Destination $backupPath -Force
        Write-Host "Moved OneDrive files/folders to 'OneDriveBackupFiles'."
        Start-Sleep 1
        Write-Host "Proceeding with OneDrive removal..."
        Start-Sleep 1
    } Else {
        Write-Host "No files found in the OneDrive folder. Proceeding with removal."
        Start-Sleep 1
        Write-Host "Enabling Group Policy 'Prevent the usage of OneDrive for File Storage'."
        $OneDriveKey = 'HKLM:\Software\Policies\Microsoft\Windows\OneDrive'
        If (-not (Test-Path $OneDriveKey)) { New-Item $OneDriveKey -Force | Out-Null }
        Set-ItemProperty $OneDriveKey -Name OneDrive -Value DisableFileSyncNGSC
    }

    Write-Host "Uninstalling OneDrive. Please wait..."
    $OneDriveSetup = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
    If (-not (Test-Path $OneDriveSetup)) {
        $OneDriveSetup = "$env:SYSTEMROOT\System32\OneDriveSetup.exe"
    }
    Stop-Process -Name "OneDrive*" -Force -ErrorAction SilentlyContinue
    Start-Sleep 2
    Start-Process $OneDriveSetup -ArgumentList "/uninstall" -NoNewWindow -Wait
    Start-Sleep 2
    Write-Output "Stopping Explorer"
    Start-Sleep 1
    taskkill.exe /F /IM explorer.exe
    Start-Sleep 3
    Write-Output "Removing leftover OneDrive files"
    Remove-Item "$env:USERPROFILE\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item "$env:LOCALAPPDATA\Microsoft\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item "$env:PROGRAMDATA\Microsoft OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
    If (Test-Path "$env:SYSTEMDRIVE\OneDriveTemp") {
        Remove-Item "$env:SYSTEMDRIVE\OneDriveTemp" -Force -Recurse -ErrorAction SilentlyContinue
    }
    Write-Output "Removing OneDrive integration from Windows Explorer"
    $ExplorerReg1 = "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    $ExplorerReg2 = "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    If (-not (Test-Path $ExplorerReg1)) { New-Item $ExplorerReg1 -Force | Out-Null }
    Set-ItemProperty $ExplorerReg1 -Name System.IsPinnedToNameSpaceTree -Value 0
    If (-not (Test-Path $ExplorerReg2)) { New-Item $ExplorerReg2 -Force | Out-Null }
    Set-ItemProperty $ExplorerReg2 -Name System.IsPinnedToNameSpaceTree -Value 0
    Write-Output "Restarting Explorer."
    Start-Process explorer.exe -NoNewWindow
    Write-Host "OneDrive has been successfully uninstalled!"
    Remove-Item Env:OneDrive -ErrorAction SilentlyContinue
}

# --- Start Menu unpinning ---
Function UnpinStart {
    # Creates a blank Start layout to unpin items.
    $START_MENU_LAYOUT = @"
<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
    <LayoutOptions StartTileGroupCellWidth="6" />
    <DefaultLayoutOverride>
        <StartLayoutCollection>
            <defaultlayout:StartLayout GroupCellWidth="6" />
        </StartLayoutCollection>
    </DefaultLayoutOverride>
</LayoutModificationTemplate>
"@
    $layoutFile = "C:\Windows\StartMenuLayout.xml"
    If (Test-Path $layoutFile) { Remove-Item $layoutFile -Force }
    $START_MENU_LAYOUT | Out-File $layoutFile -Encoding ASCII

    $regAliases = @("HKLM", "HKCU")
    foreach ($regAlias in $regAliases) {
        $basePath = "$regAlias:\SOFTWARE\Policies\Microsoft\Windows"
        $keyPath = "$basePath\Explorer"
        If (-not (Test-Path $keyPath)) { New-Item -Path $basePath -Name "Explorer" -Force | Out-Null }
        Set-ItemProperty -Path $keyPath -Name "LockedStartLayout" -Value 1
        Set-ItemProperty -Path $keyPath -Name "StartLayoutFile" -Value $layoutFile
    }
    Stop-Process -Name explorer -Force
    Start-Sleep -Seconds 5
    $wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys('^{ESCAPE}')
    Start-Sleep -Seconds 5
    foreach ($regAlias in $regAliases) {
        $basePath = "$regAlias:\SOFTWARE\Policies\Microsoft\Windows"
        $keyPath = "$basePath\Explorer"
        Set-ItemProperty -Path $keyPath -Name "LockedStartLayout" -Value 0
    }
    Stop-Process -Name explorer -Force
    Remove-Item $layoutFile -Force
}

# --- 3D Objects removal/restoration ---
Function Remove3dObjects {
    Write-Host "Removing 3D Objects from explorer 'My Computer' submenu"
    $Objects32 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
    $Objects64 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
    If (Test-Path $Objects32) { Remove-Item $Objects32 -Recurse -Force }
    If (Test-Path $Objects64) { Remove-Item $Objects64 -Recurse -Force }
}

Function Restore3dObjects {
    Write-Host "Restoring 3D Objects to explorer 'My Computer' submenu"
    $Objects32 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
    $Objects64 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
    If (-not (Test-Path $Objects32)) { New-Item $Objects32 -Force | Out-Null }
    If (-not (Test-Path $Objects64)) { New-Item $Objects64 -Force | Out-Null }
}

# --- Missing functions added based on GitHub issues ---

Function DisableDiagTrack {
    Write-Output "Disabling Diagnostics Tracking Service (DiagTrack)"
    Stop-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
    Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
}

Function DisableWAPPush {
    Write-Output "Disabling WAP Push Service (dmwappushservice)"
    Stop-Service -Name "dmwappushservice" -ErrorAction SilentlyContinue
    Set-Service -Name "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue
}

Function CheckDMWService {
    Param([switch]$Debloat)
    If ((Get-Service -Name dmwappushservice -ErrorAction SilentlyContinue).StartType -eq "Disabled") {
        Set-Service -Name dmwappushservice -StartupType Automatic
    }
    If ((Get-Service -Name dmwappushservice -ErrorAction SilentlyContinue).Status -eq "Stopped") {
        Start-Service -Name dmwappushservice
    }
}

# --- Revert changes ---
Function Revert-Changes {
    # Reinstalls all removed bloatware.
    Get-AppxPackage -AllUsers | ForEach-Object {
        Add-AppxPackage -Verbose -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"
    }
    
    Write-Output "Re-enabling advertisement information"
    $Advertising = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    If (Test-Path $Advertising) { Set-ItemProperty $Advertising -Name Enabled -Value 1 }
    
    Write-Output "Re-enabling Cortana in Windows Search"
    $Search = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    If (Test-Path $Search) { Set-ItemProperty $Search -Name AllowCortana -Value 1 }
    
    Write-Output "Re-enabling Windows Feedback Experience"
    $Period = "HKCU:\Software\Microsoft\Siuf\Rules"
    If (-not (Test-Path $Period)) { New-Item $Period -Force | Out-Null }
    Set-ItemProperty $Period -Name PeriodInNanoSeconds -Value 1
    
    Write-Output "Allowing bloatware apps to return"
    $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    If (-not (Test-Path $registryPath)) { New-Item $registryPath -Force | Out-Null }
    Set-ItemProperty $registryPath -Name DisableWindowsConsumerFeatures -Value 0
    
    Write-Output "Restoring Mixed Reality Portal value"
    $Holo = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Holographic"
    If (Test-Path $Holo) { Set-ItemProperty $Holo -Name FirstRunSucceeded -Value 1 }
    
    Write-Output "Enabling live tiles"
    $Live = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"
    If (-not (Test-Path $Live)) { New-Item $Live -Force | Out-Null }
    Set-ItemProperty $Live -Name NoTileApplicationNotification -Value 0
    
    Write-Output "Re-enabling data collection"
    $DataCollection = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
    If (-not (Test-Path $DataCollection)) { New-Item $DataCollection -Force | Out-Null }
    Set-ItemProperty $DataCollection -Name AllowTelemetry -Value 1
    
    Write-Output "Enabling People icon on Taskbar"
    $People = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People"
    If (-not (Test-Path $People)) { New-Item $People -Force | Out-Null }
    Set-ItemProperty $People -Name PeopleBand -Value 1
    
    Write-Output "Enabling Start Menu suggestions"
    $Suggestions = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    If (-not (Test-Path $Suggestions)) { New-Item $Suggestions -Force | Out-Null }
    Set-ItemProperty $Suggestions -Name SystemPaneSuggestionsEnabled -Value 1
    
    Write-Output "Enabling scheduled tasks"
    Get-ScheduledTask -TaskName XblGameSaveTaskLogon | Enable-ScheduledTask
    Get-ScheduledTask -TaskName XblGameSaveTask | Enable-ScheduledTask
    Get-ScheduledTask -TaskName Consolidator | Enable-ScheduledTask
    Get-ScheduledTask -TaskName UsbCeip | Enable-ScheduledTask
    Get-ScheduledTask -TaskName DmClient | Enable-ScheduledTask
    Get-ScheduledTask -TaskName DmClientOnScenarioDownload | Enable-ScheduledTask

    Write-Output "Re-enabling and starting WAP Push Service"
    Set-Service -Name "dmwappushservice" -StartupType Automatic
    Start-Service -Name "dmwappushservice"
    
    Write-Output "Re-enabling and starting Diagnostics Tracking Service"
    Set-Service -Name "DiagTrack" -StartupType Automatic
    Start-Service -Name "DiagTrack"
    
    Write-Output "Restoring 3D Objects in explorer 'My Computer' submenu"
    Restore3dObjects
}

### INTERACTIVE PROMPTS ###
$Button = [Windows.MessageBoxButton]::YesNoCancel
$ErrorIco = [Windows.MessageBoxImage]::Error
$Warn = [Windows.MessageBoxImage]::Warning
$Ask = 'The following will allow you to either Debloat Windows 10 or revert changes made by this script.

Select "Yes" to Debloat Windows 10.
Select "No" to revert changes made by this script.
Select "Cancel" to stop the script.'

$EverythingorSpecific = "Would you like to remove everything that was preinstalled on your Windows machine? Select Yes to remove everything, or select No to remove apps via a blacklist."
$EdgePdf = "Do you want to stop Edge from taking over as the default PDF viewer?"
$EdgePdf2 = "Do you want to revert changes that disabled Edge as the default PDF viewer?"
$Reboot = "For some changes to properly take effect it is recommended to reboot your machine. Would you like to restart?"
$OneDriveDelete = "Do you want to uninstall OneDrive?"
$Unpin = "Do you want to unpin all items from the Start menu?"
$InstallNET = "Do you want to install .NET 3.5?"
#$LastUsedFilesFolders = "Do you want to hide last used files and folders in Explorer?"
#$LastUsedFilesFolders2 = "Do you want to show last used files and folders in Explorer?"
#$ClearLastUsedFilesFolders = "Do you want to clear last used files and folders?"
#$AeroShake = "Do you want to disable AeroShake?"
#$AeroShake2 = "Do you want to re-enable AeroShake?"

$Prompt1 = [Windows.MessageBox]::Show($Ask, "Debloat or Revert", $Button, $ErrorIco)
Switch ($Prompt1) {
    Yes {
        # Debloat branch.
        $Prompt2 = [Windows.MessageBox]::Show($EverythingorSpecific, "Everything or Specific", $Button, $Warn)
        Switch ($Prompt2) {
            Yes { 
                Write-Host "Creating PSDrive 'HKCR' (HKEY_CLASSES_ROOT) for registry modifications."
                New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
                Start-Sleep 1
                Write-Host "Uninstalling all bloatware..."
                DebloatAll
                Write-Host "Bloatware removed."
                Start-Sleep 1
                Write-Host "Removing specific registry keys..."
                Remove-Keys
                Write-Host "Leftover bloatware registry keys removed."
                Start-Sleep 1
                Write-Host "Reinstalling any missing whitelisted apps..."
                FixWhitelistedApps
                Start-Sleep 1
                Write-Host "Applying privacy protections (disabling Cortana, telemetry, etc.)..."
                Protect-Privacy
                Start-Sleep 1
                DisableCortana
                Write-Host "Cortana disabled and telemetry settings applied."
                Start-Sleep 1
                Write-Host "Disabling Diagnostics Tracking Service..."
                DisableDiagTrack
                Write-Host "Diagnostics Tracking Service disabled."
                Start-Sleep 1
                Write-Host "Disabling WAP Push Service..."
                DisableWAPPush
                Start-Sleep 1
                Write-Host "Re-enabling DMWAppushservice if necessary..."
                CheckDMWService
                Start-Sleep 1
                Write-Host "Removing 3D Objects from explorer 'My Computer' submenu..."
                Remove3dObjects
                Start-Sleep 1
            }
            No {
                Write-Host "Creating PSDrive 'HKCR' (HKEY_CLASSES_ROOT) for registry modifications."
                New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
                Start-Sleep 1
                Write-Host "Uninstalling bloatware via blacklist..."
                DebloatBlacklist
                Write-Host "Bloatware removed."
                Start-Sleep 1
                Write-Host "Removing specific registry keys..."
                Remove-Keys
                Write-Host "Leftover bloatware registry keys removed."
                Start-Sleep 1
                Write-Host "Reinstalling any missing whitelisted apps..."
                FixWhitelistedApps
                Start-Sleep 1
                Write-Host "Applying privacy protections (disabling Cortana, telemetry, etc.)..."
                Protect-Privacy
                Start-Sleep 1
                DisableCortana
                Write-Host "Cortana disabled and telemetry settings applied."
                Start-Sleep 1
                Write-Host "Disabling Diagnostics Tracking Service..."
                DisableDiagTrack
                Write-Host "Diagnostics Tracking Service disabled."
                Start-Sleep 1
                Write-Host "Disabling WAP Push Service..."
                DisableWAPPush
                Start-Sleep 1
                Write-Host "Re-enabling DMWAppushservice if necessary..."
                CheckDMWService
                Start-Sleep 1
            }
        }
        # Edge PDF prompt.
        $Prompt3 = [Windows.MessageBox]::Show($EdgePdf, "Edge PDF", $Button, $Warn)
        Switch ($Prompt3) {
            Yes {
                Stop-EdgePDF
                Write-Host "Edge will no longer take over as the default PDF viewer."
            }
            No {
                Write-Host "You chose not to change Edge PDF settings."
            }
        }
        # OneDrive removal prompt.
        $Prompt4 = [Windows.MessageBox]::Show($OneDriveDelete, "Delete OneDrive", $Button, $ErrorIco)
        Switch ($Prompt4) {
            Yes {
                UninstallOneDrive
                Write-Host "OneDrive has been removed from the computer."
            }
            No {
                Write-Host "Skipping OneDrive removal."
            }
        }
        # Unpin Start menu prompt.
        $Prompt5 = [Windows.MessageBox]::Show($Unpin, "Unpin Start Items", $Button, $ErrorIco)
        Switch ($Prompt5) {
            Yes {
                UnpinStart
                Write-Host "Start menu items have been unpinned."
            }
            No {
                Write-Host "Keeping current Start menu items."
            }
        }
        # .NET 3.5 installation prompt.
        $Prompt6 = [Windows.MessageBox]::Show($InstallNET, "Install .NET", $Button, $Warn)
        Switch ($Prompt6) {
            Yes {
                Write-Host "Installing .NET 3.5..."
                DISM /Online /Enable-Feature /FeatureName:NetFx3 /All
                Write-Host ".NET 3.5 has been successfully installed!"
            }
            No {
                Write-Host "Skipping .NET installation."
            }
        }
        # Prompt to reboot.
        $Prompt0 = [Windows.MessageBox]::Show($Reboot, "Reboot", $Button, $Warn)
        Switch ($Prompt0) {
            Yes {
                Write-Host "Removing HKCR drive..."
                Remove-PSDrive HKCR
                Start-Sleep 1
                Write-Host "Initiating reboot..."
                Stop-Transcript
                Start-Sleep 2
                Restart-Computer
            }
            No {
                Write-Host "Removing HKCR drive..."
                Remove-PSDrive HKCR
                Start-Sleep 1
                Write-Host "Script finished. Exiting."
                Stop-Transcript
                Start-Sleep 2
                Exit
            }
        }
    }
    No {
        Write-Host "Reverting changes..."
        Write-Host "Creating PSDrive 'HKCR' (HKEY_CLASSES_ROOT) for registry modifications."
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
        Revert-Changes
        # Prompt to revert Edge PDF changes.
        $Prompt6 = [Windows.MessageBox]::Show($EdgePdf2, "Revert Edge PDF", $Button, $ErrorIco)
        Switch ($Prompt6) {
            Yes {
                Enable-EdgePDF
                Write-Host "Edge PDF settings have been reverted."
            }
            No {
                Write-Host "Keeping current Edge PDF settings."
            }
        }
        # Prompt to reboot.
        $Prompt0 = [Windows.MessageBox]::Show($Reboot, "Reboot", $Button, $Warn)
        Switch ($Prompt0) {
            Yes {
                Write-Host "Removing HKCR drive..."
                Remove-PSDrive HKCR
                Start-Sleep 1
                Write-Host "Initiating reboot..."
                Stop-Transcript
                Start-Sleep 2
                Restart-Computer
            }
            No {
                Write-Host "Removing HKCR drive..."
                Remove-PSDrive HKCR
                Start-Sleep 1
                Write-Host "Script finished. Exiting."
                Stop-Transcript
                Start-Sleep 2
                Exit
            }
        }
    }
}
