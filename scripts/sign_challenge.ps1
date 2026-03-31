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
    
    # $StagedFiles = @(git diff --cached --name-only) -join "," # Removido por desuso (Lint)
    $ContextString = $Challenge
    $Data = [System.Text.Encoding]::UTF8.GetBytes($ContextString)
    $Signature = $RSA.SignData($Data, "SHA256")
    $B64 = [Convert]::ToBase64String($Signature)
    
    $Payload = @{
        signature = $B64
        challenge = $Challenge
        timestamp = (Get-Date).ToString("o")
    } | ConvertTo-Json -Compress
    
    $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($SigPath, $Payload, $Utf8NoBom)
    Write-Host "FIRMADO OK"
} catch {
    Write-Error "ERROR AL FIRMAR: $_"
    exit 1
}
