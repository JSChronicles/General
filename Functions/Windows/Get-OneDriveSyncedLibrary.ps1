function Get-OneDriveSyncedLibrary {
    <#
    .SYNOPSIS
        Grabs your Onedrive url, file count, and health (which is based on file count)
    .DESCRIPTION
        Grabs your Onedrive url, file count, and health (which is based on file count)
    .INPUTS
        Description of objects that can be piped to the script.
    .OUTPUTS
        Description of objects that are output by the script.
    .EXAMPLE
        Get-OneDriveSyncedLibrary
    .LINK
        https://www.cyberdrain.com/monitoring-with-powershell-monitoring-the-onedrive-client-limitations/
    .NOTES
        Detail on what the script does, if this is needed.
    #>
    [CmdletBinding()]
    Param (

    )

    begin {
        # First block to add/change stuff in
        try {
            $IniFiles = Get-ChildItem "$ENV:LOCALAPPDATA\Microsoft\OneDrive\settings\Business1" -Filter 'ClientPolicy*' -ErrorAction SilentlyContinue

            if ($null -eq $IniFiles) {
                Write-Output "No Onedrive configuration files found."
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }

    }

    process {
        try {
            $SyncedLibraries = foreach ($inifile in $IniFiles) {
                $iniContent = Get-Content $inifile.fullname -Encoding Unicode
                [PSCustomObject]@{
                    Name  = ($iniContent.Where({ $PSItem -like 'SiteTitle*' }) -split '= ') | Select-Object -Last 1
                    URL   = ($iniContent.Where({ $PSItem -like 'DavUrlNamespace*' }) -split '= ') | Select-Object -Last 1
                    Count = ($iniContent.Where({ $PSItem -like 'ItemCount*' }) -split '= ') | Select-Object -Last 1
                }
            }

            $Health = if (($SyncedLibraries.Count | Measure-Object -Sum).sum -gt '280000') { "Unhealthy" } else { "Healthy" }
            $SyncedLibraries | Add-Member -Name 'Health' -Value $Health -MemberType NoteProperty

            $SyncedLibraries
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }

    end {

    }
}
