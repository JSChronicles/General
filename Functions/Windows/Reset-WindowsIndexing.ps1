function Reset-WindowsIndexing {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [System.Object]$Service = (Get-Service -name "WSearch")
    )

    begin {
        # First block to add/change stuff in
        try {
            $windowsIndexPath = "$env:ProgramData\Microsoft\Search\Data\Applications\Windows\Windows.edb"
            $processes = @(
                "SearchIndexer.exe",
                "SearchFilterHost.exe",
                "SearchProtocolHost.exe"
            )
            $retry = 0
        }
        catch {
            $logger.Error("$PSitem")
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }

    }

    process {

        try {
            foreach ($process in $processes){
                if (Get-Process -Name $process -ea SilentlyContinue) {
                    $logger.Informational("Stopping $process process")
                    Get-Process -Name $process | Stop-Process -force
                }
            }

            Set-Service $service.Name -StartupType Disabled
            Stop-Service $service.Name -Force
            $logger.Informational("Waiting for $($service.Name) service to stop")
            $service.WaitForStatus('Stopped', '00:00:030')

            if (test-path -Path $windowsIndexPath) {
                $logger.Informational("removing $windowsIndexPath")
                [void](Remove-Item -Path $windowsIndexPath -Force)
            }

            Write-Output "Rebuilding Search Index"
            Set-Service $service.Name -StartupType Automatic
            Start-Service $service.Name -ea Ignore
            $logger.Informational("Waiting for $($service.Name) service to start")

            do {
                Start-Service -Name "WSearch"
                Start-Sleep -Seconds 5
                $retry++
            } until (((Get-Service -name "WSearch").Status -eq "Running") -or ($retry -ge 5))
        }
        catch {
            $logger.Error("$PSitem")
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }

    end {
        $logger.Notice("Finished $($MyInvocation.MyCommand) script")
    }
}
