function Get-PortExhaustionConnection {
    <#
    .SYNOPSIS
        Get all port exhaustion connections that are TimeWait and CloseWait and relative data.
    .DESCRIPTION
        Symptoms of port exhaustion:
        Network connectivity errors
        Inability to access fileshares
        Authentication issues
        High handle counts (a handle is needed for each port)
        Server appears unresponsive or unable to connect
        High numbers of connections in the TIME_WAIT state
        Memory errors for example: 10055 "An operation on a socket could not be performed because the system lacked sufficient buffer space or because a queue was full."
        Multiple SQL Server job failures, particularly jobs which run SSIS packages that can use up a number of connections.
    .INPUTS
        Description of objects that can be piped to the script.
    .OUTPUTS
        Description of objects that are output by the script.
    .EXAMPLE
        Get-PortExhaustionConnection
    .LINK
        https://docs.microsoft.com/en-us/windows/client-management/troubleshoot-tcpip-port-exhaust
        https://techcommunity.microsoft.com/t5/ask-the-directory-services-team/port-exhaustion-and-you-or-why-the-netstat-tool-is-your-friend/ba-p/395753
    .NOTES
        Detail on what the script does, if this is needed.
    #>
    [CmdletBinding()]
    Param (

    )

    begin {

        # First block to add/change stuff in
        try {
            <#
            If needed this is 87.5X faster than Get-NetTCPConnection -State timewait,closewait
            $NetTCPConnection = [Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpConnections().where({($PSItem.State -eq "TimeWait" -or $PSItem.State -eq "CloseWait")})
            #>

            # Check for the process ID which has maximum entries as BOUND.
            Write-Verbose -Message "Gathering NetTCPConnection Relative Data..."
            $NetTCPConnection = Get-NetTCPConnection -State timewait, closewait -ea SilentlyContinue | Group-Object -Property State, OwningProcess |
            Select-Object -Property Count, Name, @{Name = "ProcessName"; Expression = { (Get-Process -PID ($PSItem.Name.Split(',')[-1].Trim(' '))).Name } }, Group | Sort-Object Count -Descending

            # Total amount of ports in a wait status
            Write-Verbose -Message "Counting Grouped 'Wait' Connections..."
            foreach ($group in $NetTCPConnection) {
                $bound = ($bound + $group.count)
                if ($group.Name -like "*CloseWait*") {
                    $closeWaitCount = ($closeWaitCount + $group.count)
                }
                elseif ($group.Name -like "*TimeWait*") {
                    $timeWaitCount = ($timeWaitCount + $group.count)
                }
            }

            # Show port range of current settings
            # Settings profile applied to a given connection is based on the matching Transport Filter
            Write-Verbose -Message "Gathering Dynamic Port Data..."
            $NetTCPSettingArray = Get-NetTCPSetting | Where-Object { ($PSItem.SettingName -like "Automatic" -or $PSItem.SettingName -like "internet*" -or $PSItem.SettingName -like "Datacenter*") }
            $index = 0
            do {
                $NetTransportFilter = $NetTCPSettingArray[$index] | Select-Object SettingName, DynamicPortRangeStartPort, DynamicPortRangeNumberOfPorts
                $index++
            } while ($null -eq $NetTransportFilter.DynamicPortRangeStartPort -and $index -lt $NetTCPSettingArray.count)

            $freePorts = if ($null -ne $NetTransportFilter.DynamicPortRangeNumberOfPorts) {
                ($NetTransportFilter.DynamicPortRangeNumberOfPorts - $bound)
            }

            $percentFree = if ($null -ne $NetTransportFilter.DynamicPortRangeNumberOfPorts -or $null -ne $NetTransportFilter.DynamicPortRangeNumberOfPorts) {
                "{0:P3}" -f (($NetTransportFilter.DynamicPortRangeNumberOfPorts - $bound) / $NetTransportFilter.DynamicPortRangeNumberOfPorts)
            }

        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }

    }

    process {

        try {
            Write-Verbose -Message "Building Object..."
            [PSCustomObject]@{
                SettingName                   = $NetTransportFilter.SettingName
                DynamicPortRangeStartPort     = $NetTransportFilter.DynamicPortRangeStartPort
                DynamicPortRangeNumberOfPorts = $NetTransportFilter.DynamicPortRangeNumberOfPorts
                Bound                         = $bound
                BoundEntries                  = $NetTCPConnection | Select-Object Count, Name, ProcessName
                CloseWait                     = $closeWaitCount
                TimeWait                      = $timeWaitCount
                FreePorts                     = $freePorts
                PercentageFree                = $percentFree
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }

    end {

    }
}

