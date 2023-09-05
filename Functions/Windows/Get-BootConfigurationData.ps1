function Get-BootConfigurationData {
    <#
    .SYNOPSIS
        Grab boot configuration data
    .DESCRIPTION
        Grab boot configuration data
    .INPUTS
        Description of objects that can be piped to the script.
    .OUTPUTS
        Description of objects that are output by the script.
    .EXAMPLE
        Get-BootConfigurationData
    .LINK
        link here
    .NOTES
        Detail on what the script does, if this is needed.
    #>
    param (
        $bcdeditpath = (Join-Path $env:SystemRoot 'system32\bcdedit.exe')
    )

    Begin {
        $bootconfigurationdata = Invoke-Expression $bcdeditpath
        $bootconfigurationdata += ''
        $hash = $null
    }

    Process{
        $result = foreach ($line in $bootconfigurationdata) {
            if ($line -eq '') {

                if ($hash) {
                    [pscustomobject]$hash
                }

                $hash = @{}
                continue
            }

            if ($line.startswith('-----')) {
                continue
            }

            if ($line.startswith('Windows Boot')) {
                $hash.Add('Type', $line)
            } else {
                $name = $line.Substring(0, $line.IndexOf(' '))
                $value = $line.Substring($line.IndexOf(' ')).trim()
                $hash.Add($name, $value)
            }
        }

        $props = $result | foreach-object {Get-Member -in $PSItem -Type *property} |  foreach-object name | Select-Object -Unique | Sort-Object

        $result | Select-Object $props

    }
}