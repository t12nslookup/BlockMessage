# Define the file extensions and associated executable
$fileExtensions = @(".tar", ".gz")
$exePath = "C:\SGS\BlockMessage.exe"

# Function to create and set registry keys
function Set-RegistryKeys {
    param (
        [string]$rootPath,
        [string]$extension,
        [string]$progID,
        [string]$exePath
    )

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

# Loop through each file extension and set association in HKLM
foreach ($extension in $fileExtensions) {
    $progID = "blockmessagefile_$($extension.TrimStart('.'))"

    # Set associations in HKLM
    Set-RegistryKeys -rootPath "HKLM:\Software\Classes" -extension $extension -progID $progID -exePath $exePath
}

Write-Host "File associations updated successfully for all users."
