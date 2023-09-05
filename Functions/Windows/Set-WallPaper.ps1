function Set-WallPaper {
    <#
    .SYNOPSIS
        Sets the wallpaper and its style.
    .DESCRIPTION
        Sets the wallpaper and its style.
    .PARAMETER Path
        File path to a single image. The file specified in the path argument must be JPG, JPEG, BMP, DIB, PNG, JFIF, JPE, GIF, TIF, TIFF, or WDP
    .PARAMETER WallpaperStyle
        Style that you want the wallpaper to be. Must be 'Fill', 'Fit', 'Stretch', 'Center', 'Tile', or 'Span'
    .INPUTS
        Description of objects that can be piped to the script.
    .OUTPUTS
        Description of objects that are output by the script.
    .EXAMPLE
        Set-WallPaper -Path "\\server\path\chosen.jpg"
    .EXAMPLE
        Set-WallPaper -Path "\\server\path\chosen.jpg" -WallpaperStyle 'Center'
    .EXAMPLE
        Set-WallPaper -Path "\\server\path\chosen.jpg" -WallpaperStyle 'Center' -Whatif
    .LINK
        Links to further documentation.
    .NOTES
        Detail on what the script does, if this is needed.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
            if (-Not ($PSItem | Test-Path) ) {
                throw "File does not exist"
            }
            if (-Not ($PSItem | Test-Path -PathType Leaf) ) {
                throw "The path argument must be a file. Folder paths are not allowed."
            }
            if ($PSItem -notmatch "(\.JPG|\.JPEG|\.BMP|\.DIB|\.PNG|\.JFIF|\.JPE|\.GIF|\.TIF|\.TIFF|\.WDP)") {
                throw "The file specified in the path argument must be JPG, JPEG, BMP, DIB, PNG, JFIF, JPE, GIF, TIF, TIFF, or WDP"
            }
            return $true
        })]
        [string]$Path,

        [ValidateSet('Fill', 'Fit', 'Stretch', 'Center', 'Tile', 'Span')]
        [string]$WallpaperStyle = 'Fill'
    )

    begin {

        Write-Output "Setting Background..."

        Add-Type -TypeDefinition '
            using System;
            using System.Runtime.InteropServices;
            using Microsoft.Win32;
            namespace Wallpaper {
                public class Setter {
                    public const int SetDesktopWallpaper = 20;
                    public const int UpdateIniFile       = 0x01;
                    public const int SendWinIniChange    = 0x02;
                    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
                    private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
                    public static void SetWallpaper ( string path ) {
                        SystemParametersInfo( SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange );
                    }
                }
            }
        '
        #remove cached files to help change happen
        #Remove-Item -Path "$($env:APPDATA)\Microsoft\Windows\Themes\CachedFiles" -Recurse -Force -ErrorAction SilentlyContinue

        $fit = @{ 'Fill' = 10; 'Fit' = 6; 'Stretch' = 2; 'Center' = 0; 'Tile' = '99'; 'Span' = '22' }

    }

    process {
        if ($WallpaperStyle -eq 'Tile') {
            Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name WallpaperStyle -value 0;
            Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name TileWallpaper -value 1;
        } else {
            Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name WallpaperStyle -value $fit[$WallpaperStyle];
            Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name TileWallpaper -value 0;
        }
    }

    end {
        if ($PSCmdlet.ShouldProcess("Item: Wallpaper to $Path",'Setting')){
            [Wallpaper.Setter]::SetWallpaper($Path);
        }
    }
}
