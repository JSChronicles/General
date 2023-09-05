function Get-PortExhaustionEvent {
    <#
    .SYNOPSIS
        Grab all port exhaustion events in the last minute.
    .DESCRIPTION
        Grab all port exhaustion events in the last minute.
    .PARAMETER StartTime
        The amount of time, in minutes negative, you want to go back in windows events
    .INPUTS
        Description of objects that can be piped to the script.
    .OUTPUTS
        Description of objects that are output by the script.
    .EXAMPLE
        Get-PortExhaustionEvent
    .EXAMPLE
        Get-PortExhaustionEvent -StartTime -20
    .LINK
        https://docs.microsoft.com/en-us/windows/client-management/troubleshoot-tcpip-port-exhaust
    .NOTES
        Detail on what the script does, if this is needed.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(
            ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [int]$StartTime = -1
    )

    begin {

        # First block to add/change stuff in
        try {
            Write-Verbose -Message "Building Filter Hash..."
            $filter = @{
                LogName      = 'System'
                ProviderName = 'Tcpip'
                #Path =<String[]>
                #Keywords = $eventValues['EventLogClassic']
                ID           = "4227", "4231"
                Level        = 3
                StartTime    = (Get-Date).AddMinutes($StartTime)
                #EndTime =$EndTime
                #UserID =<SID>
                #Data =''
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }

    }

    process {

        try {
            Write-Verbose -Message "Gathering Windows Event Ids '4227','4231'..."
            Get-WinEvent -FilterHashtable $filter -ErrorAction SilentlyContinue
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }

    end {

    }
}