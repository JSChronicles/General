function Export-ChromeBookMark {
    <#
    .SYNOPSIS
        Export Google Chrome Bookmarks
    .DESCRIPTION
        Function to create a false html header and export google chrome bookmarks
    .PARAMETER Path
        Path to Chrome bookmarks
    .INPUTS
        Description of objects that can be piped to the script.
    .OUTPUTS
        HTML file on the desktop of the current user. HTML has all the current Google Chrome bookmarks.
    .EXAMPLE
        Example of how to run the script.
    .LINK
        Stolen from https://community.spiceworks.com/topic/2123065-export-chrome-bookmarks-as-html
    .NOTES
        Detail on what the script does, if this is needed.
    #>
    [CmdletBinding()]
    param (

        $Path = "$env:localappdata\Google\Chrome\User Data\Default\Bookmarks"
    )

    begin {
        $exportPath = "$home\desktop\ChromeBookmarks.html"

        #Path to chrome bookmarks
        $htmlHeader = @'
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<!--This is an automatically generated file.
    It will be read and overwritten.
    Do Not Edit! -->
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<Title>Bookmarks</Title>
<H1>Bookmarks</H1>
<DL><p>
'@

        $htmlHeader | Out-File -FilePath $exportPath -Force -Encoding utf8 #line59

    }

    process {
        Function Get-BookmarkFolder {
            [cmdletbinding()]
            Param(
                [Parameter(Position = 0, ValueFromPipeline = $True)]
                $Node
            )

            Process {

                foreach ($child in $node.children) {
                    $da = [math]::Round([double]$child.date_added / 1000000) #date_added - from microseconds (Google Chrome {dates}) to seconds 'standard' epoch.
                    if ($child.type -eq 'Folder') {
                        "    <DT><H3 FOLDED ADD_DATE=`"$($da)`">$($child.name)</H3>" | Out-File -FilePath $exportPath -Append -Force -Encoding utf8
                        "       <DL><p>" | Out-File -FilePath $exportPath -Append -Force -Encoding utf8
                        Get-BookmarkFolder $child
                        "       </DL><p>" | Out-File -FilePath $exportPath -Append -Force -Encoding utf8
                    }
                    else {
                        "       <DT><a href=`"$($child.url)`" ADD_DATE=`"$($da)`">$($child.name)</a>" | Out-File -FilePath $exportPath -Append -Encoding utf8
                    }
                }
            }
        }

        # A nested function to enumerate bookmark folders
        $data = Get-content $Path -Encoding UTF8 | out-string | ConvertFrom-Json
        $sections = $data.roots.PSObject.Properties | Select-Object -ExpandProperty name
        ForEach ($entry in $sections) {
            $data.roots.$entry | Get-BookmarkFolder
        }
        '</DL>' | Out-File -FilePath $exportPath -Append -Force -Encoding utf8


    }

    end {
    }
}
