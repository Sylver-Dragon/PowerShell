Param(
    [Parameter(position=0, mandatory=$true)]
    [Alias('Name')]
    $ObjectName,

    [Parameter(position=1, mandatory=$true)]
    [Alias('h', 'dc')]
    $Server,

    [Parameter(position=2, mandatory=$true)]
    [Alias('b')]
    $Domain
)

$sid = [Convert]::FromBase64String(
    (ldapsearch -LLL -Q -h $Server -b $Domain -s sub "name=$ObjectName" objectSid | grep objectSid).split("::")[1].Trim()
)
# https://technet.microsoft.com/en-us/library/cc962011.aspx
# https://www.codeproject.com/Articles/303160/Converting-a-SID-in-Array-of-bytes-to-String-versi
#SID string format:
# S         -   Identifies a SID
# 1 byte    -   Revision Level
# 1 byte    -   Sub-ID Count
# 6 bytes   -   SID Identifiter Authority
# 4 bytes   -   Sub authority (repeats count times)
$sidString = New-Object System.Text.StringBuilder
$sidString.Append("S-") | Out-Null
$sidString.Append($sid[0]) | Out-Null  
$a = 0
for($i = 2; $i -lt 8; $i++) {
    $a *= 256
    $a += $sid[$i]
}
$sidString.Append("-") | Out-Null
$sidString.Append($a) | Out-Null
for($n = 0; $n -lt $sid[1]; $n++ ){
    $a = 0
    for($i = 0; $i -lt 4; $i++) {
        $a += $sid[($n * 4) + $i + 8] * [math]::Pow(2, ($i * 8))
    }   
    $sidString.Append("-") | Out-Null
    $sidString.Append($a) | Out-Null
}

Write-Output $sidString.ToString()