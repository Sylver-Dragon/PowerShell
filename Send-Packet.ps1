Param (
    [Parameter(position=0, mandatory=$true, valuefrompipeline=$true)]
    [string]$Target,
    [Parameter(position = 1, mandatory = $false)]
    [ValidateSet([Enum]::GetNames([System.Net.Sockets.ProtocolType])]
    [string]$Protocol = "IP",
    [Parameter(position = 2, mandatory = $true)]
    [ValidateRange(0, 65535)]
    [int32]$TargetPort,
    [Parameter(position = 3, mandatory = $false)]
    [ValidateRange(0, 65535)]
    [int32]$SourcePort = (Get-Random -Minimum 0 -Maximum 65535),
    [Parameter(position = 4, mandatory = $false)]
    [int32]$Ttl = 128,
    [Parameter(position = 5, mandatory = $false)]
    [int32]$Count = 1
)

$packet = New-Object System.Net.Sockets.Socket(
    [System.Net.Sockets.AddressFamily]::InterNetwork,
    [System.Net.Sockets.SocketType]::Raw,
    [System.Net.Sockets.ProtocolType]::$Protocol
)
$packet.Ttl = $Ttl
