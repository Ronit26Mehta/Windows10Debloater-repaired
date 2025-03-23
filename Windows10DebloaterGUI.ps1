<#
    This script is the GUI implementation for Windows10Debloater.
    It uses Windows Forms to offer various debloat, registry, and privacy‐fix options.
    The logic remains unchanged from the original; only improvements and repairs have been applied.
    
    Note: Related files (such as custom-lists.ps1) are not modified.
    
    Please review and test thoroughly.
#>

# Self–elevation prompt (if not already running as administrator)
$ErrorActionPreference = 'SilentlyContinue'
$Button       = [System.Windows.MessageBoxButton]::YesNoCancel
$ErrorIco     = [System.Windows.MessageBoxImage]::Error
$Ask          = @"
Do you want to run this as an Administrator?

Select "Yes" to Run as an Administrator
Select "No" to not run as an Administrator
Select "Cancel" to stop the script.
"@
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    $Prompt = [System.Windows.MessageBox]::Show($Ask, "Run as an Administrator or not?", $Button, $ErrorIco)
    switch ($Prompt) {
        'Yes' {
            Write-Host "Restarting script with elevated privileges..."
            Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
            Exit
        }
        'No' {
            # Continue without elevation
        }
        default {
            Exit
        }
    }
}

# Global lists for bloatware and whitelist
$global:Bloatware = @(
    "Microsoft.PPIProjection",
    "Microsoft.BingNews",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.Messaging",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.NetworkSpeedTest",
    "Microsoft.News",                                    # Issue 77
    "Microsoft.Office.Lens",                             # Issue 77
    "Microsoft.Office.OneNote",
    "Microsoft.Office.Sway",
    "Microsoft.OneConnect",
    "Microsoft.People",
    "Microsoft.Print3D",
    "Microsoft.RemoteDesktop",                           # Issue 120
    "Microsoft.SkypeApp",
    "Microsoft.StorePurchaseApp",
    "Microsoft.Office.Todo.List",                        # Issue 77
    "Microsoft.Whiteboard",                              # Issue 77
    "Microsoft.WindowsAlarms",
    "microsoft.windowscommunicationsapps",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    # Sponsored Windows 10 AppX Apps (wildcard style matching later)
    "EclipseManager",
    "ActiproSoftwareLLC",
    "AdobeSystemsIncorporated.AdobePhotoshopExpress",
    "Duolingo-LearnLanguagesforFree",
    "PandoraMediaInc",
    "CandyCrush",
    "BubbleWitch3Saga",
    "Wunderlist",
    "Flipboard",
    "Twitter",
    "Facebook",
    "Spotify",                                           # Issue 123
    "Minecraft",
    "Royal Revolt",
    "Sway",                                              # Issue 77
    "Dolby"                                             # Issue 78
)

$global:WhiteListedApps = @(
    "Microsoft.WindowsCalculator",               # Modern calculator
    "Microsoft.WindowsStore",                    # Windows Store
    "Microsoft.Windows.Photos",                  # Windows Photos
    "CanonicalGroupLimited.UbuntuonWindows",     # Ubuntu on Windows
    "Microsoft.Xbox.TCUI",                       # Xbox-related apps (keep for gaming)
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",               # Xbox overlay apps
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.MicrosoftStickyNotes",            # Sticky Notes
    "Microsoft.MSPaint",                         # Legacy Paint (while Paint3D exists)
    "Microsoft.WindowsCamera",                   # Windows Camera
    "\.NET",                                     # .NET frameworks
    "Microsoft.HEIFImageExtension",              # HEIF support
    "Microsoft.ScreenSketch",                    # Snip & Sketch
    "Microsoft.StorePurchaseApp",                # Store Purchase
    "Microsoft.VP9VideoExtensions",              # VP9 Video
    "Microsoft.WebMediaExtensions",              # Web Media
    "Microsoft.WebpImageExtension",              # WebP support
    "Microsoft.DesktopAppInstaller",             # Desktop App Installer
    "WindSynthBerry",                            # Music synth
    "MIDIBerry",                                 # MIDI app
    "Slack",                                     # Slack app
    "*Nvidia*",                                  # Nvidia drivers-related package
    "Microsoft.MixedReality.Portal"              # Mixed Reality Portal
)

# Build regex strings for matching
$global:BloatwareRegex      = ($global:Bloatware -join '|')
$global:WhiteListedAppsRegex= ($global:WhiteListedApps -join '|')

# Import custom lists (if any)
Function dotInclude {
    param(
        [Parameter(Mandatory)]
        [string]$includeFile
    )
    $scriptPath = $PSScriptRoot
    if (-not $scriptPath -and $psISE) {
        $scriptPath = (Split-Path -Path $psISE.CurrentFile.FullPath)
    }
    $file = Join-Path -Path $scriptPath -ChildPath $includeFile
    if (Test-Path $file) {
        . $file
    }
}
dotInclude 'custom-lists.ps1'
# Rebuild regex with any overrides
$global:BloatwareRegex      = ($global:Bloatware -join '|')
$global:WhiteListedAppsRegex= ($global:WhiteListedApps -join '|')

# Setup GUI (using Windows Forms)
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object System.Windows.Forms.Form
$Form.ClientSize                 = New-Object System.Drawing.Size(500,570)
$Form.StartPosition              = 'CenterScreen'
$Form.FormBorderStyle            = 'FixedSingle'
$Form.MinimizeBox                = $false
$Form.MaximizeBox                = $false
$Form.ShowIcon                   = $false
$Form.Text                       = "Windows10Debloater"
$Form.TopMost                    = $false
$Form.BackColor                  = [System.Drawing.ColorTranslator]::FromHtml("#252525")

# Panels for various sections
$DebloatPanel = New-Object System.Windows.Forms.Panel
$DebloatPanel.Size = New-Object System.Drawing.Size(480,160)
$DebloatPanel.Location = New-Object System.Drawing.Point(10,10)

$RegistryPanel = New-Object System.Windows.Forms.Panel
$RegistryPanel.Size = New-Object System.Drawing.Size(480,80)
$RegistryPanel.Location = New-Object System.Drawing.Point(10,180)

$CortanaPanel = New-Object System.Windows.Forms.Panel
$CortanaPanel.Size = New-Object System.Drawing.Size(153,120)
$CortanaPanel.Location = New-Object System.Drawing.Point(10,270)

$EdgePanel = New-Object System.Windows.Forms.Panel
$EdgePanel.Size = New-Object System.Drawing.Size(154,120)
$EdgePanel.Location = New-Object System.Drawing.Point(173,270)

$DarkThemePanel = New-Object System.Windows.Forms.Panel
$DarkThemePanel.Size = New-Object System.Drawing.Size(153,120)
$DarkThemePanel.Location = New-Object System.Drawing.Point(337,270)

$OtherPanel = New-Object System.Windows.Forms.Panel
$OtherPanel.Size = New-Object System.Drawing.Size(480,160)
$OtherPanel.Location = New-Object System.Drawing.Point(10,400)

# Labels and Buttons for Debloat options
$Debloat = New-Object System.Windows.Forms.Label
$Debloat.Text = "DEBLOAT OPTIONS"
$Debloat.AutoSize = $true
$Debloat.Font = New-Object System.Drawing.Font("Consolas",15,[System.Drawing.FontStyle]::Bold)
$Debloat.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")
$Debloat.Location = New-Object System.Drawing.Point(10,9)

