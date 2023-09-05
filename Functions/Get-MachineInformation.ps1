
function Get-MachineInformation {
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter(
            Position = 1,
            ValueFromPipeline)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        if ($PSBoundParameters.ContainsKey('Credential')) {
            $sessionParams = @{
                Credential  = $Credential
                ErrorAction = 'Stop'
            }
        }
    }

    Process {
        $ComputerInfo = foreach ($Computer in $ComputerName) {
            try {
                $sessionParams.ComputerName = $Computer
                $session = New-CimSession @sessionParams

                $computerSystem = (Get-CimInstance -ClassName 'Win32_ComputerSystem' -Property Manufacturer, Model, TotalPhysicalMemory, UserName -CimSession $session)
                $computerBIOS = (Get-CimInstance -ClassName 'Win32_BIOS' -Property SerialNumber -CimSession $session)
                $computerOS = (Get-CimInstance -ClassName 'Win32_OperatingSystem' -Property caption -CimSession $session)
                $computerCPU = (Get-CimInstance -ClassName 'Win32_Processor' -Property Name, numberofcores -CimSession $session)
                $computerHDD = (Get-CimInstance -ClassName 'Win32_LogicalDisk' -Filter 'DeviceId = "C:"' -CimSession $session)
                $computerMacAddress = (Get-CimInstance -ClassName 'win32_networkadapterconfiguration' -Property Description, MACAddress -CimSession $session |
                        Where-Object { ($null -ne $PSItem.macaddress) -and ($PSItem.Description -like "*Wireless*" -or $PSItem.Description -like "*Ethernet*" -or $PSItem.Description -like "*ac*") })

                $ethernet = "$(($computerMacAddress | Where-Object {$PSItem.description -like "ethernet*"}).Description): [$(($computerMacAddress | Where-Object {$PSItem.description -like "ethernet*"}).MACAddress -replace ":", "-")]"
                $wireless = "$(($computerMacAddress | Where-Object {$PSItem.description -like "*Wireless*"}).Description): [$(($computerMacAddress | Where-Object {$PSItem.description -like "*Wireless*"}).MACAddress -replace ":", "-")]"
                $VirtualAdapter = "$(($computerMacAddress | Where-Object {$PSItem.description -like "*virtual * adapter*"}).Description): [$(($computerMacAddress | Where-Object {$PSItem.description -like "*virtual * adapter*"}).MACAddress -replace ":", "-")]"

                [PSCUSTOMOBJECT]@{
                    ComputerName   = $computerSystem.Name
                    Manufacturer   = $computerSystem.Manufacturer
                    Model          = $computerSystem.Model
                    SerialNumber   = $computerBIOS.SerialNumber
                    CPU            = $($computerCPU.Name)
                    Cores          = $($computerCPU.numberofcores)
                    DriveCapacity  = "$([Math]::Round(($computerHDD.Size/1GB)))GB"
                    DriveSpace     = "{0:P2}" -f ($computerHDD.FreeSpace / $computerHDD.Size) + " Free (" + "{0:N2}" -f ($computerHDD.FreeSpace / 1GB) + "GB)"
                    RAM            = "$([Math]::Round(($computerSystem.TotalPhysicalMemory/1GB)))GB"
                    OS             = $computerOS.caption
                    Ethernet       = if ($ethernet -match '\: \[\]') {} else { $ethernet }
                    WiFi           = if ($wireless -match '\: \[\]') {} else { $wireless }
                    VirtualAdapter = if ($VirtualAdapter -match '\: \[\]') {} else { $VirtualAdapter }
                    CurrentUser    = $computerSystem.UserName
                }
            }
            catch {
                $PSItem
            }
        }

        $ComputerInfo

    }

    end {
        # Remove Cim sessions
        foreach ($Computer in $RemoteMachine) {
            Get-Cimsession | Remove-CimSession
        }
    }

}