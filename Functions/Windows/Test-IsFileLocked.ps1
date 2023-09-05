Function Test-IsFileLocked {
    <#
    .SYNOPSIS
        Test one or more files for locks.
    .DESCRIPTION
        Test one or more files for locks.
    .PARAMETER Path
        Path to file.
    .INPUTS
        Description of objects that can be piped to the script.
    .OUTPUTS
        Description of objects that are output by the script.
    .EXAMPLE
        Test-IsFileLocked -Path "$home\desktop\test.csv"
    .EXAMPLE
        Test-IsFileLocked -Path "$home\desktop\test.csv","$home\desktop\test2.csv"
    .EXAMPLE
        Test-IsFileLocked -Path "$home\desktop\test.csv","$home\desktop\test2.csv" -Detail
    .LINK
        Links to further documentation.
    .NOTES
        Detail on what the script does, if this is needed.
    #>
    [cmdletbinding()]
    Param (
        [parameter(Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [Alias('FullName', 'PSPath')]
        [string[]]$Path,

        [switch]$Detail
    )
    Process {

        ForEach ($Item in $Path) {

            # Ensure this is a full path
            $Item = Convert-Path $Item

            # Verify that this is a file and not a directory
            If ([System.IO.File]::Exists($Item)) {

                Try {
                    $FileStream = [System.IO.File]::Open($Item, 'Open', 'Write')
                    $FileStream.Close()
                    $FileStream.Dispose()
                    $IsLocked = $False
                }
                Catch [System.UnauthorizedAccessException] {
                    $IsLocked = 'AccessDenied'
                }
                Catch {
                    $IsLocked = $True
                }
                Finally {
                    if ($Detail) {
                        [pscustomobject]@{
                            File     = $Item
                            IsLocked = $IsLocked
                        }
                    } else {
                        $IsLocked
                    }
                }

            }

        }

    }
}
