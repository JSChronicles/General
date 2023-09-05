function Get-NearestDomain {
    <#
    .SYNOPSIS
        Gets the nearest DC via lowest ping
    .DESCRIPTION
        Gets the nearest DC via lowest ping. Imports a json file
    .PARAMETER Path
        Accepts a single Json file in list format
    .PARAMETER LowestPing
        Lowest ping you are wanting to start at. Default is 30.
    .PARAMETER Count
        How many counts you want to test each connection. Default is 2.
    .INPUTS
        Description of objects that can be piped to the script.
    .OUTPUTS
        Description of objects that are output by the script.
    .EXAMPLE
        Get-NearestDomain -Path "\\server\path\DCList.json"
    .EXAMPLE
        Get-NearestDomain -Path "\\server\path\DCList.json" -LowestPing 100
    .EXAMPLE
        Get-NearestDomain -Path "\\server\path\DCList.json" -Count 10
    .EXAMPLE
        Get-NearestDomain -Path "\\server\path\DCList.json" -LowestPing 100 -Count 10
    .EXAMPLE
        Get-NearestDomain -Name ([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().DomainControllers.Name) -LowestPing 100 -Count 10
    .EXAMPLE
        Get-NearestDomain -Name "DC01","DC02" -LowestPing 100 -Count 10
    .LINK
        Links to further documentation.
    .NOTES
        Detail on what the script does, if this is needed.
    #>
    [CmdletBinding(DefaultParameterSetName = "Name")]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline,
            ParameterSetName = "Path")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
            if (-Not ($PSItem | Test-Path) ) {
                throw "File does not exist"
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

        [Parameter(Mandatory,
        ValueFromPipeline,
        ParameterSetName = "Name")]
        [string[]]$Name,

        [Parameter(
            ValueFromPipeline)]
        [ValidateRange(0,9999)]
        [int]$LowestPing = 30,

        [Parameter(
            ValueFromPipeline)]
        [ValidateRange(0,10)]
        [int]$Count = 2
    )

    begin {
        if ($PSBoundParameters.ContainsKey('Name')) {
            $DCs = $Name
        } else {
            Write-Verbose -Message "Importing $(split-path $PSBoundParameters.Path -Leaf)"
            $DCs = Get-Content $Path | ConvertFrom-Json
        }

    }

    process {
        Write-Verbose -Message "Intializing Domain Check..."
        Foreach ($DC in $DCs) {
            $ping = (Test-Connection -ComputerName $DC -Count $Count -ea SilentlyContinue | measure-Object -Property ResponseTime -Average)

            if ($ping.Average -lt $LowestPing -and $null -ne $ping.Average ) {
                $LowestPing = $ping.Average
                $nearestDomain = $DC

                if ($LowestPing -lt 13) {
                    break
                }
            }
        }
    }

    end {
        Write-Verbose -Message "Finished Domain Check"
        $nearestDomain
    }
}