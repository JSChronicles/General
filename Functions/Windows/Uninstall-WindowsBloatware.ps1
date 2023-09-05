function Uninstall-WindowsBloatware {
    <#
    .SYNOPSIS
        A brief description of the function or script.
    .DESCRIPTION
        A longer description.
    .PARAMETER Path
        Accepts a single Json file in list format
    .PARAMETER LogPath
        Path of the logfile you want it to log to. Default is C:\Temp.
    .INPUTS
        Description of objects that can be piped to the script.
    .OUTPUTS
        Description of objects that are output by the script.
    .EXAMPLE
        Example of how to run the script.
    .LINK
        Links to further documentation.
    .NOTES
        Detail on what the script does, if this is needed.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
            if (-Not ($PSItem | Test-Path) ) {
                throw "File or folder does not exist"
            }
            if (-Not ($PSItem | Test-Path -PathType Leaf) ) {
                throw "The path argument must be a file. Folder paths are not allowed."
            }
            if ($PSItem -notmatch "(\.json)") {
                throw "The file specified in the path argument must be .json"
            }
            return $true
        })]
        [string]$Path,

        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [String]$LogPath = "C:\Temp"

    )
    begin {
        $ProgressPreference = "SilentlyContinue"

        $logger.Notice("Starting $($MyInvocation.MyCommand) script")

        if ($PSBoundParameters.Keys.Contains("Path") ) {
            $logger.Informational("Importing $(split-path $PSBoundParameters.Path -Leaf)")
            $apps = Get-Content $Path | ConvertFrom-Json
        }

    }

    process {
        Write-Verbose -Message "Initiating Windows 10 Bloatware Removal..."
        foreach ($app in $apps) {
            $package = Get-AppxPackage -Name $app -AllUsers
            try {
                if ($null -ne $package) {

                    $package | Remove-AppxPackage -ErrorAction SilentlyContinue
                    if ($PSCmdlet.ShouldProcess("Item: $app",'Remove AppxProvisionedPackage')){
                        (Get-AppXProvisionedPackage -Online).Where( { $PSItem.DisplayName -EQ $app }) | Remove-AppxProvisionedPackage -Online
                    }

                    $appPath = "$Env:LOCALAPPDATA\Packages\$app*"

                    $logger.Informational("Removing $appPath")
                    Remove-Item $appPath -Recurse -ErrorAction SilentlyContinue
                }
            }
            catch {
                $logger.Informational("$PSItem.Exception.Message the $app app had an issue uninstalling")
                Write-Error -Message "$($PSItem.Exception.Message) the $app app had an issue uninstalling"
            }
        }
    }
    end {
        $ProgressPreference = $OriginalPref
        Write-Verbose -Message "Finished Windows 10 Bloatware Removal"
        $logger.Notice("Finished $($MyInvocation.MyCommand) script")
    }
}
