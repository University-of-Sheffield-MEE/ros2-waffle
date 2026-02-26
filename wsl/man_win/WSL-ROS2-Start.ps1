[string]$DistroName = "WSL-ROS2"
[string]$TarBallName = "wsl-ros2-v2526.02.tar"
[string]$TarBallPath = "$env:SystemDrive\$DistroName\$TarBallName"
[string]$DistroTargetPath = "$env:LOCALAPPDATA\$DistroName"
[string]$WinTermSettingsTargetPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
[string]$WinTermSettingsTargetFilePath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
[string]$WinTermSettingsBackup = "$env:LOCALAPPDATA\temp_terminal_settings.json"
$LogFile = "$env:LOCALAPPDATA\WSL-ROS2-Start-ps1.log"

$ubuntuScheme = [PSCustomObject]@{
        name                = "tuos-ubuntu"
        background          = "#300A24"
        black               = "#2E3436"
        blue                = "#3465A4"
        brightBlack         = "#555753"
        brightBlue          = "#729FCF"
        brightCyan          = "#34E2E2"
        brightGreen         = "#8AE234"
        brightPurple        = "#AD7FA8"
        brightRed           = "#EF2929"
        brightWhite         = "#EEEEEC"
        brightYellow        = "#FCE94F"
        cursorColor         = "#FFFFFF"
        cyan                = "#06989A"
        foreground          = "#EEEEEC"
        green               = "#4E9A06"
        purple              = "#75507B"
        red                 = "#CC0000"
        selectionBackground = "#FFFFFF"
        white               = "#D3D7CF"
        yellow              = "#C4A000"
    }

function Write-Log {
    param([string]$Message)
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $StampedMessage = "[$TimeStamp] $Message"
    
    $StampedMessage | Out-File -FilePath $LogFile -Append
}

Write-Log "==============================="
Write-Log "Starting WSL-ROS2-Start.ps1..."
Write-Log "==============================="

If (-not(Get-Process | Where-Object {$_.Name -eq "vcxsrv"}))
{
    Write-Log "VcXsrv is not running. Starting VcXsrv..."
    try {
        Start-Process -FilePath "$env:SystemDrive\ProgramData\Microsoft\AppV\Client\Integration\8FCACB30-2BA0-4AFE-9816-259ED56E59EB\Root\VFS\ProgramFilesX64\VcXsrv\xlaunch.exe" -ArgumentList "-run $env:SystemDrive\$DistroName\wsl_ros_config.xlaunch"
    } catch {
        Write-Log "Couldn't start VcXsrv: $($_.Exception.Message)"
    }
}

Write-Log "Checking the WSL distro list."
$console_encoding = ([console]::OutputEncoding)
[console]::OutputEncoding = New-Object System.Text.UnicodeEncoding
Clear
$Distros = wsl --list
[console]::OutputEncoding = $console_encoding

Write-Host
If ($Distros | Where-Object {$_ -eq $DistroName -or $_ -eq ($DistroName + " (Default)")})
{
    Write-Log "$DistroName distro is already installed."
    Write-Host "You already have a $DistroName distribution installed."
    Write-Host
    $Reply = Read-Host -Prompt "Would you like to carry on using it? (Y/N)"
    Write-Host
    If ($Reply -eq "Y" -or $Reply -eq "YES")
    {
        Write-Log "Continue using the existing $DistroName distribution (and exit)."
        Start-Process -FilePath "shell:AppsFolder\Microsoft.WindowsTerminal_8wekyb3d8bbwe!App"
        Exit  
    }
    $Reply = Read-Host -Prompt "Is it OK to delete the current distribution and install a fresh copy? (Y/N)"
    If ($Reply -eq "Y" -or $Reply -eq "YES")
    {
        Write-Log "Unregistering existing $DistroName distribution (to start from fresh)."
        wsl --unregister $DistroName
		Clear
    }
    Else
    {
        Write-Log "Don't install a fresh $DistroName distro. Exiting."
        Write-Host "Exiting..."
        Start-Sleep -Seconds 3
        Exit
    }
}

Write-Log "Check if the Windows Terminal is currently running. If it is, close it."
$wtProcess = Get-Process -Name "WindowsTerminal" -ErrorAction SilentlyContinue
if ($wtProcess) {
    $Reply = Read-Host -Prompt "The Windows Terminal needs to be closed. Please save any work before continuing. OK to proceed? (Y/N)"
    Write-Log "Windows Terminal is currently running."
    If ($Reply -eq "Y" -or $Reply -eq "YES")
    {
        Write-Log "Closing Windows Terminal to proceed with the installation."
        $wtProcess | Stop-Process -Force
        Start-Sleep -Seconds 2		
    }
    Else
    {
        Write-Log "User chose not to close Windows Terminal. Exiting"
        Write-Host "Unable to proceed, please close the Windows Terminal and try again."
        Start-Sleep -Seconds 3
        Exit
    }   
}

Write-Log "Delete the existing Windows Terminal settings file if it exists (triggering creation of a default one)."
If (Test-Path $WinTermSettingsTargetFilePath)
{
    Write-Log "A settings.json file existed. Backing this up and then deleting the original."
    Copy-Item -Path $WinTermSettingsTargetFilePath -Destination $WinTermSettingsBackup -Force
    Remove-Item -Path $WinTermSettingsTargetFilePath -Force
    Write-Log "Existing Windows Terminal settings backed up and removed."
    $settingsToRestore = $true
} else {
    Write-Log "No existing settings.json file found, so no need to back up or delete anything."
    $settingsToRestore = $false
}

