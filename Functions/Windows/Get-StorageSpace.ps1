function Get-StorageSpace {
    <#
    .SYNOPSIS
        Grab one or more computers drive space.
    .DESCRIPTION
        Gather all drives per computer and output an object that has the name and driver letter, capacity, percentage left and GB free
    .PARAMETER ComputerName
        Provide one or more computer names, default uses the current machines name.
    .PARAMETER Credential
        Provide a credential to access computers as needed.
    .INPUTS
        Description of objects that can be piped to the script.
    .OUTPUTS
        Description of objects that are output by the script.
    .EXAMPLE
        Get-StorageSpace
    .EXAMPLE
        Get-StorageSpace -ComputerName "computerOne"
    .EXAMPLE
        Get-StorageSpace -ComputerName "computerOne","computerTwo"
    .EXAMPLE
        Get-StorageSpace -ComputerName "computerOne","computerTwo" -Credential $credential
    .LINK
        https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-computersystem
    .NOTES
        Detail on what the script does, if this is needed.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Position = 1)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty

    )
    begin {

        $autoCimParams = @{
            ErrorAction = 'SilentlyContinue'
        }

        if ($PSBoundParameters.ContainsKey('Credential')) {
            $autoCimParams.Credential = $Credential
        }
    }

    Process {
        foreach ($Computer in $ComputerName) {
            $autoCimParams.Name = $Computer
            $autoCimParams.ComputerName = $Computer

            if (Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
                try {
                    # Create a CIM Session and gather HDD info
                    $session = (New-CimSession @autoCimParams)
                    $computerSystem = (Get-CimInstance -ClassName 'Win32_ComputerSystem' -Property UserName -CimSession $session)
                    $computerHDD = (Get-CimInstance -ClassName 'Win32_LogicalDisk' -Filter 'drivetype = "3"' -CimSession $session)

                    foreach ($HDD in $computerHDD) {
                        [PSCUSTOMOBJECT]@{
                            ComputerName  = $computerSystem.Name
                            DriveLetter   = $HDD.deviceid
                            DriveCapacity = "$([Math]::Round(($HDD.Size/1GB)))GB"
                            DriveSpace    = "{0:P2}" -f ($HDD.FreeSpace / $HDD.Size)
                            FreeSpaceGB   = "{0:N2}" -f ($HDD.FreeSpace / 1GB) + "GB"
                        }
                    }
                }
                catch {
                    $PSItem
                }
            }
            else {
                Write-Output "There is no connection for $computer."
            }
        }
    }

    end {
        # Remove Cim sessions
        foreach ($Computer in $ComputerName) {
            Get-CimSession -Name $Computer -ea SilentlyContinue | Remove-CimSession -ea SilentlyContinue
        }

    }
}