$CustomizeBlacklist = New-Object System.Windows.Forms.Button
$CustomizeBlacklist.FlatStyle = 'Flat'
$CustomizeBlacklist.Text = "CUSTOMISE BLOCKLIST"
$CustomizeBlacklist.Size = New-Object System.Drawing.Size(460,30)
$CustomizeBlacklist.Font = New-Object System.Drawing.Font("Consolas",9)
$CustomizeBlacklist.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")
$CustomizeBlacklist.Location = New-Object System.Drawing.Point(10,40)

$RemoveAllBloatware = New-Object System.Windows.Forms.Button
$RemoveAllBloatware.FlatStyle = 'Flat'
$RemoveAllBloatware.Text = "REMOVE ALL BLOATWARE"
$RemoveAllBloatware.Size = New-Object System.Drawing.Size(460,30)
$RemoveAllBloatware.Font = New-Object System.Drawing.Font("Consolas",9)
$RemoveAllBloatware.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")
$RemoveAllBloatware.Location = New-Object System.Drawing.Point(10,80)

$RemoveBlacklistedBloatware = New-Object System.Windows.Forms.Button
$RemoveBlacklistedBloatware.FlatStyle = 'Flat'
$RemoveBlacklistedBloatware.Text = "REMOVE BLOATWARE WITH CUSTOM BLOCKLIST"
$RemoveBlacklistedBloatware.Size = New-Object System.Drawing.Size(460,30)
$RemoveBlacklistedBloatware.Font = New-Object System.Drawing.Font("Consolas",9)
$RemoveBlacklistedBloatware.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")
$RemoveBlacklistedBloatware.Location = New-Object System.Drawing.Point(10,120)

# Registry Panel controls
$Registry = New-Object System.Windows.Forms.Label
$Registry.Text = "REGISTRY CHANGES"
$Registry.AutoSize = $true
$Registry.Font = New-Object System.Drawing.Font("Consolas",15,[System.Drawing.FontStyle]::Bold)
$Registry.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")
$Registry.Location = New-Object System.Drawing.Point(10,10)

$RevertChanges = New-Object System.Windows.Forms.Button
$RevertChanges.FlatStyle = 'Flat'
$RevertChanges.Text = "REVERT REGISTRY CHANGES"
$RevertChanges.Size = New-Object System.Drawing.Size(460,30)
$RevertChanges.Font = New-Object System.Drawing.Font("Consolas",9)
$RevertChanges.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")
$RevertChanges.Location = New-Object System.Drawing.Point(10,40)

# Cortana Panel controls
$Cortana = New-Object System.Windows.Forms.Label
$Cortana.Text = "CORTANA"
$Cortana.AutoSize = $true
$Cortana.Font = New-Object System.Drawing.Font("Consolas",15,[System.Drawing.FontStyle]::Bold)
$Cortana.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")
$Cortana.Location = New-Object System.Drawing.Point(10,10)

$EnableCortana = New-Object System.Windows.Forms.Button
$EnableCortana.FlatStyle = 'Flat'
$EnableCortana.Text = "ENABLE"
$EnableCortana.Size = New-Object System.Drawing.Size(133,30)
$EnableCortana.Font = New-Object System.Drawing.Font("Consolas",9)
$EnableCortana.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")
$EnableCortana.Location = New-Object System.Drawing.Point(10,40)

$DisableCortana = New-Object System.Windows.Forms.Button
$DisableCortana.FlatStyle = 'Flat'
$DisableCortana.Text = "DISABLE"
$DisableCortana.Size = New-Object System.Drawing.Size(133,30)
$DisableCortana.Font = New-Object System.Drawing.Font("Consolas",9)
$DisableCortana.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")
$DisableCortana.Location = New-Object System.Drawing.Point(10,80)

# Edge Panel controls
$Edge = New-Object System.Windows.Forms.Label
$Edge.Text = "EDGE PDF"
$Edge.AutoSize = $true
$Edge.Font = New-Object System.Drawing.Font("Consolas",15,[System.Drawing.FontStyle]::Bold)
$Edge.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")
$Edge.Location = New-Object System.Drawing.Point(10,10)

$EnableEdgePDFTakeover = New-Object System.Windows.Forms.Button
$EnableEdgePDFTakeover.FlatStyle = 'Flat'
$EnableEdgePDFTakeover.Text = "ENABLE"
$EnableEdgePDFTakeover.Size = New-Object System.Drawing.Size(134,30)
$EnableEdgePDFTakeover.Font = New-Object System.Drawing.Font("Consolas",9)
$EnableEdgePDFTakeover.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")
$EnableEdgePDFTakeover.Location = New-Object System.Drawing.Point(10,40)

$DisableEdgePDFTakeover = New-Object System.Windows.Forms.Button
$DisableEdgePDFTakeover.FlatStyle = 'Flat'
$DisableEdgePDFTakeover.Text = "DISABLE"
$DisableEdgePDFTakeover.Size = New-Object System.Drawing.Size(134,30)
$DisableEdgePDFTakeover.Font = New-Object System.Drawing.Font("Consolas",9)
$DisableEdgePDFTakeover.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")
$DisableEdgePDFTakeover.Location = New-Object System.Drawing.Point(10,80)

# Dark Theme Panel controls
$Theme = New-Object System.Windows.Forms.Label
$Theme.Text = "DARK THEME"
$Theme.AutoSize = $true
$Theme.Font = New-Object System.Drawing.Font("Consolas",15,[System.Drawing.FontStyle]::Bold)
$Theme.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")
$Theme.Location = New-Object System.Drawing.Point(10,10)

$EnableDarkMode = New-Object System.Windows.Forms.Button
$EnableDarkMode.FlatStyle = 'Flat'
$EnableDarkMode.Text = "ENABLE"
$EnableDarkMode.Size = New-Object System.Drawing.Size(133,30)
$EnableDarkMode.Font = New-Object System.Drawing.Font("Consolas",9)
$EnableDarkMode.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")
$EnableDarkMode.Location = New-Object System.Drawing.Point(10,40)

$DisableDarkMode = New-Object System.Windows.Forms.Button
$DisableDarkMode.FlatStyle = 'Flat'
$DisableDarkMode.Text = "DISABLE"
$DisableDarkMode.Size = New-Object System.Drawing.Size(133,30)
$DisableDarkMode.Font = New-Object System.Drawing.Font("Consolas",9)
$DisableDarkMode.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")
$DisableDarkMode.Location = New-Object System.Drawing.Point(10,80)

# Other Panel controls
$Other = New-Object System.Windows.Forms.Label
$Other.Text = "OTHER CHANGES & FIXES"
$Other.AutoSize = $true
$Other.Font = New-Object System.Drawing.Font("Consolas",15,[System.Drawing.FontStyle]::Bold)
$Other.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")
$Other.Location = New-Object System.Drawing.Point(10,10)

$RemoveOnedrive = New-Object System.Windows.Forms.Button
$RemoveOnedrive.FlatStyle = 'Flat'
$RemoveOnedrive.Text = "UNINSTALL ONEDRIVE"
$RemoveOnedrive.Size = New-Object System.Drawing.Size(225,30)
$RemoveOnedrive.Font = New-Object System.Drawing.Font("Consolas",9)
$RemoveOnedrive.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")
$RemoveOnedrive.Location = New-Object System.Drawing.Point(10,40)

