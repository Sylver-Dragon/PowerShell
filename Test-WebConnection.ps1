[CmdletBinding(DefaultParametersetName="Download")]
Param 
(
    [Parameter(position=0, mandatory=$true)]
    [string]$Uri,
    [Parameter(position=1, mandatory=$false, ParameterSetName="Download")]
    [ValidateScript({if($_ -ne $null){Test-Path (Split-Path $_)}else{$true}})]
    [string]$DownloadPath,
    [Parameter(mandatory=$false)]
    [Uint]$Timeout = 10000,
    [Parameter(mandatory=$false)]
    [PSCredential]$Credential,
    [switch]$Certificate,
    [switch]$CurrentUser,
    [switch]$Options,
    [switch]$Proxy,
    [Parameter(mandatory=$false, ParameterSetName="WebDAV")]
    [switch]$WebDav,
    [Parameter(mandatory=$false, ParameterSetName="WebDAV")]
    [ValidateSet(0, 1, "infinity")]
    $Depth = 0,
    [Parameter(mandatory=$false, ParameterSetName="WebDAV")]
    $Verb = "PROPFIND",
    [Parameter(mandatory=$false, ParameterSetName="WebDAV")]
    $Properties = @("allprop")
)

$WebReq = [System.Net.WebRequest]::Create($Uri)

# Get Client Certificate
if ($Certificate) 
{
    $TryAgain = $true
    while($TryAgain) 
    {
        Clear-Host
        $Certs = (Get-ChildItem -Path Cert:CurrentUser\My)
        For($i = 0; $i -lt $Certs.Length; $i++)
        {
            Write-Host ("[{0}] - {1}" -f $i.ToString(), $Certs[$i].FriendlyName)
        }
        $Choice = Read-Host -Prompt ("Use which certificate (leave blank to quit)[0-{0}]" -f ($i.ToString() - 1))
        $Pattern = ("^[0-{0}]" -f {if ($i -gt 9){"9"}else{$i.ToString()}}) + "{1,2}$"
        if ([RegEx]::IsMatch($Choice, $Pattern)) 
        {
            $TryAgain = $false
            $WebReq.ClientCertificates.Add($Certs[$Choice]) | Out-Null
            $WebReq.PreAuthenticate = $true
        }
    }
} elseif($Credential -notlike $null) 
{
    $WebReq.Credentials = $Credential
    $WebReq.PreAuthenticate = $true
} elseif($CurrentUser) 
{
    $WebReq.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
    $WebReq.PreAuthenticate = $true
}

# Proxy login
if($Proxy) {
    $WebReq.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
}

# WebDAV connection
if($WebDav) {
<#
See:
 http://www.webdav.org/specs/rfc2518.html 
 Section 13 for properties list
#>
    switch ($Verb) 
    {
        "PROPFIND" 
        {
            $XmlRequest = New-Object System.Xml.XmlDataDocument
            $XmlNsm = New-Object System.Xml.XmlNamespaceManager($XmlRequest.NameTable)
            $XmlNsm.AddNamespace([String].Empty, "DAV:") | Out-Null
            $Propfind = $XmlRequest.CreateElement("propfind", $XmlNsm.DefaultNamespace)
            $XmlRequest.AppendChild($Propfind) | Out-Null
            switch ($Properties[0])
            {
                "ALLPROP" 
                {
                    $Propfind.AppendChild($XmlRequest.CreateElement("allprop", $XmlNsm.DefaultNamespace)) | Out-Null
                }
                "PROPNAME" 
                {
                    $Propfind.AppendChild($XmlRequest.CreateElement("propname", $XmlNsm.DefaultNamespace)) | Out-Null
                }
                default 
                {
                    $Prop = $XmlRequest.CreateElement("prop", $XmlNsm.DefaultNamespace)
                    $Propfind.AppendChild($prop) | Out-Null
                    foreach($Property in $Properties)
                    {
                        $Prop.AppendChild($XmlRequest.CreateElement($Property, $XmlNsm.DefaultNamespace)) | Out-Null
                    }                    
                }
            }
        }
    }

    $RequestBytes = [System.Text.Encoding]::UTF8.GetBytes($XmlRequest.OuterXml)
    $WebReq.Method = $Verb
    $WebReq.ContentType = "application/xml"
    $WebReq.ContentLength = $RequestBytes.Length
    $webreq.Headers.Add("Depth", $Depth.ToString())
    $ReqStream = $WebReq.GetRequestStream()
    $ReqStream.Write($RequestBytes, 0, $RequestBytes.Length)
    $ReqStream.Close()    
}

# Use OPTIONS verb
if($Options) {
    $WebReq.Method = "OPTIONS"
}

# Connect
$Response = $WebReq.GetResponse()

# Get and parse response
if($Response.StatusCode -eq [System.Net.HttpStatusCode]::OK -or
    $Response.StatusCode -like 207) 
{
    $ResponseStream = $Response.GetResponseStream()
    # File Download
    if($DownloadPath -ne $null)
    {
        try 
        {
            $File = [System.IO.File]::Create($DownloadPath)
            $totalCount = 0
            $startTime = [DateTime]::Now
            if($Response.ContentType -like "application/*") {
                $bytes = New-Object byte[] 4096
                do {
                    $count = $ResponseStream.Read($bytes, 0, $bytes.Length)
                    $File.Write($bytes, 0, $count)
                    $totalCount += $count
                    if($count -eq 0 -and $totalCount -lt $Response.ContentType) {
                        Start-Sleep -Milliseconds 100
                    }
                } while ($totalCount -lt $Response.ContentLength -AND
                         ([DateTime]::Now - $startTime).TotalMilliseconds -lt $Timeout)
                Write-Verbose ("Total byte count: {0}" -f $totalCount.ToString())
            }            
        }
        catch
        {
            Throw "An Error occured while saving the stream"
        }
        finally
        {
            $File.Close()
            $ResponseStream.Close()
        }
    }
    elseif($Options) {
        Write-Output $Response
    }
    else
    {   
        try 
        {
            
            $StreamReader = New-Object System.IO.StreamReader($ResponseStream, [System.Text.Encoding]::UTF8)
            $ResponseText = $StreamReader.ReadToEnd()
        }
        catch
        {
            Throw "Unable to read stream"
        }
        finally
        {
            $ResponseStream.Close()
        }
        Write-Output $ResponseText
    }
}
else
{
    Write-Host ("Error while getting web response: {0}" -f $Response.StatusCode)
    Write-output $Response.Header
}

# Cleanup
if($Response -notlike $null) {
    $Response.Close()
}