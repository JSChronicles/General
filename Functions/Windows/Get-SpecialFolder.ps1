function Get-SpecialFolder {
    <#
    .SYNOPSIS
        Output both the special folder name and location.
    .DESCRIPTION
        Get and output both the special folder name and location.
    .PARAMETER Name
        Name of the special folder you wish to find.
    .INPUTS
        Description of objects that can be piped to the script.
    .OUTPUTS
        Object containing Name and Path of the special folder
    .EXAMPLE
        Get-SpecialFolder
    .EXAMPLE
        Get-SpecialFolder -Name "desktop"
    .LINK
        Links to further documentation.
    .NOTES
        Detail on what the script does, if this is needed.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(
            Position = 0,
            ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    begin {
        # First block to add/change stuff in
        try {
            $specialFolder = [System.Enum]::GetNames([System.Environment+SpecialFolder])
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }

    }

    process {

        try {
            if ($PSBoundParameters.ContainsKey('Name')) {
                [PSCustomObject]@{
                    Name = $specialFolder -eq $PSBoundParameters['Name']
                    Path =  [System.Environment]::GetFolderPath($PSBoundParameters['Name'])
                }

            } else {
                $folderTable = foreach ($folder in $specialFolder) {
                    [PSCustomObject]@{
                        Name = $folder
                        Path =  [System.Environment]::GetFolderPath($folder)
                    }
                }
            }
            $folderTable
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }

    end {

    }
}
