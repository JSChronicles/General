function Test-DATFile {
    <#
    .SYNOPSIS
        Tests the ntuser.dat file
    .DESCRIPTION
        Tests the ntuser.dat file by loading it into a hive and looks for a successful exit code. It will then try to unload
        the new hive upto five times. Does some log cleanup and garbage collecting at the end.
    .PARAMETER Path
        Path to any ntuser.dat file.
    .INPUTS
        Description of objects that can be piped to the script.
    .OUTPUTS
        Description of objects that are output by the script.
    .EXAMPLE
        Test-DATFile
    .EXAMPLE
        Test-DATFile -Whatif
    .LINK
        Links to further documentation.
    .NOTES
        Detail on what the script does, if this is needed.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([String])]
    param (
        [string[]]$Path
    )

    begin {
        Write-Verbose -Message "Creating where filter array..."
        $whereNameFilter = @(
            "ntuser.dat",
            "ntuser.ini",
            "ntuser.pol"
        )
    }
    process {
        foreach ($DAT in $Path) {
            try {
                Write-Verbose -Message "Creating hive name..."
                $hive = Split-Path (Split-Path -Path $DAT -Parent) -Leaf

                $hiveParams = @{
                    FilePath     = reg.exe
                    ArgumentList = "load HKLM\$hive $DAT"
                    Wait         = $true
                    WindowStyle  = Hidden
                    PassThru     = $true
                }

                # Load the user hive
                Write-Verbose -Message "Loading hive..."
                $load = Start-Process @hiveParams

                if ($load.ExitCode -ne 0) {
                    "$NTuserDATpath could not be loaded"
                }

                if ($load.ExitCode -eq 0) {
                    # Try to unload the hive, up to 5 times.
                    $att = 0
                    $hiveParams.ArgumentList = "unload HKLM\$hive"

                    while ((Test-Path -Path "HKLM:\$hive") -and ($att -le 5)) {
                        Write-Verbose -Message "Trying to unload hive $hive $att/5"
                        $unload = Start-Process @hiveParams
                        $att ++
                    }

                    if ($unload.ExitCode -ne 0) {
                        "Unable to unload Hive $hive from path $NTuserDATpath"
                    }

                    # Clean up the NTUSER.LOG files that get created when the hive is loaded
                    Write-Verbose -Message "Getting NTUser.DAT log file paths..."
                    Get-ChildItem -Path (Split-Path $NTuserDATpath -Parent) -Force |
                    Where-Object { ($PSItem.psiscontainer -eq $false) -and ($PSItem.Name -like "ntuser*") -and ($PSItem.Name -notmatch ($whereNameFilter -join "|")) } |
                    Remove-Item -Force
                }
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($PSItem)
            }
            finally {
                Write-Verbose -Message "Garbage collecting..."
                [gc]::Collect()
            }
        }
    }

    end {

    }
}
