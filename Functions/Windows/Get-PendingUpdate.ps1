Function Get-PendingUpdate {
    <#
    .SYNOPSIS
        Get pending WSUS updates.
    .DESCRIPTION
        Get pending WSUS updates and output a detailed object.
    .PARAMETER ComputerName
        Computer you wish to connect to for setting the chosen power plan.
    .INPUTS
        Description of objects that can be piped to the script.
    .OUTPUTS
        CimInstance
    .EXAMPLE
        Get-PendingUpdate
    .EXAMPLE
        Get-PendingUpdate -ComputerName "NameHere"
    .LINK
        Links to further documentation.
    .NOTES
        Detail on what the script does, if this is needed.
    #>
    #Requires -version 3.0
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )
    Process {
        ForEach ($computer in $ComputerName) {
            try {
                If (Test-Connection -ComputerName $computer -Count 1 -Quiet) {

                    Write-Verbose "Creating COM object for WSUS Session"
                    $updatesession = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session", $computer))

                    Write-Verbose "Creating COM object for WSUS update Search"
                    $updatesearcher = $updatesession.CreateUpdateSearcher()

                    Write-Verbose "Searching for WSUS updates on client"
                    $searchresult = $updatesearcher.Search("IsInstalled=0")

                    Write-Verbose "Verifing that updates are available to install"
                    If ($searchresult.Updates.Count -gt 0) {

                        Write-Verbose "Found $($searchresult.Updates.Count) update\s!"

                        # Cache the count to make the For loop run faster
                        $count = $searchresult.Updates.Count

                        Write-Verbose "Iterating through list of updates"
                        For ($i = 0; $i -lt $Count; $i++) {

                            $Update = $searchresult.Updates.Item($i)
                            [pscustomobject]@{
                                Computername     = $Computer
                                Title            = $Update.Title
                                KB               = $Update.KBArticleIDs
                                SecurityBulletin = $Update.SecurityBulletinIDs
                                MsrcSeverity     = $Update.MsrcSeverity
                                IsDownloaded     = $Update.IsDownloaded
                                Url              = $Update.MoreInfoUrls
                                Categories       = $Update.Categories | Select-Object -ExpandProperty Name
                                BundledUpdates   = $Update.BundledUpdates | ForEach-Object {
                                    [pscustomobject]@{
                                        Title       = $PSItem.Title
                                        DownloadUrl = @($PSItem.DownloadContents).DownloadUrl
                                    }
                                }
                            }

                        }
                    }
                    Else {
                        Write-Verbose "No updates to install."
                    }
                }
                Else {
                    Write-Warning "$($computer): Offline"
                }
            }
            Catch {
                Write-Error -Message $PsItem
                Break
            }
        }
    }
}