$UnpinStartMenuTiles = New-Object System.Windows.Forms.Button
$UnpinStartMenuTiles.FlatStyle = 'Flat'
$UnpinStartMenuTiles.Text = "UNPIN TILES FROM START MENU"
$UnpinStartMenuTiles.Size = New-Object System.Drawing.Size(225,30)
$UnpinStartMenuTiles.Font = New-Object System.Drawing.Font("Consolas",9)
$UnpinStartMenuTiles.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")
$UnpinStartMenuTiles.Location = New-Object System.Drawing.Point(245,40)

$DisableTelemetry = New-Object System.Windows.Forms.Button
$DisableTelemetry.FlatStyle = 'Flat'
$DisableTelemetry.Text = "DISABLE TELEMETRY / TASKS"
$DisableTelemetry.Size = New-Object System.Drawing.Size(225,30)
$DisableTelemetry.Font = New-Object System.Drawing.Font("Consolas",9)
$DisableTelemetry.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")
$DisableTelemetry.Location = New-Object System.Drawing.Point(10,80)

$RemoveRegkeys = New-Object System.Windows.Forms.Button
$RemoveRegkeys.FlatStyle = 'Flat'
$RemoveRegkeys.Text = "REMOVE BLOATWARE REGKEYS"
$RemoveRegkeys.Size = New-Object System.Drawing.Size(225,30)
$RemoveRegkeys.Font = New-Object System.Drawing.Font("Consolas",9)
$RemoveRegkeys.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")
$RemoveRegkeys.Location = New-Object System.Drawing.Point(245,80)

$InstallNet35 = New-Object System.Windows.Forms.Button
$InstallNet35.FlatStyle = 'Flat'
$InstallNet35.Text = "INSTALL .NET V3.5"
$InstallNet35.Size = New-Object System.Drawing.Size(460,30)
$InstallNet35.Font = New-Object System.Drawing.Font("Consolas",9)
$InstallNet35.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")
$InstallNet35.Location = New-Object System.Drawing.Point(10,120)

# Add panels to the form
$Form.Controls.AddRange(@($RegistryPanel,$DebloatPanel,$CortanaPanel,$EdgePanel,$DarkThemePanel,$OtherPanel))
$DebloatPanel.Controls.AddRange(@($Debloat,$CustomizeBlacklist,$RemoveAllBloatware,$RemoveBlacklistedBloatware))
$RegistryPanel.Controls.AddRange(@($Registry,$RevertChanges))
$CortanaPanel.Controls.AddRange(@($Cortana,$EnableCortana,$DisableCortana))
$EdgePanel.Controls.AddRange(@($EnableEdgePDFTakeover,$DisableEdgePDFTakeover,$Edge))
$DarkThemePanel.Controls.AddRange(@($Theme,$EnableDarkMode,$DisableDarkMode))
$OtherPanel.Controls.AddRange(@($Other,$RemoveOnedrive,$InstallNet35,$UnpinStartMenuTiles,$DisableTelemetry,$RemoveRegkeys))

# Create log folder if not present and start transcript
$DebloatFolder = "C:\Temp\Windows10Debloater"
if (-not (Test-Path $DebloatFolder)) {
    Write-Host "Creating log folder $DebloatFolder..."
    New-Item -Path $DebloatFolder -ItemType Directory -Force | Out-Null
    Write-Host "Log folder created."
} else {
    Write-Host "$DebloatFolder already exists. Skipping folder creation."
}
Start-Transcript -OutputDirectory $DebloatFolder

Write-Output "Creating System Restore Point (if one does not already exist)..."
Checkpoint-Computer -Description "Before using W10DebloaterGUI.ps1" -ErrorAction SilentlyContinue

#region GUI event handlers

