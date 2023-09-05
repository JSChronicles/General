function Get-SearchIndexStatus {
    <#
    .SYNOPSIS
        Obtain the current users search index status.
    .DESCRIPTION
        On a typical user's computer, the Indexer indexes fewer than 30,000 items. On a power user's computer, the Indexer might index up to 300,000 items.
        If the Indexer indexes more than 400,000 items, you may begin to see performance issues.
        The Indexer can index up to 1 million items. If the Indexer tries to index beyond that limit,
        it may fail or cause resource problems on the computer (such as high usage of CPU, memory, or disk space).
    .INPUTS
        Description of objects that can be piped to the script.
    .OUTPUTS
        Description of objects that are output by the script.
    .EXAMPLE
        Get-SearchIndexStatus
    .LINK
        https://docs.microsoft.com/en-us/troubleshoot/windows-client/shell-experience/windows-search-performance-issues
        https://blog.ironmansoftware.com/daily-powershell/powershell-windows-search-index-status/#next-steps
        https://github.com/ironmansoftware/searchindex
    .NOTES
        By default, the Indexer indexes any Outlook mailboxes on the computer.
        If a mailbox contains more than 6 million items, the performance of the Indexer may degrade.
    #>
    [CmdletBinding()]
    Param (

    )

    begin {

        # First block to add/change stuff in
        try {
            <#
            $sql = "SELECT System.ItemName, System.DateCreated FROM SYSTEMINDEX"
            $provider = "provider=search.collatordso;extended properties='application=windows';"
            $connector = [system.data.oledb.oledbdataadapter]::new($sql, $provider)
            $dataset = [system.data.dataset]::new()
            $index = if ($connector.fill($dataset)) { $dataset.tables[0] }
            $count = ($index | Measure-Object).count

            Dim status As _CatalogStatus
            Dim reason As _CatalogPausedReason
            Dim manager As CSearchManager = New CSearchManager()
            Dim catalogManager As ISearchCatalogManager = manager.GetCatalog("SystemIndex")
            catalogManager.GetCatalogStatus(status, reason)
            #>

            <#
            $status = "_CatalogStatus"
            $reason = "_CatalogPausedReason"
            $manager = New-Object CSearchManager = New CSearchManager()
            $catalogManager = New-Object ISearchCatalogManager = manager.GetCatalog("SystemIndex")

            #>

            try {
                $objConn = [System.Data.OleDb.OleDbConnection]::new("Provider=Search.CollatorDSO;Extended Properties='Application=Windows'")
                $sqlCommand = [System.Data.OleDb.OleDbCommand]::new("GROUP ON workid [0] AGGREGATE COUNT() as 'Total' OVER (SELECT workid FROM systemindex)")
                $sqlCommand.Connection = $objConn
                $objConn.open()
                $reader = $sqlCommand.ExecuteReader()
                try {
                    # Will cause an error but we can ignore it... without this we won't have data
                    [void]($reader.Read())
                }
                catch {
                    $PSCmdlet.ThrowTerminatingError($PSitem)
                }
                $count = $reader[2]

            }
            catch {
                $PSCmdlet.ThrowTerminatingError($PSitem)
            }

            $explanation = @{
                "Indexing complete"                                                                   = "The Indexer is running as usual, and has finished indexing."
                "Indexing in progress. Search results might not be complete during this time."        = "The Indexer has found new files on the system and is adding them to the index. Depending on the number of files that have recently changed, it could take a few hours"
                "Indexing speed is reduced because of user activity."                                 = "The Indexer is adding new items to be searched, but has slowed its progress because the user is interacting with the device."
                "Indexing is waiting for computer to become idle."                                    = "The Indexer has detected items that have to be indexed, but the device is too busy for the indexing process to continue."
                "Indexing is paused to conserve battery power."                                       = "The Indexer has stopped adding new items to the index because of low battery power. Search results may not be complete."
                "Your group policy is set to pause indexing while on battery power."                  = "Your IT department has configured the Indexer pause while the device uses battery power."
                "Indexing is paused."                                                                 = "The Indexer has been paused from the Windows Search settings page."
                "Indexing is not running."                                                            = "Indexer hasn't started or is disabled."
                "Insufficient memory to continue indexing. Search results might not be complete."     = "The Indexer detected a low memory state and stopped to preserve the user experience."
                "Insufficient disk space to continue indexing. Search results might not be complete." = "There's not enough space on the disk to continue indexing. The Indexer stops before it fills the entire disk. The index is generally 10 percent of the size of the content that is being indexed."
                "Waiting the receive indexing status..."                                              = "The Indexer hasn't replied to the status query."
                "Indexing is starting up."                                                            = "The Indexer is starting."
                "Indexing is shutting down."                                                          = "The Indexer has received the signal to shut down either because the operating system is shutting down or because the user requested it."
                "Index is performing maintenance. Please wait."                                       = "The Indexer is trying to recover and optimize the index database. It could occur because lots of content was added recently, or because the Indexer encountered a problem while writing out data to the hard disk."
                "Indexing is paused by an external application."                                      = "An application on the computer requested the Indexer to stop. It commonly occurs during Game mode or during an upgrade."
                "The status message is missing, and the entire page is greyed out."                   = "Something has corrupted the Indexer registry keys or database. The service can no longer start or report status."
            }

            # diagnostic
            # msdt.exe -ep SystemSettings_Troubleshoot_L2 -id SearchDiagnostic
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }

    process {

        try {
            if ($count -lt 400000) {
                $health = "healthy"
            }
            elseif ($count -ge 400000 -and $count -lt 1000000) {
                $health = "degraded"
            }
            elseif ($count -ge 1000000) {
                $health = "Unhealthy"
            }

            [PSCustomObject]@{
                Status      = $status
                Explanation = $explanation[$status]
                Count       = $count
                Health      = $health
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }

    end {

    }
}