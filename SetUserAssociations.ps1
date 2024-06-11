# Define the file extensions and associated executable
$fileExtensions = @(".tar", ".gz")
$exePath = "C:\SGS\BlockMessage.exe"
$progIDPrefix = "blockmessagefile"

# Function to remove existing registry keys for a specific user hive
function Remove-UserRegistryKeys {
    param (
        [string]$userHiveRoot,
        [string]$extension
    )
    
    $fileExtKey = Join-Path "$userHiveRoot\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts" $extension

    try {
        Write-Output "Attempting to remove keys at $fileExtKey..."

        if (Test-Path $fileExtKey) {
            Remove-Item -Path $fileExtKey -Recurse -Force -ErrorAction Stop
            Write-Output "Extension key $fileExtKey removed successfully."
        } else {
            Write-Output "Extension key $fileExtKey does not exist."
        }
    } catch {
        Write-Output "ERROR: Failed to remove keys at $fileExtKey. $_"
    }
}

# Function to set registry keys for a specific user hive
function Set-UserRegistryKeys {
    param (
        [string]$userHiveRoot,
        [string]$extension,
        [string]$progID,
        [string]$exePath
    )

    $fileExtKey = Join-Path "$userHiveRoot\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts" $extension

    try {
        Write-Output "Attempting to set keys at $fileExtKey..."

        # Create or access the FileExts key
        if (-not (Test-Path $fileExtKey)) {
            Write-Output "creating $fileExtKey..."
            New-Item -Path $fileExtKey -Force | Out-Null
        }

        # Create or access the OpenWithProgids key
        $openWithProgidsKey = Join-Path $fileExtKey "OpenWithProgids"
        if (-not (Test-Path $openWithProgidsKey)) {
            Write-Output "creating $openWithProgidsKey..."
            New-Item -Path $openWithProgidsKey -Force | Out-Null
        }

        # Set the ProgID value under OpenWithProgids key
        Set-ItemProperty -Path $openWithProgidsKey -Name $progID -Value 0 -ErrorAction Stop

        # Create or access the UserChoice key
        $userChoiceKey = Join-Path $fileExtKey "UserChoice"
        if (-not (Test-Path $userChoiceKey)) {
            Write-Output "creating $userChoiceKey..."
            New-Item -Path $userChoiceKey -Force | Out-Null
        }

        # Set the ProgId and Hash values for UserChoice key
        Set-ItemProperty -Path $userChoiceKey -Name "ProgId" -Value $progID -ErrorAction Stop
        Set-ItemProperty -Path $userChoiceKey -Name "Hash" -Value ([byte[]]@(0)) -ErrorAction Stop

        Write-Output "Keys set successfully at $fileExtKey."
    } catch {
        Write-Output "ERROR: Failed to set keys at $fileExtKey. $_"
    }
}

# Function to update registry keys for a user
function Update-UserRegistry {
    param (
        [array]$fileExtensions,
        [string]$progIDPrefix,
        [string]$exePath,
        [string]$profilePath,
        [string]$userName
    )

    # Flag to indicate if the profile is already loaded
    $profileLoaded = $false

    try {
        # Check if the profile is already loaded
        $loadedProfiles = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\hivelist" | ForEach-Object { $_.PSObject.Properties }
        $loadedProfile = $loadedProfiles | Where-Object { $_.Value -match "$userName\\NTUSER\.DAT" }

        if ($loadedProfile) {
            Write-Output "Profile for user $userName is already loaded. Using existing hive."
            $hiveRoot = "Registry::HKU$($loadedProfile.Name -replace '^\\REGISTRY\\USER', '')"
            $profileLoaded = $true
        } else {
            # Load the user's registry hive
            $userHive = "HKU\TempHive"
	    $hiveRoot = "Registry::HKU\TempHive"
            $regFile = "$profilePath\NTUSER.DAT"
            reg load $userHive $regFile
        }

        Write-Output "Updating registry for user: $userName"

        foreach ($extension in $fileExtensions) {
            $progID = "${progIDPrefix}_$($extension.TrimStart('.'))"

            Remove-UserRegistryKeys -userHiveRoot $hiveRoot -extension $extension
            Set-UserRegistryKeys -userHiveRoot $hiveRoot -extension $extension -progID $progID -exePath $exePath
        }

        # Unload the registry hive if it was loaded in this function and not previously loaded
        if (!$profileLoaded) {
            [gc]::Collect()
	    [gc]::WaitForPendingFinalizers()
	    reg unload $userHive
        }
    } catch {
        Write-Output "ERROR: Failed to update registry for user $userName : $_"
        if (!$profileLoaded -and $userHive -eq "HKU\TempHive") {
            reg unload $userHive
        }
    }
}

# Get all user profile paths
$userProfiles = Get-WmiObject Win32_UserProfile | Where-Object { $_.Special -eq $false } | Select-Object -ExpandProperty LocalPath

foreach ($profilePath in $userProfiles) {
    $userName = Split-Path $profilePath -Leaf

    Update-UserRegistry -profilePath $profilePath -userName $userName -fileExtensions $fileExtensions -progIDPrefix $progIDPrefix -exePath $exePath
}

Write-Host "File associations updated successfully for all users."
