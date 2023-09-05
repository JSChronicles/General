function Get-WindowsBuildHistory {
    <#
    .SYNOPSIS
        Gather the build history of a Windows OS
    .DESCRIPTION
        When building an image sometimes it's best to keep track of how many upgrades an image has gone through.
        You may want to consider rebuilding an image from scratch if the image itself has been upgraded a few times.
        This is to start as clean as possible and reduce leftovers and potential issues for a person. Please be aware that
        this was not tested on W11.
    .INPUTS
        Description of objects that can be piped to the script.
    .OUTPUTS
        Description of objects that are output by the script.
    .EXAMPLE
        Get-WindowsBuildHistory
    .LINK
        Links to further documentation.
    .NOTES
        Detail on what the script does, if this is needed.
    #>
    [CmdletBinding()]
    Param (

    )

    begin {

        try {
            $builds = @(
                @{Name = "UpdateTime"; Expression = { if ($PSItem.Name -match "Updated\son\s(\d{1,2}\/\d{1,2}\/\d{4}\s\d{2}:\d{2}:\d{2})\)$") { [dateTime]::Parse($Matches[1], ([Globalization.CultureInfo]::CreateSpecificCulture('en-US'))) } } },
                @{Name = "ReleaseID"; Expression = { $PSItem.GetValue("ReleaseID") } }, @{Name = "Branch"; Expression = { $PSItem.GetValue("BuildBranch") } },
                @{Name = "Build"; Expression = { $PSItem.GetValue("CurrentBuild") } }, @{Name = "ProductName"; Expression = { $PSItem.GetValue("ProductName") } },
                @{Name = "InstallTime"; Expression = { [datetime]::FromFileTime($PSItem.GetValue("InstallTime")) } }
            )
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }

    }

    process {

        try {

            $AllBuilds = $(Get-ChildItem "HKLM:\System\Setup" | Where-Object { $PSItem.Name -match "\\Source\s" }) |
            ForEach-Object { $PSItem | Select-Object $builds }

            if (($AllBuilds).count -gt 2) {
                Write-Warning -Message "Image has been upgraded more than 2 times. Consider rebuilding the entire image. [TotalUpgrades:$($AllBuilds.count)]"
                $AllBuilds | Sort-Object UpdateTime | Format-Table UpdateTime, Build, ReleaseID, Branch, ProductName
            }

        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }

    end {

    }
}