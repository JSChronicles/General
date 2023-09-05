function Get-ADSystemInfo {
	<#
	.SYNOPSIS
		Get following from local computer: UserName, ComputerName, SiteName, DomainShortName, DomainDNSName, ForestDNSName, PDCRoleOwner, SchemaRoleOwner, IsNativeMode
	.DESCRIPTION
		This script gets the attributes from the ADSystemInfo com object.
	.INPUTS
		Description of objects that can be piped to the script.
	.OUTPUTS
		Description of objects that are output by the script.
	.EXAMPLE
		Get-ADSystemInfo
	.LINK
		https://technet.microsoft.com/en-us/library/ee198776.aspx
	.NOTES
		Detail on what the script does, if this is needed.
	#>
	[CmdletBinding()]

	Param (
	)

	begin {

		# First block to add/change stuff in
		try {
			$properties = @(
				'UserName',
				'ComputerName',
				'SiteName',
				'DomainShortName',
				'DomainDNSName',
				'ForestDNSName',
				'PDCRoleOwner',
				'SchemaRoleOwner',
				'IsNativeMode'
			)
			$adsi = New-Object -ComObject ADSystemInfo
			$type = $adsi.GetType()
			$hash = @{}
		}
		catch {
			$PSCmdlet.ThrowTerminatingError($PSitem)
		}

	}

	process {

		try {
			foreach ($property in $properties) {
				$hash.Add($property, $type.InvokeMember($property, 'GetProperty', $Null, $adsi, $Null))
			}

			[pscustomobject]$hash
		}
		catch {
			$PSCmdlet.ThrowTerminatingError($PSitem)
		}
		finally {
			[void]([System.Runtime.Interopservices.Marshal]::ReleaseComObject($adsi))
			[System.GC]::Collect()
			[System.GC]::WaitForPendingFinalizers()
		}
	}

	end {

	}
}
