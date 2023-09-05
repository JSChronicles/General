function Invoke-RetryCommand {
    [CmdletBinding()]
    param (
        [parameter(Mandatory,
            ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [scriptblock] $ScriptBlock,

        [parameter(
            ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [int] $RetryCount = 3,

        [parameter(
            ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [int] $TimeoutInSecs = 10
    )

    process {
        $Attempt = 1
        $Flag = $true
        [string] $SuccessMessage = "Command executed successfuly!"
        [string] $FailureMessage = "Failed to execute the command"

        do {
            try {
                $PreviousPreference = $ErrorActionPreference
                $ErrorActionPreference = 'Stop'
                Invoke-Command -ScriptBlock $ScriptBlock -OutVariable Result
                $ErrorActionPreference = $PreviousPreference

                # flow control will execute the next line only if the command in the scriptblock executed without any errors
                # if an error is thrown, flow control will go to the 'catch' block
                Write-Verbose "$SuccessMessage"
                $Flag = $false
            }
            catch {
                if ($Attempt -gt $RetryCount) {
                    Write-Verbose "$FailureMessage! Total retry attempts: $RetryCount"
                    Write-Verbose "[Error Message] $($PSItem.exception.message) `n"
                    $Flag = $false
                }
                else {
                    Write-Verbose "[$Attempt/$RetryCount] $FailureMessage. Retrying in $TimeoutInSecs seconds..."
                    Start-Sleep -Seconds $TimeoutInSecs
                    $Attempt = $Attempt + 1
                }
            }
        }
        While ($Flag)
    }
}
