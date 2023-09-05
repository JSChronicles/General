function Get-BitlockerCompatibility {
    <#
    .SYNOPSIS
        Multi-check for Bitlocker Compatibility.
    .DESCRIPTION
        Multi-check for Bitlocker Compatibility. If you run into an error you may need to run this bit of code to fix it.
        # Checks if WinRE is enabled
        $env:SystemDirectory = [Environment]::SystemDirectory
        $analyzeReagentc = Invoke-Expression "$env:SystemDirectory\ReagentC.exe /info"
        $analyzeReagentcEnabled = "$AnalyzeReagentC" -Match [regex]::new("Enabled")
    .INPUTS
        Description of objects that can be piped to the script.
    .OUTPUTS
        Description of objects that are output by the script.
    .EXAMPLE
        Get-BitlockerCompatibility
    .LINK
        Links to further documentation.
    .NOTES
        Detail on what the script does, if this is needed.
    #>
    [CmdletBinding()]
    param (
    )
    begin {

        # First block to add/change stuff in
        try {

            $winProductName = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName
            $partitonStyleCheck = Get-Disk | Where-Object -FilterScript { $_.isboot -Eq "true" } | Select-Object -ExpandProperty partitionstyle
            $BitLockerReadyDrive = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction SilentlyContinue

            $tpm = (Get-Tpm)

            $Compatibility = [PSCustomObject]@{
                Version              = ((Get-CimInstance -ClassName "Win32_Tpm" -Namespace "root\cimv2\Security\MicrosoftTpm").SpecVersion).Split("{,}")[0]
                TPMPresent           = $tpm.TpmPresent
                TPMReady             = $tpm.TpmReady
                WinRE                = ""
                User                 = ""
                OU                   = ""
                PartitionProvisioned = ""
                HardwareCompatible   = ""
            }
            function Get-ADSystemInfo {
                # https://technet.microsoft.com/en-us/library/ee198776.aspx
                $properties = @(
                    'UserName',
                    'ComputerName',
                    'SiteName',
                    'DomainShortName',
                    'DomainDNSName',
                    'ForestDNSName',
                    'PDCRoleOwner',
                    'SchemaRoleOwner',
                    'IsNativeMode'
                )
                $adsi = New-Object -ComObject ADSystemInfo
                $type = $adsi.GetType()
                $hash = @{}
                foreach ($property in $properties) {
                    $hash.Add($property, $type.InvokeMember($property, 'GetProperty', $Null, $adsi, $Null))
                }
                [pscustomobject]$hash
            }

        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }

    }

    process {

        try {

            if ($BitLockerReadyDrive) {
                $Compatibility.PartitionProvisioned = $True
            } else {
                $Compatibility.PartitionProvisioned = $False
            }

            if ($analyzeReagentcEnabled) {
                $Compatibility.WinRE = $True
            } else {
                $Compatibility.WinRE = $False
            }

            if (!((Get-LocalUser).name -contains $env:USERNAME)) {
                $Compatibility.User = $True
                if (!(((Get-ADSystemInfo).computername).contains('/'))) {
                    $Compatibility.OU = $True
                } else {
                    $Compatibility.OU = $False
                }

            } else {
                $Compatibility.User = $False
            }

            # Check if TPM Version, partition Style,, and firmware meet requirements
            if ($winProductName -like "*10 Pro*" -or $winProductName -like "*10 enterprise*") {
                if ($Compatibility.TPMPresent) {
                    if ($Compatibility.Version -eq "1.2" -and $env:firmware_type -eq "Legacy" -and $partitonStyleCheck -eq "MBR") {
                        $Compatibility.HardwareCompatible = $True
                    } elseif (($Compatibility.Version -eq "1.2" -or $Compatibility.Version -eq "2.0" ) -and $env:firmware_type -eq "UEFI" -and $partitonStyleCheck -eq "GPT") {
                        $Compatibility.HardwareCompatible = $True
                    } else {
                        $Compatibility.HardwareCompatible = $False
                    }
                }
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }

        $Compatibility

    }

    end {

    }
}
