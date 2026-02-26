[string]$DistroName = "WSL-ROS2"
[string]$TarBallName = "wsl-ros2-v2526.02.tar"
[string]$TarBallPath = "$env:SystemDrive\$DistroName\$TarBallName"
[string]$DistroTargetPath = "$env:LOCALAPPDATA\$DistroName"
[string]$WinTermSettingsTargetPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
[string]$WinTermSettingsTargetFilePath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
[string]$WinTermSettingsBackup = "$env:LOCALAPPDATA\temp_terminal_settings.json"

If (-not(Get-Process | Where-Object {$_.Name -eq "vcxsrv"}))
{
    Start-Process -FilePath "$env:SystemDrive\ProgramData\Microsoft\AppV\Client\Integration\8FCACB30-2BA0-4AFE-9816-259ED56E59EB\Root\VFS\ProgramFilesX64\VcXsrv\xlaunch.exe" -ArgumentList "-run $env:SystemDrive\$DistroName\wsl_ros_config.xlaunch"
}

$console_encoding = ([console]::OutputEncoding)
[console]::OutputEncoding = New-Object System.Text.UnicodeEncoding
Clear
$Distros = wsl --list
[console]::OutputEncoding = $console_encoding

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

Write-Host
If ($Distros | Where-Object {$_ -eq $DistroName -or $_ -eq ($DistroName + " (Default)")})
{
    Write-Host "You already have a $DistroName distribution installed."
    Write-Host
    $Reply = Read-Host -Prompt "Would you like to carry on using it? (Y/N)"
    Write-Host
    If ($Reply -eq "Y" -or $Reply -eq "YES")
    {
        Start-Process -FilePath "shell:AppsFolder\Microsoft.WindowsTerminal_8wekyb3d8bbwe!App"
        Exit  
    }
    $Reply = Read-Host -Prompt "Is it OK to delete the current distribution and install a fresh copy? (Y/N)"
    If ($Reply -eq "Y" -or $Reply -eq "YES")
    {
        wsl --unregister $DistroName
		Clear
    }
    Else
    {
        Write-Host "Exiting..."
        Start-Sleep -Seconds 3
        Exit
    }
}

# check if the windows terminal is currently running. If it is, close it.
$wtProcess = Get-Process -Name "WindowsTerminal" -ErrorAction SilentlyContinue
if ($wtProcess) {
    $Reply = Read-Host -Prompt "The Windows Terminal needs to be closed. Please save any work before continuing. OK to proceed? (Y/N)"
    If ($Reply -eq "Y" -or $Reply -eq "YES")
    {
        $wtProcess | Stop-Process -Force
        Start-Sleep -Seconds 2		
    }
    Else
    {
        Write-Host "Unable to proceed, please close the Windows Terminal and try again."
        Start-Sleep -Seconds 3
        Exit
    }   
}

# Delete the existing Windows Terminal settings file if it exists
# (Forcing a default one to be created)
If (Test-Path $WinTermSettingsTargetFilePath)
{
    Write-Host "Backing up existing Windows Terminal settings..."
    Copy-Item -Path $WinTermSettingsTargetFilePath -Destination $WinTermSettingsBackup -Force
    Remove-Item -Path $WinTermSettingsTargetFilePath -Force
    Write-Host "Existing Windows Terminal settings backed up and removed."
    Start-Sleep -Seconds 2
    $settingsToRestore = $true
} else {
    $settingsToRestore = $false
}

Write-Host "Installing $DistroName from '$TarBallName'. Please wait..."
Write-Host "(This should take no more than 2-3 minutes.)"
Write-Host
wsl --import $DistroName $DistroTargetPath $TarBallPath --version 2

Start-Sleep -Seconds 5

$wtPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
if (Test-Path $wtPath) {
    # found the alias in local app data, so can launch silently (in the background)
    $wtProcess = Start-Process -FilePath $wtPath -WindowStyle Hidden -PassThru
} else {
    # Not ideal, but need to fallback to launching the Windows Terminal from the Start Menu, which means we can't do it silently (but it will be closed automatically a bit later on, at least).
    $wtProcess = Start-Process -FilePath "shell:AppsFolder\Microsoft.WindowsTerminal_8wekyb3d8bbwe!App"
}

$maxRetries = 10
$retryCount = 0
$profileFound = $false

while (-not $profileFound -and $retryCount -lt $maxRetries) {
    if (Test-Path $WinTermSettingsTargetFilePath) {
        $liveSettings = Get-Content $WinTermSettingsTargetFilePath -Raw | ConvertFrom-Json
        
        $correctProfile = $liveSettings.profiles.list | Where-Object { 
            $_.name -eq $DistroName -and $_.source -ne "Windows.Terminal.Wsl" -and $_.source -ne $null
        }

        if ($correctProfile) {
            $profileFound = $true
            $wslguid = $correctProfile.guid
            Write-Host "Found the right profile for $DistroName. GUID = $wslguid"
        } else {
            Write-Host "Waiting for Windows Terminal to register $DistroName... ($($retryCount + 1)/$maxRetries)"
        }
    } else {
        Write-Host "Waiting for Windows Terminal settings file to be created...  ($($retryCount + 1)/$maxRetries)"
    }
    Start-Sleep -Seconds 2
    $retryCount++
}

Get-Process -Name "WindowsTerminal" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 5

if (-not $profileFound) {
    Write-Host "Failed to find a valid profile for $DistroName after $maxRetries attempts."
    Write-Host "launching Windows Terminal with no custom settings applied."
    Start-Process -FilePath "shell:AppsFolder\Microsoft.WindowsTerminal_8wekyb3d8bbwe!App" -ArgumentList "wsl ~ -d $DistroName"
    Read-Host -Prompt "Press Enter to exit..."
    Exit
} elseif ($settingsToRestore) {
    # a profile existed AND and original settings file was found.
    # we need to restore the original settings file and 
    # inject the newly obtained WSL-ROS2 settings:
    $originalSettings = Get-Content $WinTermSettingsBackup -Raw | ConvertFrom-Json
    # Find the number of profiles currently in the list:
    $profCount = $originalSettings.profiles.list.Count
    # Then, check if a WSL-ROS2 profile is one of them:
    $originalSettings.profiles.list = $originalSettings.profiles.list | Where-Object { 
        -not ($_.name -eq $DistroName)
    }
    if ($originalSettings.profiles.list.Count -lt $profCount) {
        Write-Host "Count now: $($originalSettings.profiles.list.Count), was $profCount."
        Write-Host "A profile for $DistroName already existed in the original settings and has now been removed."    
    }
    # add the correct WSL-ROS2 profile:
    $originalSettings.profiles.list += $correctProfile
    Write-Host "The profile for $DistroName has been added to the original settings (which will be restored)."
    $finalSettings = $originalSettings
} else {
    # a profile existed, but NO original settings file was found (so use the auto-generated one).
    Write-Host "No original Windows Terminal settings found to restore, but a new valid profile for $DistroName was created."
    $finalSettings = $liveSettings
}

# Set the WSL-ROS2 profile as the default:
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

# launch the windows terminal:
Start-Process -FilePath "shell:AppsFolder\Microsoft.WindowsTerminal_8wekyb3d8bbwe!App"
Read-Host -Prompt "Press Enter to exit..."
