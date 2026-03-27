param(
    [string]$Challenge,
    [string]$KeyPath
)

$IntelDir = "$PSScriptRoot/../vault/intel"
$SigPath = "$IntelDir/signature.json"

if (!(Test-Path $KeyPath)) { exit 1 }

try {
    $RSA = New-Object System.Security.Cryptography.RSACryptoServiceProvider
    $XML = Get-Content $KeyPath -Raw
    $RSA.FromXmlString($XML)
    
    $StagedFiles = @(git diff --cached --name-only) -join ","
    $ContextString = $Challenge
    $Data = [System.Text.Encoding]::UTF8.GetBytes($ContextString)
    $Signature = $RSA.SignData($Data, "SHA256")
    $B64 = [Convert]::ToBase64String($Signature)
    
    $Payload = @{
        signature = $B64
        challenge = $Challenge
        timestamp = (Get-Date).ToString("o")
    } | ConvertTo-Json
    
    $Payload | Set-Content $SigPath -Encoding UTF8
    Write-Host "FIRMADO OK"
} catch {
    Write-Error "ERROR AL FIRMAR: $_"
    exit 1
}
