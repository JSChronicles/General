function Initialize-BCDOutputList {

    $entries = ([System.Collections.Generic.List[pscustomobject]]::new())
    $count = 0

    do {
        Start-Sleep -Milliseconds 1700
        $count ++
        if ($count -eq "2" -or "4") {
            Export-CurrentBCDSetting -Path "C:\bcd_backup.bcd"
        }
    } until ((Test-Path -Path "C:\bcd_backup.bcd") -or ($count -eq "5"))

    if (!(Test-Path -Path "C:\bcd_backup.bcd")) {
        $logger.error("Current BCDEdit Settings where unable to backup properly. Please manually back them up. ")
        throw "Current BCDEdit Settings where unable to backup properly. Please manually back them up. "
    }

    # IMPORTANT: bcdedit /enum requires an ELEVATED session.
    # Initialize the output list.
    Write-Verbose -Message "Building BCDEdit Custom Object..."
    $bcdOutput = (bcdedit /enum) -join "`n" # collect bcdedit's output as a *single* string
    # Parse bcdedit's output.
    ($bcdOutput -split '(?m)^(.+\n-)-+\n' -ne '').ForEach( {
            if ($PSItem.EndsWith("`n-")) {
                # entry header
                $entries.Add([pscustomobject] @{ Name = ($PSItem -split '\n')[0]; Properties = [ordered] @{ } })
            }
            else {
                # block of property-value lines
            ($PSItem -split '\n' -ne '').ForEach( {
                        $propAndVal = $PSItem -split '\s+', 2 # split line into property name and value
                        if ($propAndVal[0] -ne '') {
                            # [start of] new property; initialize list of values
                            $currProp = $propAndVal[0]
                            $entries[-1].Properties[$currProp] = [System.Collections.Generic.List[string]]::new()
                        }
                        $entries[-1].Properties[$currProp].Add($propAndVal[1]) # add the value
                    })
            }
        })

    $entries
}