Write-Host "Installing $DistroName from '$TarBallName'. Please wait..."
Write-Host "(This should take no more than 2-3 minutes.)"
Write-Host
wsl --import $DistroName $DistroTargetPath $TarBallPath --version 2

Start-Sleep -Seconds 2

Write-Log "Attempting to launch Windows Terminal to trigger the creation of a new settings file."
$wtPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
if (Test-Path $wtPath) {
    Write-Log "Found the Windows Terminal alias in local app data, so can launch silently (in the background)."
    $wtProcess = Start-Process -FilePath $wtPath -WindowStyle Hidden -PassThru
} else {
    Write-Log "Windows Terminal alias not found in local app data. Launching from Start Menu. Cannot be done silently, but will be closed automatically."
    $wtProcess = Start-Process -FilePath "shell:AppsFolder\Microsoft.WindowsTerminal_8wekyb3d8bbwe!App"
}

$maxRetries = 10
$retryCount = 0
$profileFound = $false
Write-Log "Waiting for Windows Terminal to create the settings file and register the new $DistroName profile (up to $maxRetries attempts with 2 seconds between each attempt)."
while (-not $profileFound -and $retryCount -lt $maxRetries) {
    if (Test-Path $WinTermSettingsTargetFilePath) {
        $liveSettings = Get-Content $WinTermSettingsTargetFilePath -Raw | ConvertFrom-Json
        
        $correctProfile = $liveSettings.profiles.list | Where-Object { 
            $_.name -eq $DistroName -and $_.source -ne "Windows.Terminal.Wsl" -and $_.source -ne $null
        }

        if ($correctProfile) {
            $profileFound = $true
            $wslguid = $correctProfile.guid
            Write-Log "Found the right profile for $DistroName. GUID = $wslguid"
        } else {
            Write-Log "Waiting for Windows Terminal to register $DistroName... ($($retryCount + 1)/$maxRetries)"
        }
    } else {
        Write-Log "Waiting for the Windows Terminal settings file to be created...  ($($retryCount + 1)/$maxRetries)"
    }
    Start-Sleep -Seconds 2
    $retryCount++
}
Write-Log "Finished waiting for Windows Terminal. Profile found: $profileFound. Number of attempts: $retryCount."
Write-Log "Closing Windows Terminal."
Get-Process -Name "WindowsTerminal" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

if (-not $profileFound) {
    Write-Log "Failed to find a valid profile for $DistroName after $maxRetries attempts. Launching Windows Terminal with no custom settings applied, and exiting."
    Start-Process -FilePath "shell:AppsFolder\Microsoft.WindowsTerminal_8wekyb3d8bbwe!App" -ArgumentList "wsl ~ -d $DistroName"
    Exit
} elseif ($settingsToRestore) {
    Write-Log "A profile existed AND an original settings file was found, which will now be restored (with newly obtained $DistroName settings)."
    $originalSettings = Get-Content $WinTermSettingsBackup -Raw | ConvertFrom-Json
    # Find the number of profiles currently in the list:
    $profCount = $originalSettings.profiles.list.Count
    # Then, check if a WSL-ROS2 profile is one of them:
    $originalSettings.profiles.list = $originalSettings.profiles.list | Where-Object { 
        -not ($_.name -eq $DistroName)
    }
    if ($originalSettings.profiles.list.Count -lt $profCount) {
        Write-Log "A profile for $DistroName already existed in the original WT settings file, and has now been removed (num profiles now: $($originalSettings.profiles.list.Count), was $profCount)."
    }
    $originalSettings.profiles.list += $correctProfile
    Write-Log "The profile for $DistroName has been added to the original settings file (which will be restored)."
    $finalSettings = $originalSettings
} else {
    Write-Log "No original Windows Terminal settings found to restore, but a new valid profile for $DistroName was created. Using the auto-generated settings."
    $finalSettings = $liveSettings
}

Write-Log "Setting the WSL-ROS2 profile as the default, and configuring some additional custom settings (e.g. colour scheme etc.)."
$finalSettings.defaultProfile = $wslguid

# add some additional custom WT settings
$finalSettings | Add-Member -MemberType NoteProperty -Name "warning.confirmCloseAllTabs" -Value $false -Force
$finalSettings | Add-Member -MemberType NoteProperty -Name "warning.multiLinePaste" -Value $false -Force
$finalSettings | Add-Member -MemberType NoteProperty -Name "language" -Value "en-US" -Force
# add an ubuntu colour scheme
if ($null -eq $finalSettings.schemes) { 
    $finalSettings | Add-Member -MemberType NoteProperty -Name "schemes" -Value @() 
}
$existingScheme = $finalSettings.schemes | Where-Object { $_.name -eq "tuos-ubuntu" }
    if (-not $existingScheme) {
    $finalSettings.schemes += $ubuntuScheme
}
# apply the colour scheme to the WSL-ROS2 profile:
$correctProfile | Add-Member -MemberType NoteProperty -Name "colorScheme" -Value "tuos-ubuntu" -Force

# save the settings file:
$finalSettings | ConvertTo-Json -Depth 100 | Set-Content $WinTermSettingsTargetFilePath

Write-Log "Settings file saved to $WinTermSettingsTargetFilePath"
Write-Log "Launching Windows Terminal."
Start-Process -FilePath "shell:AppsFolder\Microsoft.WindowsTerminal_8wekyb3d8bbwe!App"
