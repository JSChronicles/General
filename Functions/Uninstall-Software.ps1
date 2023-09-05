function Uninstall-Software {
    <#
.SYNOPSIS
    Uninstall software
.DESCRIPTION
    Uninstall software of your choosing. The script will pull the uninstall and convert as need.
.EXAMPLE
   Uninstall-Software -Name "cisco"
.EXAMPLE
    Uninstall-Software -Name "cisco" -Whatif
.INPUTS
    Software list
.OUTPUTS
    Host console will see a list of software names being uninstall as it happens.
.NOTES
#>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Position = 0, ParameterSetName = 'UninstallNames',
            HelpMessage = "Enter one or more software names. Or use (gc C:\softwarelist.txt)")]
        [String]$Name,

        [parameter()]
        [switch]$CSV
    )

    begin {
        $Properties = @("DisplayName", "UninstallString")
        $32bit = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
        $64bit = "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"

        $endTailArgs = @{
            Wait          = $True
            NoNewWindow   = $True
            ErrorAction   = "Stop"
            ErrorVariable = "+UninstallSoftware"
            PassThru      = $True
        }

        $qtVer = (Get-ChildItem -Path $32bit, $64bit | Get-ItemProperty) | Where-Object { $PSItem.DisplayName -like "*$Name*" } | Select-Object -Property $Properties
    }

    process {
        try {
            if ($CSV) {
                $qtVer | Sort-Object DisplayName | Export-Csv -Path "$home\desktop\uninstallInfo.csv" -NoTypeInformation
            }
            else {
                ForEach ($ver in $qtVer) {
                    if ($PSCmdlet.ShouldProcess("$($ver.DisplayName)", "Uninstall")) {
                        If ($ver.UninstallString) {
                            $uninst = $ver.UninstallString
                            $uninst = $uninst -replace "/I", "/x "
                            $uninstall = Start-Process -FilePath cmd.exe -ArgumentList '/c', "$uninst /Q" @endTailArgs

                            if ([int]$uninstall.lastexitcode -eq 0) {
                                Write-Output "LastExitCode: $($uninstall.ExitCode) - $Name has uninstalled properly"

                            }
                            else {
                                Write-Error -Message "LastExitCode: $($uninstall.ExitCode) - $Name has not uninstalled properly" -ErrorVariable +UninstallSoftware
                            }

                        }

                    }
                }

            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }

    end {
        if ($null -ne $UninstallSoftware) {
            $UninstallSoftware
        }
    }
}
