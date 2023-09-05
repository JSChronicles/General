function Resolve-BCDEdit {
    <#
    .SYNOPSIS
        Backup and cleanup
    .DESCRIPTION
        A longer description.
    .PARAMETER Description
        Description of each of the parameters.
        Note:
        To make it easier to keep the comments synchronized with changes to the parameters,
        the preferred location for parameter documentation comments is not here,
        but within the param block, directly above each parameter.
    .INPUTS
        Description of objects that can be piped to the script.
    .OUTPUTS
        Description of objects that are output by the script.
    .EXAMPLE
        Resolve-BCDEdit
    .EXAMPLE
        Resolve-BCDEdit -Description "somebusiness"
    .LINK
        Links to further documentation.
    .NOTES
        create test BCD using bcdedit /copy {current} /d "test"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [String]$Description

    )

    begin {
        $logger.Notice("Starting $($MyInvocation.MyCommand) script")

        $winProductName = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName
        $Description = "$Description-$winProductName"

        Write-Warning -Message "Resolving BCDEdit objects...Please be patient as this is an important task"

        function Export-CurrentBCDSetting {
            params (
                [Parameter(Mandatory,
                    Position = 0,
                    ValueFromPipeline)]
                [string]$Path
            )

            if (Test-Path -Path $Path) {
                Remove-Item -Path $Path -Force -ErrorAction SilentlyContinue
            }

            Write-Verbose -Message "Exporting Current BCDEdit Settings..."
            bcdedit /export "$Path"
        }
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

        function Remove-NonCurrentEntry {
            [CmdletBinding(SupportsShouldProcess)]
            param (
                [Parameter(Mandatory,
                    Position = 0
                )]
                $Entry
            )
            $winBootLoaders = ($Entry.where( { $PSItem.name -like "*Windows Boot Loader*" }))
            $current = $Entry.where( { $PSItem.name -like "*Windows Boot Manager*" }).properties.default

            Write-Verbose -Message "Removing Non-Current BCDEdit Boot Loader Objects..."
            foreach ($winBootLoader in $winBootLoaders) {

                if ($winBootLoader.properties.identifier -ne "$($current)") {
                    if ($PSCmdlet.ShouldProcess("windows boot loader $($winBootLoader.properties.identifier)", "Remove")) {
                        Write-Output "$($winBootLoader.properties.identifier) is being removed"
                        $logger.notification("$($winBootLoader.properties.identifier) is being removed")

                        bcdedit /displayorder "$($winBootLoader.properties.identifier)" /remove
                        #bcdedit /delete "$($winBootLoader.properties.identifier)"
                    }
                }
            }
        }
    }

    process {

        $entries = Initialize-BCDOutputList

        if (($entries).count -gt 2) {
            Remove-NonCurrentEntry -Entry $entries
        }
        # Rename {Current} description
        $logger.informational("Renaming {Current} description...")
        $current = $entries.where( { $PSItem.name -like "*Windows Boot Manager*" }).properties.default
        bcdedit /set "$current" description  "$description"
    }

    end {
        Write-Verbose -Message "Configuration of BCDEdit is Complete"
        $logger.Notice("Finished $($MyInvocation.MyCommand) script")
    }
}