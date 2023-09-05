function Write-ProgressHelper {
	<#
    .SYNOPSIS
        A brief description of the function or script.
    .DESCRIPTION
        A longer description.
    .PARAMETER StepNumber
        Description of each of the parameters.
        Note:
        To make it easier to keep the comments synchronized with changes to the parameters,
        the preferred location for parameter documentation comments is not here,
        but within the param block, directly above each parameter.
    .PARAMETER Activity
        Description of each of the parameters.
    .PARAMETER Status
        Description of each of the parameters.
    .INPUTS
        Description of objects that can be piped to the script.
    .OUTPUTS
        Description of objects that are output by the script.
    .EXAMPLE
        $script:steps = ([System.Management.Automation.PsParser]::Tokenize((Get-Content "$PSScriptRoot\$($MyInvocation.MyCommand.Name)"), [ref]$null) | Where-Object { $PSItem.Type -eq 'Command' -and $PSItem.Content -eq 'Write-ProgressHelper' }).Count
        $stepCounter = 0
        Write-ProgressHelper -Activity "Building Params..." -status "Progress:" -StepNumber ($script:stepCounter++)
    .LINK
        Links to further documentation.
    .NOTES
        Detail on what the script does, if this is needed.
    #>
	param (
		[int]$StepNumber,
		[string]$Activity = "N/A",
		[string]$Status = "N/A"
		#[switch]$Tokenize = $false
	)

	Write-Progress -Activity $Activity -Status $Status -PercentComplete (($StepNumber / $steps) * 100)
}