# Customize blocklist event
$CustomizeBlacklist.Add_Click({
    $CustomizeForm = New-Object System.Windows.Forms.Form
    $CustomizeForm.ClientSize = New-Object System.Drawing.Size(580,570)
    $CustomizeForm.StartPosition = 'CenterScreen'
    $CustomizeForm.FormBorderStyle = 'FixedSingle'
    $CustomizeForm.MinimizeBox = $false
    $CustomizeForm.MaximizeBox = $false
    $CustomizeForm.ShowIcon = $false
    $CustomizeForm.Text = "Customize Allowlist and Blocklist"
    $CustomizeForm.TopMost = $false
    $CustomizeForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#252525")

    $ListPanel = New-Object System.Windows.Forms.Panel
    $ListPanel.Size = New-Object System.Drawing.Size(572,510)
    $ListPanel.Location = New-Object System.Drawing.Point(10,10)
    $ListPanel.AutoScroll = $true
    $ListPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#252525")

    $SaveList = New-Object System.Windows.Forms.Button
    $SaveList.FlatStyle = 'Flat'
    $SaveList.Text = "Save custom Allowlist and Blocklist to custom-lists.ps1"
    $SaveList.Size = New-Object System.Drawing.Size(560,30)
    $SaveList.Location = New-Object System.Drawing.Point(10,530)
    $SaveList.Font = New-Object System.Drawing.Font("Consolas",9)
    $SaveList.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")

    $CustomizeForm.Controls.AddRange(@($SaveList,$ListPanel))

    $SaveList.Add_Click({
        $customListPath = Join-Path -Path $PSScriptRoot -ChildPath "custom-lists.ps1"
        # Write white list block
        '@
$global:WhiteListedApps = @(
'@ | Out-File -FilePath $customListPath -Encoding utf8
        foreach ($ctrl in $ListPanel.Controls) {
            if ($ctrl -is [System.Windows.Forms.CheckBox] -and $ctrl.Enabled -and -not $ctrl.Checked) {
                "    `"$($ctrl.Text)`"," | Out-File -FilePath $customListPath -Append -Encoding utf8
            }
        }
        ")" | Out-File -FilePath $customListPath -Append -Encoding utf8
        # Write bloatware block
        '@
$global:Bloatware = @(
'@ | Out-File -FilePath $customListPath -Append -Encoding utf8
        foreach ($ctrl in $ListPanel.Controls) {
            if ($ctrl -is [System.Windows.Forms.CheckBox] -and $ctrl.Enabled -and $ctrl.Checked) {
                "    `"$($ctrl.Text)`"," | Out-File -FilePath $customListPath -Append -Encoding utf8
            }
        }
        ")" | Out-File -FilePath $customListPath -Append -Encoding utf8

        # Override the global lists with the new custom lists
        dotInclude "custom-lists.ps1"
        $global:BloatwareRegex = ($global:Bloatware -join '|')
        $global:WhiteListedAppsRegex = ($global:WhiteListedApps -join '|')
    })

    function AddAppToCustomizeForm {
        param(
            [Parameter(Mandatory)]
            [int]$position,
            [Parameter(Mandatory)]
            [string]$appName,
            [Parameter(Mandatory)]
            [bool]$enabled,
            [Parameter(Mandatory)]
            [bool]$checked,
            [Parameter(Mandatory)]
            [bool]$autocheck,
            [string]$notes
        )
        $label = New-Object System.Windows.Forms.Label
        $label.Location = New-Object System.Drawing.Point(0, (2 + $position * 25))
        $label.Text = $notes
        $label.Font = New-Object System.Drawing.Font("Consolas",8)
        $label.Size = New-Object System.Drawing.Size(260,27)
        $label.TextAlign = [System.Drawing.ContentAlignment]::TopRight
        $label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#888888")
        $ListPanel.Controls.Add($label)

        $Checkbox = New-Object System.Windows.Forms.CheckBox
        $Checkbox.Text = $appName
        $Checkbox.Font = New-Object System.Drawing.Font("Consolas",8)
        $Checkbox.FlatStyle = 'Flat'
        $Checkbox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")
        $Checkbox.Location = New-Object System.Drawing.Point(268, (0 + $position * 25))
        $Checkbox.AutoSize = $true
        $Checkbox.Checked = $checked
        $Checkbox.Enabled = $enabled
        $Checkbox.AutoCheck = $autocheck
        $ListPanel.Controls.Add($Checkbox)
    }

    # Gather installed, online, and all-users apps
    $Installed = (Get-AppxPackage).Name
    $Online    = (Get-AppxProvisionedPackage -Online).DisplayName
    $AllUsers  = (Get-AppxPackage -AllUsers).Name
    $checkboxCounter = 0

    foreach ($item in $NonRemovables) {
        $string = ""
        if ($global:BloatwareRegex -and ($item -cmatch $global:BloatwareRegex)) { $string += " ConflictBlacklist" }
        if ($global:WhiteListedAppsRegex -and ($item -cmatch $global:WhiteListedAppsRegex)) { $string += " ConflictWhitelist" }
        if ($Installed -contains $item) { $string += " Installed" }
        if ($AllUsers -contains $item) { $string += " AllUsers" }
        if ($Online -contains $item) { $string += " Online" }
        $string += " Non-Removable"
        AddAppToCustomizeForm -position $checkboxCounter -appName $item -enabled $true -checked $false -autocheck $false -notes $string
        $checkboxCounter++
    }
    foreach ($item in $global:WhiteListedApps) {
        $string = ""
        if ($NonRemovables -contains $item) { $string += " Conflict NonRemovables" }
        if ($global:BloatwareRegex -and ($item -cmatch $global:BloatwareRegex)) { $string += " ConflictBlacklist" }
        if ($Installed -contains $item) { $string += " Installed" }
        if ($AllUsers -contains $item) { $string += " AllUsers" }
        if ($Online -contains $item) { $string += " Online" }
        AddAppToCustomizeForm -position $checkboxCounter -appName $item -enabled $true -checked $false -autocheck $true -notes $string
        $checkboxCounter++
    }
    foreach ($item in $global:Bloatware) {
        $string = ""
        if ($NonRemovables -contains $item) { $string += " Conflict NonRemovables" }
        if ($global:WhiteListedAppsRegex -and ($item -cmatch $global:WhiteListedAppsRegex)) { $string += " Conflict Whitelist" }
        if ($Installed -contains $item) { $string += " Installed" }
        if ($AllUsers -contains $item) { $string += " AllUsers" }
        if ($Online -contains $item) { $string += " Online" }
        AddAppToCustomizeForm -position $checkboxCounter -appName $item -enabled $true -checked $true -autocheck $true -notes $string
        $checkboxCounter++
    }
    foreach ($item in $AllUsers) {
        if ($NonRemovables -contains $item -or ($global:WhiteListedAppsRegex -and ($item -cmatch $global:WhiteListedAppsRegex)) -or ($global:BloatwareRegex -and ($item -cmatch $global:BloatwareRegex))) { continue }
        $string = "NEW AllUsers"
        if ($Installed -contains $item) { $string += " Installed" }
        if ($Online -contains $item) { $string += " Online" }
        AddAppToCustomizeForm -position $checkboxCounter -appName $item -enabled $true -checked $true -autocheck $true -notes $string
        $checkboxCounter++
    }
    foreach ($item in $Installed) {
        if (($AllUsers -contains $item) -or ($global:WhiteListedAppsRegex -and ($item -cmatch $global:WhiteListedAppsRegex)) -or ($global:BloatwareRegex -and ($item -cmatch $global:BloatwareRegex))) { continue }
        $string = "NEW Installed"
        if ($Online -contains $item) { $string += " Online" }
        AddAppToCustomizeForm -position $checkboxCounter -appName $item -enabled $true -checked $true -autocheck $true -notes $string
        $checkboxCounter++
    }
    foreach ($item in $Online) {
        if (($Installed -contains $item) -or ($AllUsers -contains $item) -or ($global:WhiteListedAppsRegex -and ($item -cmatch $global:WhiteListedAppsRegex)) -or ($global:BloatwareRegex -and ($item -cmatch $global:BloatwareRegex))) { continue }
        $string = "NEW Online"
        AddAppToCustomizeForm -position $checkboxCounter -appName $item -enabled $true -checked $true -autocheck $true -notes $string
        $checkboxCounter++
    }
    [void]$CustomizeForm.ShowDialog()
})

# Remove Blacklisted Bloatware event
$RemoveBlacklistedBloatware.Add_Click({
    $ErrorActionPreference = 'SilentlyContinue'
    function DebloatBlacklist {
        Write-Host "Removing blocklisted bloatware matching: $global:BloatwareRegex"
        Write-Host "--- This may take a while - please be patient ---"
        Get-AppxPackage | Where-Object { $_.Name -cmatch $global:BloatwareRegex } | Remove-AppxPackage
        Write-Host "Removing provisioned packages..."
        Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -cmatch $global:BloatwareRegex } | Remove-AppxProvisionedPackage -Online
        Write-Host "Removing from all users..."
        Get-AppxPackage -AllUsers | Where-Object { $_.Name -cmatch $global:BloatwareRegex } | Remove-AppxPackage
    }
    Write-Host "Removing blocklisted bloatware..."
    DebloatBlacklist
    Write-Host "Bloatware removed!"
})

