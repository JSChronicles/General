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