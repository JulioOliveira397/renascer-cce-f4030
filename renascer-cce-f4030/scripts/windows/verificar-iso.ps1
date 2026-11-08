<#
.SYNOPSIS
    Confere o SHA-256 de uma ISO antes de gravá-la no pendrive.
.DESCRIPTION
    Compara o hash calculado com o hash oficial (colado à mão ou lido do
    sha256sum.txt publicado pela distribuição). Garante que a ISO não está
    corrompida nem adulterada (cadeia de confiança de software).
.EXAMPLE
    .\verificar-iso.ps1 -Iso .\linuxmint-22.3-xfce-64bit.iso -HashOficial 0123abcd...
.EXAMPLE
    .\verificar-iso.ps1 -Iso .\linuxmint-22.3-xfce-64bit.iso -ArquivoSha256 .\sha256sum.txt
.NOTES
    Projeto Renascer CCE F4030 - Julio Oliver
    Ideal: verificar também a assinatura GPG do sha256sum.txt (sha256sum.txt.gpg).
#>
param(
    [Parameter(Mandatory)] [string] $Iso,
    [string] $HashOficial,
    [string] $ArquivoSha256
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Iso -PathType Leaf)) { throw "ISO não encontrada: $Iso" }
$nome = Split-Path $Iso -Leaf

if (-not $HashOficial) {
    if (-not $ArquivoSha256) { throw "Informe -HashOficial ou -ArquivoSha256." }
    $linha = Get-Content -LiteralPath $ArquivoSha256 |
             Where-Object { $_ -match [regex]::Escape($nome) } | Select-Object -First 1
    if (-not $linha) { throw "'$nome' não aparece em $ArquivoSha256." }
    $HashOficial = ($linha -split '\s+')[0]
}

$HashOficial = $HashOficial.Trim()
if ($HashOficial -notmatch '^[0-9a-fA-F]{64}$') { throw "Hash oficial inválido (esperado: 64 caracteres hexadecimais)." }

Write-Host "Calculando SHA-256 de $nome (pode demorar)..."
$calculado = (Get-FileHash -LiteralPath $Iso -Algorithm SHA256).Hash

Write-Host "Oficial  : $($HashOficial.ToUpper())"
Write-Host "Calculado: $calculado"

if ($calculado -ieq $HashOficial) {
    Write-Host "`n[OK] ISO íntegra. Pode gravar." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n[FALHA] Hash diferente. NÃO grave esta ISO; baixe novamente de fonte oficial." -ForegroundColor Red
    exit 2
}
