function Sync-WindowsTimeService {
    <#
    .SYNOPSIS
        Sync the current computers time service.
    .DESCRIPTION
        Sync the current computers time service to a server. Test the connection to the server before proceeding.
        If there is no connection then the script will stop. If it fails the command then it will output the command for you to use
        manually. If you do not wish to sync to a specific machine then do not run with ComputerName parameter.
    .PARAMETER ComputerName
        Type a computer/server name that you want to sync the current machine to. It will test the connection before making any changes.
    .PARAMETER LogPath
        Path of the logfile you want it to log to. Default is C:\Temp.
    .INPUTS
        Description of objects that can be piped to the script.
    .OUTPUTS
        Description of objects that are output by the script.
    .EXAMPLE
        Sync-WindowsTimeService -ComputerName "console.real.root.local"
    .EXAMPLE
        Sync-WindowsTimeService
    .LINK
        Links to further documentation.
    .NOTES
        Detail on what the script does, if this is needed.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if (-Not (Test-Connection -ComputerName $PSItem -Quiet -Count 1) ) {
                    throw "Connection to $PSItem failed"
                }
                return $true
            })]
        [string]$ComputerName,

        [Parameter(Position = 1,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [String]$ID = "Central Standard Time",

        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [String]$LogPath = "C:\Temp"
    )

    begin {

        $logger.Notice("Starting $($MyInvocation.MyCommand) script")

        Write-Verbose -Message "Building Time Parameters..."
        $timeArgs = @{}
        if ($PSBoundParameters.ContainsKey('ComputerName')) {
            $timeArgs.ArgumentList  = @(
                "/config"
                "/manualpeerlist:$ComputerName"
                "/reliable:yes"
                "/update"
            )
        } else {
            $timeArgs.ArgumentList  = @(
                "/config"
                "/syncfromflags:DOMHIER"
                "/update"
            )
        }

        $timeArgs = @{
            FilePath      = 'w32tm.exe'
            Wait          = $True
            NoNewWindow   = $True
            ErrorAction   = "Stop"
            ErrorVariable = "+TimeSync"
            PassThru      = $True
        }
    }

    process {
        Write-Verbose -Message "Running DC Time Sync..."
        try {
            if ((Get-LocalUser).name -contains $env:USERNAME) {
                $logger.Informational("Logged in as $env:UserName, Cannot Run Time Fix.")
                Write-Output "Logged in as $env:UserName, Cannot Run Time Fix."
            }
            else {
                Write-Output "Running DC Time Sync..."
                if ($PSCmdlet.ShouldProcess("Item: $($timeArgs.FilePath)", 'Start-Process')) {
                    $time = Start-Process @timeArgs
                }

                $logger.Informational("Setting Timezone to Automatic...")
                Write-Output "Setting Timezone to Automatic..."

                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate" -Name "Start" -type Dword -Value 3
            }

            if ($PSCmdlet.ShouldProcess("Item: '$ID'", 'Setting')) {
                $logger.Informational("Setting Timezone to $ID...")
                Set-TimeZone -Id $ID
            }

            if ($null -ne $time.ExitCode -and $time.ExitCode -eq 0) {
                $logger.Informational("[Time exitcode]:$($time.exitcode) Successful")
                Write-Output "[Time exitcode]:$($time.exitcode) Successful"
            }
            else {
                $logger.Warning("[Time exitcode]:$($time.exitcode) Failed.")
                Write-Warning -Message "[Time exitcode]:$($time.exitcode) Failed."

                $logger.Warning("Please Run Manually $($timeArgs.FilePath) $($timeArgs.ArgumentList)")
                Write-Output "Please Run Manually $($timeArgs.FilePath) $($timeArgs.ArgumentList)"
            }
        }
        catch {
            $logger.Error("$PSitem")
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }

    }

    end {
        Write-Verbose -Message "Finished DC Time Sync"

        $logger.Notice("Finished $($MyInvocation.MyCommand) script")
    }
}
