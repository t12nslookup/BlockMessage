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
    
    $fileExtKey = "$userHiveRoot\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$extension"

    # Remove the extension key if it exists
    if (Test-Path $fileExtKey) {
        Remove-Item -Path $fileExtKey -Recurse -Force
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

    $fileExtKey = "$userHiveRoot\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$extension"

    # Create the necessary registry keys if they don't exist
    if (-Not (Test-Path "$fileExtKey\OpenWithProgids")) {
        New-Item -Path "$fileExtKey\OpenWithProgids" -Force
    }
    Set-ItemProperty -Path "$fileExtKey\OpenWithProgids" -Name $progID -Value 0

    # Create and set UserChoice key
    $userChoiceKey = "$fileExtKey\UserChoice"
    if (-Not (Test-Path $userChoiceKey)) {
        New-Item -Path $userChoiceKey -Force
    }
    Set-ItemProperty -Path $userChoiceKey -Name "ProgId" -Value $progID
    Set-ItemProperty -Path $userChoiceKey -Name "Hash" -Value ""
}

# Function to remove existing registry keys in HKLM
function Remove-MachineRegistryKeys {
    param (
        [string]$extension
    )
    
    $rootPath = "HKLM:\Software\Classes"
    $extensionKey = "$rootPath\$extension"
    $progIDKey = "$rootPath\$extension\shell\open\command"
    $openWithProgidsKey = "$rootPath\$extension\OpenWithProgids"

    # Remove the extension key if it exists
    if (Test-Path $extensionKey) {
        Remove-Item -Path $extensionKey -Recurse -Force
    }

    # Remove the ProgID key if it exists
    if (Test-Path $progIDKey) {
        Remove-Item -Path $progIDKey -Recurse -Force
    }

    # Remove the OpenWithProgids key if it exists
    if (Test-Path $openWithProgidsKey) {
        Remove-Item -Path $openWithProgidsKey -Recurse -Force
    }
}

# Function to set registry keys in HKLM
function Set-MachineRegistryKeys {
    param (
        [string]$extension,
        [string]$progID,
        [string]$exePath
    )

    $rootPath = "HKLM:\Software\Classes"

    # Create the necessary registry keys if they don't exist
    if (-Not (Test-Path "$rootPath\$extension")) {
        New-Item -Path "$rootPath\$extension" -Force
    }
    Set-ItemProperty -Path "$rootPath\$extension" -Name "(default)" -Value $progID

    if (-Not (Test-Path "$rootPath\$progID\shell\open\command")) {
        New-Item -Path "$rootPath\$progID\shell\open\command" -Force
    }
    Set-ItemProperty -Path "$rootPath\$progID\shell\open\command" -Name "(default)" -Value "`"$exePath`" `"%1`""

    # Add ProgID to OpenWithProgids
    if (-Not (Test-Path "$rootPath\$extension\OpenWithProgids")) {
        New-Item -Path "$rootPath\$extension\OpenWithProgids" -Force
    }
    if (-Not (Get-ItemProperty -Path "$rootPath\$extension\OpenWithProgids" -Name $progID -ErrorAction SilentlyContinue)) {
        New-ItemProperty -Path "$rootPath\$extension\OpenWithProgids" -Name $progID -PropertyType String -Value ""
    }
}

foreach ($extension in $fileExtensions) {
    $progID = "${progIDPrefix}_$($extension.TrimStart('.'))"

    # Remove existing keys in HKLM
    Remove-MachineRegistryKeys -extension $extension

    # Set new associations in HKLM
    Set-MachineRegistryKeys -extension $extension -progID $progID -exePath $exePath
}

Write-Host "File associations updated successfully for all users."
