function Set-WindowsDPI {
    [CmdletBinding(SupportsShouldProcess)]
    param (
    )

    begin {
        $logger.Notice("Starting $($MyInvocation.MyCommand) script")

        $MonitorList = @(Get-CimInstance -Namespace "root\wmi" -ClassName "WmiMonitorListedSupportedSourceModes")
        $sortedModes = foreach ($Index in 0..$MonitorList.GetUpperBound(0)) {
            $PrefSourceMode = $MonitorList[$Index].PreferredMonitorSourceModeIndex
            [PSCustomObject]@{
                Res_Horizontal = $MonitorList[$Index].MonitorSourceModes.HorizontalActivePixels[$PrefSourceMode]
                Res_Vertical = $MonitorList[$Index].MonitorSourceModes.VerticalActivePixels[$PrefSourceMode]
            } | Select-Object @{N = "MaxRes"; E = { "$($PSItem.Res_Horizontal)x$($PSItem.Res_Vertical)" } }
        }
        $sortedModes = $sortedModes | Where-Object { ($PSItem.MaxRes -gt "1000x768") }

        $DPI = @{
            "1920x1080" = 96
            "2560x1440" = 144
            "3200x1800" = 168
            "3840x2160" = 216
        }

        $mainMonitor = $sortedModes.maxres | Select-Object -First 1
    }

    process {

        $logger.informational("Main Screen Resolution: $mainMonitor")
        $logger.informational("Attemping to set DPI for Main Screen to $($DPI[$mainMonitor])")

        # Creates Win8DpiScaling registry if it doesn't exist
        If (!(Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name "Win8DpiScaling" -ErrorAction SilentlyContinue)) {
            [void](New-ItemProperty -Path "HKCU:\Control Panel\Desktop\" -Name "Win8DpiScaling" -Type DWord -Value 1)
        }
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Win8DpiScaling" -Type DWord -Value 1

        # Creates LogPixels registry if it doesn't exist
        If (!(Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name "LogPixels" -ErrorAction SilentlyContinue)) {
            [void](New-ItemProperty -Path "HKCU:\Control Panel\Desktop\" -Name "LogPixels" -Type DWord -Value $DPI[$mainMonitor])
        }
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "LogPixels" -Type DWord -Value $DPI[$mainMonitor]
    }

    end {
        Write-Verbose -Message "Finished Setting Monitor DPI"
        $logger.Notice("Finished $($MyInvocation.MyCommand) script")
    }
}