# Remove All Bloatware event
$RemoveAllBloatware.Add_Click({
    $ErrorActionPreference = 'SilentlyContinue'

    # Begin system preparation fixes
    function Begin-SysPrep {
        Write-Host "Starting Sysprep Fixes..."
        Write-Host "Disabling Windows Store Automatic Updates..."
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
        if (-not (Test-Path $registryPath)) {
            New-Item -Path $registryPath -Force | Out-Null
            New-ItemProperty -Path $registryPath -Name AutoDownload -Value 2 -Force | Out-Null
        }
        Set-ItemProperty -Path $registryPath -Name AutoDownload -Value 2 -Force

        Write-Host "Stopping InstallService..."
        Stop-Service InstallService -ErrorAction SilentlyContinue
        Write-Host "Setting InstallService startup type to Disabled..."
        Set-Service InstallService -StartupType Disabled -ErrorAction SilentlyContinue
    }

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

    function DebloatAll {
        Write-Host "Removing all removable AppX packages..."
        Get-AppxPackage | Where-Object {
            ($_ .Name -notcmatch $global:WhiteListedAppsRegex) -and (-not ($NonRemovables -cmatch $_.Name))
        } | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object {
            ($_ .DisplayName -notcmatch $global:WhiteListedAppsRegex) -and (-not ($NonRemovables -cmatch $_.DisplayName))
        } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        Get-AppxPackage -AllUsers | Where-Object {
            ($_ .Name -notcmatch $global:WhiteListedAppsRegex) -and (-not ($NonRemovables -cmatch $_.Name))
        } | Remove-AppxPackage -ErrorAction SilentlyContinue
    }

    # Create PSDrive for HKCR access
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null

    function Remove-Keys {
        $Keys = @(
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y",
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0",
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe",
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy",
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy",
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy",
            "HKCR:\Extensions\ContractId\Windows.File\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0",
            "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y",
            "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0",
            "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy",
            "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy",
            "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy",
            "HKCR:\Extensions\ContractId\Windows.PreInstalledConfigTask\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe",
            "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0",
            "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy",
            "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy",
            "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy",
            "HKCR:\Extensions\ContractId\Windows.ShareTarget\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
        )
        foreach ($Key in $Keys) {
            Write-Output "Removing registry key: $Key"
            Remove-Item $Key -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    function Protect-Privacy {
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
        Write-Host "Disabling Windows Feedback Experience..."
        $Advertising = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
        if (Test-Path $Advertising) { Set-ItemProperty $Advertising -Name Enabled -Value 0 }
        Write-Host "Disabling Cortana from Windows Search..."
        $Search = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        if (Test-Path $Search) { Set-ItemProperty $Search -Name AllowCortana -Value 0 }
        Write-Host "Disabling Bing Search in Start Menu..."
        $WebSearch = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name BingSearchEnabled -Value 0
        if (-not (Test-Path $WebSearch)) { New-Item $WebSearch -Force | Out-Null }
        Set-ItemProperty $WebSearch -Name DisableWebSearch -Value 1
        Write-Host "Stopping Feedback Experience data collection..."
        $Period = "HKCU:\Software\Microsoft\Siuf\Rules"
        if (-not (Test-Path $Period)) { New-Item $Period -Force | Out-Null }
        Set-ItemProperty $Period -Name PeriodInNanoSeconds -Value 0
        Write-Host "Preventing bloatware apps from returning..."
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
        $registryOEM = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        if (-not (Test-Path $registryPath)) { New-Item $registryPath -Force | Out-Null }
        Set-ItemProperty $registryPath -Name DisableWindowsConsumerFeatures -Value 1
        if (-not (Test-Path $registryOEM)) { New-Item $registryOEM -Force | Out-Null }
        Set-ItemProperty $registryOEM -Name ContentDeliveryAllowed -Value 0
        Set-ItemProperty $registryOEM -Name OemPreInstalledAppsEnabled -Value 0
        Set-ItemProperty $registryOEM -Name PreInstalledAppsEnabled -Value 0
        Set-ItemProperty $registryOEM -Name PreInstalledAppsEverEnabled -Value 0
        Set-ItemProperty $registryOEM -Name SilentInstalledAppsEnabled -Value 0
        Set-ItemProperty $registryOEM -Name SystemPaneSuggestionsEnabled -Value 0
        Write-Host "Setting Mixed Reality Portal FirstRunSucceeded to 0..."
        $Holo = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Holographic"
        if (Test-Path $Holo) { Set-ItemProperty $Holo -Name FirstRunSucceeded -Value 0 }
        Write-Host "Disabling Wi-Fi Sense..."
        $WifiSense1 = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting"
        $WifiSense2 = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots"
        $WifiSense3 = "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config"
        if (-not (Test-Path $WifiSense1)) { New-Item $WifiSense1 -Force | Out-Null }
        Set-ItemProperty $WifiSense1 -Name Value -Value 0
        if (-not (Test-Path $WifiSense2)) { New-Item $WifiSense2 -Force | Out-Null }
        Set-ItemProperty $WifiSense2 -Name Value -Value 0
        Set-ItemProperty $WifiSense3 -Name AutoConnectAllowedOEM -Value 0
        Write-Host "Disabling live tiles..."
        $Live = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"
        if (-not (Test-Path $Live)) { New-Item $Live -Force | Out-Null }
        Set-ItemProperty $Live -Name NoTileApplicationNotification -Value 1
        Write-Host "Turning off Data Collection..."
        $DataCollection1 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
        $DataCollection2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
        $DataCollection3 = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
        if (Test-Path $DataCollection1) { Set-ItemProperty $DataCollection1 -Name AllowTelemetry -Value 0 }
        if (Test-Path $DataCollection2) { Set-ItemProperty $DataCollection2 -Name AllowTelemetry -Value 0 }
        if (Test-Path $DataCollection3) { Set-ItemProperty $DataCollection3 -Name AllowTelemetry -Value 0 }
        Write-Host "Disabling Location Tracking..."
        $SensorState = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"
        $LocationConfig = "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration"
        if (-not (Test-Path $SensorState)) { New-Item $SensorState -Force | Out-Null }
        Set-ItemProperty $SensorState -Name SensorPermissionState -Value 0
        if (-not (Test-Path $LocationConfig)) { New-Item $LocationConfig -Force | Out-Null }
        Set-ItemProperty $LocationConfig -Name Status -Value 0
        Write-Host "Disabling People icon on Taskbar..."
        $People = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People'
        if (Test-Path $People) { Set-ItemProperty $People -Name PeopleBand -Value 0 }
        Write-Host "Disabling scheduled tasks..."
        Get-ScheduledTask -TaskName XblGameSaveTaskLogon | Disable-ScheduledTask -ErrorAction SilentlyContinue
        Get-ScheduledTask -TaskName XblGameSaveTask | Disable-ScheduledTask -ErrorAction SilentlyContinue
        Get-ScheduledTask -TaskName Consolidator | Disable-ScheduledTask -ErrorAction SilentlyContinue
        Get-ScheduledTask -TaskName UsbCeip | Disable-ScheduledTask -ErrorAction SilentlyContinue
        Get-ScheduledTask -TaskName DmClient | Disable-ScheduledTask -ErrorAction SilentlyContinue
        Get-ScheduledTask -TaskName DmClientOnScenarioDownload | Disable-ScheduledTask -ErrorAction SilentlyContinue
        Write-Host "Disabling Diagnostics Tracking Service..."
        DisableDiagTrack
        Write-Host "Removing CloudStore registry key..."
        $CloudStore = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore"
        if (Test-Path $CloudStore) {
            Stop-Process -Name Explorer -Force -ErrorAction SilentlyContinue
            Remove-Item $CloudStore -Recurse -Force -ErrorAction SilentlyContinue
            Start-Process Explorer -Wait
        }
    }

    function DisableCortana {
        Write-Host "Disabling Cortana..."
        $Cortana1 = "HKCU:\SOFTWARE\Microsoft\Personalization\Settings"
        $Cortana2 = "HKCU:\SOFTWARE\Microsoft\InputPersonalization"
        $Cortana3 = "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore"
        if (-not (Test-Path $Cortana1)) { New-Item $Cortana1 -Force | Out-Null }
        Set-ItemProperty $Cortana1 -Name AcceptedPrivacyPolicy -Value 0
        if (-not (Test-Path $Cortana2)) { New-Item $Cortana2 -Force | Out-Null }
        Set-ItemProperty $Cortana2 -Name RestrictImplicitTextCollection -Value 1
        Set-ItemProperty $Cortana2 -Name RestrictImplicitInkCollection -Value 1
        if (-not (Test-Path $Cortana3)) { New-Item $Cortana3 -Force | Out-Null }
        Set-ItemProperty $Cortana3 -Name HarvestContacts -Value 0
    }

    function EnableCortana {
        Write-Host "Re-enabling Cortana..."
        $Cortana1 = "HKCU:\SOFTWARE\Microsoft\Personalization\Settings"
        $Cortana2 = "HKCU:\SOFTWARE\Microsoft\InputPersonalization"
        $Cortana3 = "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore"
        if (-not (Test-Path $Cortana1)) { New-Item $Cortana1 -Force | Out-Null }
        Set-ItemProperty $Cortana1 -Name AcceptedPrivacyPolicy -Value 1
        if (-not (Test-Path $Cortana2)) { New-Item $Cortana2 -Force | Out-Null }
        Set-ItemProperty $Cortana2 -Name RestrictImplicitTextCollection -Value 0
        Set-ItemProperty $Cortana2 -Name RestrictImplicitInkCollection -Value 0
        if (-not (Test-Path $Cortana3)) { New-Item $Cortana3 -Force | Out-Null }
        Set-ItemProperty $Cortana3 -Name HarvestContacts -Value 1
    }

    function Stop-EdgePDF {
        Write-Output "Stopping Edge from taking over as default PDF viewer..."
        $NoPDF = "HKCR:\.pdf"
        $NoProgids = "HKCR:\.pdf\OpenWithProgids"
        $NoWithList = "HKCR:\.pdf\OpenWithList"
        if (-not (Get-ItemProperty -Path $NoPDF -Name NoOpenWith -ErrorAction SilentlyContinue)) {
            New-ItemProperty -Path $NoPDF -Name NoOpenWith -Value "" -Force | Out-Null
        }
        if (-not (Get-ItemProperty -Path $NoPDF -Name NoStaticDefaultVerb -ErrorAction SilentlyContinue)) {
            New-ItemProperty -Path $NoPDF -Name NoStaticDefaultVerb -Value "" -Force | Out-Null
        }
        if (-not (Get-ItemProperty -Path $NoProgids -Name NoOpenWith -ErrorAction SilentlyContinue)) {
            New-ItemProperty -Path $NoProgids -Name NoOpenWith -Value "" -Force | Out-Null
        }
        if (-not (Get-ItemProperty -Path $NoProgids -Name NoStaticDefaultVerb -ErrorAction SilentlyContinue)) {
            New-ItemProperty -Path $NoProgids -Name NoStaticDefaultVerb -Value "" -Force | Out-Null
        }
        if (-not (Get-ItemProperty -Path $NoWithList -Name NoOpenWith -ErrorAction SilentlyContinue)) {
            New-ItemProperty -Path $NoWithList -Name NoOpenWith -Value "" -Force | Out-Null
        }
        if (-not (Get-ItemProperty -Path $NoWithList -Name NoStaticDefaultVerb -ErrorAction SilentlyContinue)) {
            New-ItemProperty -Path $NoWithList -Name NoStaticDefaultVerb -Value "" -Force | Out-Null
        }
        $EdgeKey = "HKCR:\AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723_"
        if (Test-Path $EdgeKey) {
            Set-ItemProperty -Path $EdgeKey -Name "(default)" -Value "AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723_"
        }
    }

    function Enable-EdgePDF {
        Write-Output "Restoring Edge PDF defaults..."
        $NoPDF = "HKCR:\.pdf"
        $NoProgids = "HKCR:\.pdf\OpenWithProgids"
        $NoWithList = "HKCR:\.pdf\OpenWithList"
        if (Get-ItemProperty -Path $NoPDF -Name NoOpenWith -ErrorAction SilentlyContinue) {
            Remove-ItemProperty -Path $NoPDF -Name NoOpenWith -Force
        }
        if (Get-ItemProperty -Path $NoPDF -Name NoStaticDefaultVerb -ErrorAction SilentlyContinue) {
            Remove-ItemProperty -Path $NoPDF -Name NoStaticDefaultVerb -Force
        }
        if (Get-ItemProperty -Path $NoProgids -Name NoOpenWith -ErrorAction SilentlyContinue) {
            Remove-ItemProperty -Path $NoProgids -Name NoOpenWith -Force
        }
        if (Get-ItemProperty -Path $NoProgids -Name NoStaticDefaultVerb -ErrorAction SilentlyContinue) {
            Remove-ItemProperty -Path $NoProgids -Name NoStaticDefaultVerb -Force
        }
        if (Get-ItemProperty -Path $NoWithList -Name NoOpenWith -ErrorAction SilentlyContinue) {
            Remove-ItemProperty -Path $NoWithList -Name NoOpenWith -Force
        }
        if (Get-ItemProperty -Path $NoWithList -Name NoStaticDefaultVerb -ErrorAction SilentlyContinue) {
            Remove-ItemProperty -Path $NoWithList -Name NoStaticDefaultVerb -Force
        }
        $EdgeKey = "HKCR:\AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723_"
        if (Test-Path $EdgeKey) {
            Set-ItemProperty -Path $EdgeKey -Name "(default)" -Value "AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723"
        }
    }

    function FixWhitelistedApps {
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

    function UninstallOneDrive {
        Write-Host "Checking OneDrive folder for files..."
        Start-Sleep 1
        if (Test-Path "$env:USERPROFILE\OneDrive\*") {
            Write-Host "Files found in OneDrive. Checking for desktop backup folder..."
            Start-Sleep 1
            $backupPath = "$env:USERPROFILE\Desktop\OneDriveBackupFiles"
            if (-not (Test-Path $backupPath)) {
                Write-Host "Creating backup folder 'OneDriveBackupFiles'..."
                New-Item -Path "$env:USERPROFILE\Desktop" -Name "OneDriveBackupFiles" -ItemType Directory -Force | Out-Null
            } else {
                Write-Host "Backup folder already exists."
            }
            Start-Sleep 1
            Move-Item -Path "$env:USERPROFILE\OneDrive\*" -Destination $backupPath -Force
            Write-Host "Files moved to backup folder."
            Start-Sleep 1
            Write-Host "Proceeding with OneDrive removal..."
            Start-Sleep 1
        }
        else {
            Write-Host "No files found in OneDrive. Enabling Group Policy to disable OneDrive file storage..."
            $OneDriveKey = 'HKLM:\Software\Policies\Microsoft\Windows\OneDrive'
            if (-not (Test-Path $OneDriveKey)) { New-Item $OneDriveKey -Force | Out-Null }
            Set-ItemProperty $OneDriveKey -Name OneDrive -Value DisableFileSyncNGSC
        }
        Write-Host "Uninstalling OneDrive..."
        $OneDriveSetup = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
        if (-not (Test-Path $OneDriveSetup)) {
            $OneDriveSetup = "$env:SYSTEMROOT\System32\OneDriveSetup.exe"
        }
        Stop-Process -Name "OneDrive*" -Force -ErrorAction SilentlyContinue
        Start-Sleep 2
        Start-Process $OneDriveSetup -ArgumentList "/uninstall" -NoNewWindow -Wait
        Start-Sleep 2
        Write-Host "Stopping Explorer..."
        Start-Sleep 1
        taskkill.exe /F /IM explorer.exe
        Start-Sleep 3
        Write-Host "Removing leftover OneDrive files..."
        Remove-Item "$env:USERPROFILE\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
        Remove-Item "$env:LOCALAPPDATA\Microsoft\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
        Remove-Item "$env:PROGRAMDATA\Microsoft OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
        if (Test-Path "$env:SYSTEMDRIVE\OneDriveTemp") {
            Remove-Item "$env:SYSTEMDRIVE\OneDriveTemp" -Force -Recurse -ErrorAction SilentlyContinue
        }
        Write-Host "Removing OneDrive integration from Explorer..."
        $ExplorerReg1 = "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
        $ExplorerReg2 = "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
        if (-not (Test-Path $ExplorerReg1)) { New-Item $ExplorerReg1 -Force | Out-Null }
        Set-ItemProperty $ExplorerReg1 -Name System.IsPinnedToNameSpaceTree -Value 0
        if (-not (Test-Path $ExplorerReg2)) { New-Item $ExplorerReg2 -Force | Out-Null }
        Set-ItemProperty $ExplorerReg2 -Name System.IsPinnedToNameSpaceTree -Value 0
        Write-Host "Restarting Explorer..."
        Start-Process explorer.exe -NoNewWindow
        Write-Host "OneDrive successfully uninstalled!"
        Remove-Item Env:OneDrive -ErrorAction SilentlyContinue
    }

    function UnpinStart {
        # Create a blank Start layout XML to unpin tiles.
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
        if (Test-Path $layoutFile) { Remove-Item $layoutFile -Force }
        $START_MENU_LAYOUT | Out-File $layoutFile -Encoding ASCII
        $regAliases = @("HKLM", "HKCU")
        foreach ($regAlias in $regAliases) {
            $basePath = "$regAlias:\SOFTWARE\Policies\Microsoft\Windows"
            $keyPath = "$basePath\Explorer"
            if (-not (Test-Path $keyPath)) { New-Item -Path $basePath -Name "Explorer" -Force | Out-Null }
            Set-ItemProperty -Path $keyPath -Name "LockedStartLayout" -Value 1
            Set-ItemProperty -Path $keyPath -Name "StartLayoutFile" -Value $layoutFile
        }
        Stop-Process -Name explorer -Force
        Start-Sleep -Seconds 5
        $wshell = New-Object -ComObject wscript.shell
        $wshell.SendKeys('^{ESCAPE}')
        Start-Sleep -Seconds 5
        foreach ($regAlias in $regAliases) {
            $basePath = "$regAlias:\SOFTWARE\Policies\Microsoft\Windows"
            $keyPath = "$basePath\Explorer"
            Set-ItemProperty -Path $keyPath -Name "LockedStartLayout" -Value 0
        }
        Stop-Process -Name explorer -Force
        Remove-Item $layoutFile -Force
    }

    function Remove3dObjects {
        Write-Host "Removing 3D Objects from 'My Computer' submenu..."
        $Objects32 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
        $Objects64 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
        if (Test-Path $Objects32) { Remove-Item $Objects32 -Recurse -Force }
        if (Test-Path $Objects64) { Remove-Item $Objects64 -Recurse -Force }
    }

    function Restore3dObjects {
        Write-Host "Restoring 3D Objects to 'My Computer' submenu..."
        $Objects32 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
        $Objects64 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
        if (-not (Test-Path $Objects32)) { New-Item $Objects32 -Force | Out-Null }
        if (-not (Test-Path $Objects64)) { New-Item $Objects64 -Force | Out-Null }
    }

    # Missing functions from GitHub issues
    function DisableDiagTrack {
        Write-Output "Disabling Diagnostics Tracking Service (DiagTrack)..."
        Stop-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
        Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
    }

    function DisableWAPPush {
        Write-Output "Disabling WAP Push Service (dmwappushservice)..."
        Stop-Service -Name "dmwappushservice" -ErrorAction SilentlyContinue
        Set-Service -Name "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue
    }

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

    # Revert changes function
    function Revert-Changes {
        Write-Output "Reinstalling all removed bloatware..."
        Get-AppxPackage -AllUsers | ForEach-Object {
            Add-AppxPackage -Verbose -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"
        }
        Write-Output "Re-enabling advertisement information..."
        $Advertising = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
        if (Test-Path $Advertising) { Set-ItemProperty $Advertising -Name Enabled -Value 1 }
        Write-Output "Re-enabling Cortana in Windows Search..."
        $Search = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        if (Test-Path $Search) { Set-ItemProperty $Search -Name AllowCortana -Value 1 }
        Write-Output "Re-enabling Windows Feedback Experience..."
        $Period = "HKCU:\Software\Microsoft\Siuf\Rules"
        if (-not (Test-Path $Period)) { New-Item $Period -Force | Out-Null }
        Set-ItemProperty $Period -Name PeriodInNanoSeconds -Value 1
        Write-Output "Allowing bloatware apps to return..."
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
        if (-not (Test-Path $registryPath)) { New-Item $registryPath -Force | Out-Null }
        Set-ItemProperty $registryPath -Name DisableWindowsConsumerFeatures -Value 0
        Write-Output "Restoring Mixed Reality Portal value..."
        $Holo = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Holographic"
        if (Test-Path $Holo) { Set-ItemProperty $Holo -Name FirstRunSucceeded -Value 1 }
        Write-Output "Enabling live tiles..."
        $Live = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"
        if (-not (Test-Path $Live)) { New-Item $Live -Force | Out-Null }
        Set-ItemProperty $Live -Name NoTileApplicationNotification -Value 0
        Write-Output "Re-enabling data collection..."
        $DataCollection = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
        if (-not (Test-Path $DataCollection)) { New-Item $DataCollection -Force | Out-Null }
        Set-ItemProperty $DataCollection -Name AllowTelemetry -Value 1
        Write-Output "Enabling People icon on Taskbar..."
        $People = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People"
        if (-not (Test-Path $People)) { New-Item $People -Force | Out-Null }
        Set-ItemProperty $People -Name PeopleBand -Value 1
        Write-Output "Enabling Start Menu suggestions..."
        $Suggestions = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        if (-not (Test-Path $Suggestions)) { New-Item $Suggestions -Force | Out-Null }
        Set-ItemProperty $Suggestions -Name SystemPaneSuggestionsEnabled -Value 1
        Write-Output "Enabling scheduled tasks..."
        Get-ScheduledTask -TaskName XblGameSaveTaskLogon | Enable-ScheduledTask -ErrorAction SilentlyContinue
        Get-ScheduledTask -TaskName XblGameSaveTask | Enable-ScheduledTask -ErrorAction SilentlyContinue
        Get-ScheduledTask -TaskName Consolidator | Enable-ScheduledTask -ErrorAction SilentlyContinue
        Get-ScheduledTask -TaskName UsbCeip | Enable-ScheduledTask -ErrorAction SilentlyContinue
        Get-ScheduledTask -TaskName DmClient | Enable-ScheduledTask -ErrorAction SilentlyContinue
        Get-ScheduledTask -TaskName DmClientOnScenarioDownload | Enable-ScheduledTask -ErrorAction SilentlyContinue
        Write-Output "Re-enabling and starting WAP Push Service..."
        Set-Service -Name "dmwappushservice" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name "dmwappushservice" -ErrorAction SilentlyContinue
        Write-Output "Re-enabling and starting Diagnostics Tracking Service..."
        Set-Service -Name "DiagTrack" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
        Write-Output "Restoring 3D Objects..."
        Restore3dObjects
    }

    # Interactive prompts
    $Button = [Windows.MessageBoxButton]::YesNoCancel
    $ErrorIco = [Windows.MessageBoxImage]::Error
    $Warn = [Windows.MessageBoxImage]::Warning
    $Ask = @"
The following will allow you to either Debloat Windows 10 or revert changes made by this script.

Select "Yes" to Debloat Windows 10.
Select "No" to revert changes.
Select "Cancel" to stop the script.
"@
    $EverythingorSpecific = "Would you like to remove everything that was preinstalled on your Windows machine? Select Yes to remove everything, or No to use a custom blacklist."
    $EdgePdf = "Do you want to stop Edge from taking over as the default PDF viewer?"
    $EdgePdf2 = "Do you want to revert changes that disabled Edge as the default PDF viewer?"
    $Reboot = "It is recommended to reboot for all changes to take effect. Restart now?"
    $OneDriveDelete = "Do you want to uninstall OneDrive?"
    $Unpin = "Do you want to unpin all items from the Start menu?"
    $InstallNET = "Do you want to install .NET 3.5?"

    $Prompt1 = [Windows.MessageBox]::Show($Ask, "Debloat or Revert", $Button, $ErrorIco)
    switch ($Prompt1) {
        'Yes' {
            $Prompt2 = [Windows.MessageBox]::Show($EverythingorSpecific, "Everything or Specific", $Button, $Warn)
            switch ($Prompt2) {
                'Yes' {
                    Write-Host "Creating PSDrive HKCR for registry modifications..."
                    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
                    Start-Sleep 1
                    Write-Host "Uninstalling all bloatware..."
                    DebloatAll
                    Write-Host "Bloatware removed."
                    Start-Sleep 1
                    Write-Host "Removing registry keys..."
                    Remove-Keys
                    Write-Host "Registry keys removed."
                    Start-Sleep 1
                    Write-Host "Reinstalling missing whitelisted apps..."
                    FixWhitelistedApps
                    Start-Sleep 1
                    Write-Host "Applying privacy settings..."
                    Protect-Privacy
                    Start-Sleep 1
                    DisableCortana
                    Write-Host "Cortana disabled."
                    Start-Sleep 1
                    Write-Host "Disabling Diagnostics Tracking Service..."
                    DisableDiagTrack
                    Write-Host "DiagTrack disabled."
                    Start-Sleep 1
                    Write-Host "Disabling WAP Push Service..."
                    DisableWAPPush
                    Start-Sleep 1
                    Write-Host "Ensuring dmwappushservice is running..."
                    CheckDMWService
                    Start-Sleep 1
                    Write-Host "Removing 3D Objects..."
                    Remove3dObjects
                    Start-Sleep 1
                }
                'No' {
                    Write-Host "Creating PSDrive HKCR for registry modifications..."
                    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
                    Start-Sleep 1
                    Write-Host "Uninstalling bloatware via blacklist..."
                    DebloatBlacklist
                    Write-Host "Bloatware removed."
                    Start-Sleep 1
                    Write-Host "Removing registry keys..."
                    Remove-Keys
                    Write-Host "Registry keys removed."
                    Start-Sleep 1
                    Write-Host "Reinstalling missing whitelisted apps..."
                    FixWhitelistedApps
                    Start-Sleep 1
                    Write-Host "Applying privacy settings..."
                    Protect-Privacy
                    Start-Sleep 1
                    DisableCortana
                    Write-Host "Cortana disabled."
                    Start-Sleep 1
                    Write-Host "Disabling Diagnostics Tracking Service..."
                    DisableDiagTrack
                    Write-Host "DiagTrack disabled."
                    Start-Sleep 1
                    Write-Host "Disabling WAP Push Service..."
                    DisableWAPPush
                    Start-Sleep 1
                    Write-Host "Ensuring dmwappushservice is running..."
                    CheckDMWService
                    Start-Sleep 1
                }
            }
            $Prompt3 = [Windows.MessageBox]::Show($EdgePdf, "Edge PDF", $Button, $Warn)
            switch ($Prompt3) {
                'Yes' {
                    Stop-EdgePDF
                    Write-Host "Edge PDF takeover disabled."
                }
                default { Write-Host "Edge PDF settings unchanged." }
            }
            $Prompt4 = [Windows.MessageBox]::Show($OneDriveDelete, "Delete OneDrive", $Button, $ErrorIco)
            switch ($Prompt4) {
                'Yes' {
                    UninstallOneDrive
                    Write-Host "OneDrive removed."
                }
                default { Write-Host "OneDrive removal skipped." }
            }
            $Prompt5 = [Windows.MessageBox]::Show($Unpin, "Unpin Start Items", $Button, $ErrorIco)
            switch ($Prompt5) {
                'Yes' {
                    UnpinStart
                    Write-Host "Start menu items unpinned."
                }
                default { Write-Host "Start menu items retained." }
            }
            $Prompt6 = [Windows.MessageBox]::Show($InstallNET, "Install .NET", $Button, $Warn)
            switch ($Prompt6) {
                'Yes' {
                    Write-Host "Installing .NET 3.5..."
                    DISM /Online /Enable-Feature /FeatureName:NetFx3 /All
                    Write-Host ".NET 3.5 installed."
                }
                default { Write-Host ".NET installation skipped." }
            }
            $Prompt0 = [Windows.MessageBox]::Show($Reboot, "Reboot", $Button, $Warn)
            switch ($Prompt0) {
                'Yes' {
                    Write-Host "Removing HKCR drive..."
                    Remove-PSDrive HKCR
                    Start-Sleep 1
                    Write-Host "Restarting computer..."
                    Stop-Transcript
                    Start-Sleep 2
                    Restart-Computer
                }
                default {
                    Write-Host "Removing HKCR drive..."
                    Remove-PSDrive HKCR
                    Start-Sleep 1
                    Write-Host "Script finished."
                    Stop-Transcript
                    Start-Sleep 2
                    Exit
                }
            }
        }
        'No' {
            Write-Host "Reverting changes..."
            Write-Host "Creating PSDrive HKCR for registry modifications..."
            New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
            Revert-Changes
            $Prompt6 = [Windows.MessageBox]::Show($EdgePdf2, "Revert Edge PDF", $Button, $ErrorIco)
            switch ($Prompt6) {
                'Yes' {
                    Enable-EdgePDF
                    Write-Host "Edge PDF settings reverted."
                }
                default { Write-Host "Edge PDF settings unchanged." }
            }
            $Prompt0 = [Windows.MessageBox]::Show($Reboot, "Reboot", $Button, $Warn)
            switch ($Prompt0) {
                'Yes' {
                    Write-Host "Removing HKCR drive..."
                    Remove-PSDrive HKCR
                    Start-Sleep 1
                    Write-Host "Restarting computer..."
                    Stop-Transcript
                    Start-Sleep 2
                    Restart-Computer
                }
                default {
                    Write-Host "Removing HKCR drive..."
                    Remove-PSDrive HKCR
                    Start-Sleep 1
                    Write-Host "Script finished."
                    Stop-Transcript
                    Start-Sleep 2
                    Exit
                }
            }
        }
        default { Write-Host "Operation cancelled."; Exit }
    }
})
#endregion

[void]$Form.ShowDialog()
