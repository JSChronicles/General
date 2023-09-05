#using namespace System.Management.Automation.Host
function Enable-BitlockerEncryption {
    <#
    .SYNOPSIS
        Encrypts the drive with bitlocker and creates a backup to AD and a flashdrive if connected.
    .DESCRIPTION
        Checks and fixes the reagent file and WinRE.
        Checks compatibility between the tpm Version, firmware type and partiton style.
        If everything is working correctly or set properly then it will check to see if the computer is bitlocked and if not
        then it will prompt to bitlock and backup the key to AD and create a file on the first USB drive plugged into the computer.
    .OUTPUTS
        Description of objects that are output by the script.
    .EXAMPLE
        Enable-BitlockerEncryption
    .LINK
        Links to further documentation.
    .NOTES
        Detail on what the script does, if this is needed.
    #>
    [CmdletBinding()]
    param (

    )

    begin {

        if ((Get-LocalUser).name -contains $env:USERNAME) {
            return Write-Warning -Message "Logged in as $env:UserName, You cannot encrypt a drive on a non-AD account."
        }

        $BLV = Get-BitLockerVolume -MountPoint "C:"
        $BLVKeyProtector = $BLV.KeyProtector | Where-Object { $_.KeyProtectorType -like "recoverypassword" } | Select-Object -Last 1
        function Show-Menu {
            [CmdletBinding()]
            [OutputType([Boolean])]
            param(
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [string]$Title,

                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [string]$Question
            )
            #Add-Type -TypeDefinition 'using namespace System.Management.Automation.Host'
            $Yes = [System.Management.Automation.Host.ChoiceDescription]::new('&Yes')
            $No = [System.Management.Automation.Host.ChoiceDescription]::new('&No')
            $Cancel = [System.Management.Automation.Host.ChoiceDescription]::new('&Cancel')

            $options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No, $Cancel)

            $result = $host.ui.PromptForChoice($Title, $Question, $options, 0)

            switch ($result) {
                0 {
                    return $true
                    Break
                 }
                1 {
                    return $false
                    Break
                 }
                2 {
                    return $false
                    Break
                 }
            }
        }

        function Backup-Key {
            begin {

                Add-Type -AssemblyName System.DirectoryServices.AccountManagement;
                $DisplayName = [System.DirectoryServices.AccountManagement.UserPrincipal]::Current.DisplayName;
                $DisplayName = ($DisplayName).replace(" ","_")

                $BLV = Get-BitLockerVolume -MountPoint "C:"
                $BLVKeyProtector = $BLV.KeyProtector | Where-Object {$_.KeyProtectorType -like "recoverypassword"} | Select-Object -Last 1

                # Store on first external USB drive connected
                $BackuptoUSB = (Get-Volume | Where-Object {($_.DriveLetter-ne "C" -and $_.drivetype -eq "Removable")} | Select-Object driveletter,drivetype -Last 1)
                $numericalFileName = "$DisplayName`_assetnumber`_$date`_BitLocker Recovery Key $(($BLVKeyProtector.KeyProtectorId).Trim('{}')).txt"

            }

            Process{

                # Create text file Contents
                $passwordFileContent = @"
$DisplayName
To verify that this is the correct recovery key, compare the start of the following identifier with the identifier value displayed on your PC.

Identifier:

$(($BLVKeyProtector.KeyProtectorId).Trim('{}'))

If the above identifier matches the one displayed by your PC, then use the following key to unlock your drive.

Recovery Key:

$($BLVKeyProtector.recoverypassword)

If the above identifier doesn't match the one displayed by your PC, then this isn't the right key to unlock your drive.
Try another recovery key, or refer to https://go.microsoft.com/fwlink/?LinkID=260589 for additional assistance.
"@

                if($null -ne $BackuptoUSB){
                    if (!(test-path -Path "$($BackuptoUSB.driveletter):\BitLockerKeys")) {
                        [void](New-Item -Path "$($BackuptoUSB.driveletter):\BitLockerKeys" -ItemType Directory -ErrorAction SilentlyContinue -ErrorVariable $InstallingSoftware)
                    }
                    Write-Verbose -Message "Backing Up Key to a Flash Drive..."
                    $passwordFileContent | Out-File "$($BackuptoUSB.driveletter):\BitLockerKeys\$numericalFileName"
                }
            }
        }
    }

    process {
        # Check Current Bitlocker Status
        if ($BLV.VolumeStatus -notmatch "FullyEncrypted") {

            Write-Output "BitLocker Status: $($BLV.VolumeStatus)"

            $Answer = Show-Menu -Title 'Bitlocker' -Question "Do you wish to Bitlock the current computer [$env:computername]"
            if ($Answer) {
                # Enable Bitlocker on C:\ for both TPM and numercial recovery key
                Write-Verbose -Message "Enabling Bitlocker Settings..."
                Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes128 -RecoveryPasswordProtector

                $BLV = Get-BitLockerVolume -MountPoint "C:"
                $BLVKeyProtector = $BLV.KeyProtector | Where-Object { $_.KeyProtectorType -like "recoverypassword" } | Select-Object -Last 1

                # Upload key to AD
                Write-Verbose -Message "Backing Up Numerical Key to AD..."
                [void](Backup-BitLockerKeyProtector -MountPoint "C:" -KeyProtectorId $BLVKeyProtector.KeyProtectorId)

                # Enable notificaction in tray
                Push-Location -Path "$Home"
                fvenotify.exe
            }
            Else {
                Write-Output "Skipping Bitlocker Setup..."
            }

        }
        Else {
            Write-Output "BitLocker Status: $($BLV.VolumeStatus)"
        }
    }

    end {
        if ($BLV.VolumeStatus -notmatch "FullyDecrypted" -and !([string]::IsNullOrWhiteSpace($BLV.KeyProtector))) {
            [void](Backup-BitLockerKeyProtector -MountPoint "C:" -KeyProtectorId $BLVKeyProtector.KeyProtectorId)
        }
        # If not decrypted then back up key to flash drive
        if (!([string]::IsNullOrWhiteSpace($BLV.KeyProtector))) {
            Backup-Key
        }
    }
}
