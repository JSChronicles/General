function Add-RSATTool {
    <#
    .SYNOPSIS
        Adds "ActiveDirectory", "bitlocker", "wsus" RSAT tools to the computer.
    .DESCRIPTION
        Turns off WSUS connection and adds the RSAT tools "ActiveDirectory", "bitlocker", "wsus".
        Then turns the WSUS connection back on.
    .PARAMETER FirstParameter
        Description of each of the parameters.
        Note:
        To make it easier to keep the comments synchronized with changes to the parameters,
        the preferred location for parameter documentation comments is not here,
        but within the param block, directly above each parameter.
    .PARAMETER SecondParameter
        Description of each of the parameters.
    .INPUTS
        Description of objects that can be piped to the script.
    .OUTPUTS
        Description of objects that are output by the script.
    .EXAMPLE
        Add-RSATTools
    .LINK
        Links to further documentation.
    .NOTES
       Error 0x800f0954 happens, unless you turn off WSUS updates and restart the service
    #>
    [CmdletBinding()]
    param (
        [ValidateSet("ActiveDirectory","bitlocker","wsus")]
        [String[]]$Feature = ("ActiveDirectory","bitlocker","wsus")
    )

    begin {
        $wsusReg = "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU\"
        $name = "UseWUServer"
        $on = "1"
        $off = "0"
        $service = Get-Service -Name "wuauserv"

        $availableRSAT = Get-WindowsCapability -Online
    }

    process {
        # Turn off WSUS connection in Registry
        Set-ItemProperty -Path $wsusReg -name $name -Type Dword -Value $off

        # Restart WSUS Service and Install Add-Ons
        $service | Restart-Service -Force
        foreach ($install in $Feature) {
            $availableRSAT | Where-Object {$PSItem.Name -like "*$install*" } | Add-WindowsCapability -Online
        }

        # Turn on WSUS connection in Registry
        Set-ItemProperty -Path $wsusReg -name $name -Type Dword -Value $on

        # Restart WSUS Service
        $service | Restart-Service -Force
    }

    end {
        # Check installed items
        $installed = Get-WindowsCapability -Name RSAT* -Online | where-object {$PSItem.state -like "installed"}
        foreach ($install in $installed) {
            [PSCustomObject]@{
                Name = $install.displayname
                State = $install.State
            }
        }
        start-sleep -seconds 5
    }
}
