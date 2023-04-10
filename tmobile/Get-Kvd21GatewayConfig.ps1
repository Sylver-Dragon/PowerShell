function Get-Kvd21GatewayConfig {
    Param (
        [Parameter(position = 0, mandatory = $false)]
        [string]
        [ValidatePattern("[h|H][t|T][t|T][p|P][s|S]?://\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}")]
        $Server = "http://192.168.12.1",
        [Parameter(position = 1, mandatory = $false)]
        [Alias("Username", "Identity")]
        [string]
        $User = "admin",
        [Parameter(position = 2, mandatory = $true)]
        [string]
        $Password,
        [Parameter(position = 3, mandatory = $false)]
        #[ValidateSet("all", "signal")]
        [string]
        $Request = "all"
    )

    $session = [GUID]::NewGuid().Guid
    if($Server[-1] -ne '/') {
        $Server = $Server + '/'
    }
    $connectParams = @{
        Uri = $Server + "TMI/v1/auth/login"
        Method = "Post"
        Body = "{`"username`": `"$User`", `"password`": `"$Password`"}"

    }
    #curl -s -d "${auth_payload}" http://192.168.12.1/TMI/v1/auth/login | jq -r ".auth.token")
    
    $token = Invoke-RestMethod @connectParams
    $header = @{
        Authorization = "Bearer $($token.auth.token)"
    }
    $connectParams = @{
        Uri = $Server + "TMI/v1/gateway?get=$Request"
        Method = "Get"
        Headers = $header
    }

    $config = Invoke-RestMethod @connectParams
    return $config
}