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