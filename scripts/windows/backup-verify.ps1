<#
.SYNOPSIS
    Gera um manifesto SHA-256 de uma pasta (caminho relativo, tamanho, hash).
.DESCRIPTION
    O manifesto é a "prova" do backup: depois de restaurar em qualquer sistema,
    o verificar-manifesto.py confere arquivo por arquivo.
    Antes de começar, mostra a tabela "Cabe?" com o espaço livre de cada disco
    em relação ao tamanho da origem (lição do incidente 2).
.PARAMETER Origem
    Pasta a ser inventariada.
.PARAMETER Manifesto
    Caminho do CSV de saída.
.EXAMPLE
    .\backup-verify.ps1 -Origem "D:\Backup" -Manifesto "D:\manifesto.csv"
.NOTES
    Projeto Renascer CCE F4030 - Julio Oliveira
    O manifesto contém nomes de arquivos: NÃO publique o CSV.
#>
param(
    [Parameter(Mandatory)] [string] $Origem,
    [Parameter(Mandatory)] [string] $Manifesto
)

$ErrorActionPreference = 'Stop'
$log = [IO.Path]::ChangeExtension($Manifesto, '.log')
Start-Transcript -Path $log | Out-Null

trap {
    Write-Host "`n[ERRO] $($_.Exception.Message)" -ForegroundColor Red
    Stop-Transcript | Out-Null
    Read-Host "Pressione Enter para sair"
    exit 1
}

# --- Validação de entradas (lição do incidente 4) ---
if ([string]::IsNullOrWhiteSpace($Origem)) { throw "Origem vazia." }
if (-not (Test-Path -LiteralPath $Origem -PathType Container)) { throw "Origem não existe: $Origem" }
$Origem = (Resolve-Path -LiteralPath $Origem).Path.TrimEnd('\')

$arquivos = @(Get-ChildItem -LiteralPath $Origem -Recurse -File -Force -ErrorAction SilentlyContinue)
if ($arquivos.Count -eq 0) { throw "Nenhum arquivo encontrado em $Origem." }
$totalBytes = ($arquivos | Measure-Object Length -Sum).Sum
$totalGB = [math]::Round($totalBytes / 1GB, 2)
Write-Host ("Origem: {0} | {1} arquivos | {2} GB" -f $Origem, $arquivos.Count, $totalGB)

# --- Tabela "Cabe?" (lição do incidente 2) ---
Write-Host "`nDiscos disponíveis para a cópia:" -ForegroundColor Cyan
Get-Volume | Where-Object { $_.DriveLetter -and $_.Size -gt 0 } | ForEach-Object {
    [pscustomobject]@{
        Unidade = "$($_.DriveLetter):"
        Rotulo  = $_.FileSystemLabel
        LivreGB = [math]::Round($_.SizeRemaining / 1GB, 2)
        'Cabe?' = if ($_.SizeRemaining -gt $totalBytes * 1.05) { 'SIM' } else { 'NÃO' }
    }
} | Format-Table -AutoSize

$ok = Read-Host "Gerar o manifesto de '$Origem' em '$Manifesto'? (s/N)"
if ($ok -notmatch '^[sS]$') { Write-Host "Cancelado."; Stop-Transcript | Out-Null; exit 0 }

# --- Geração do manifesto ---
$i = 0
$linhas = foreach ($a in $arquivos) {
    $i++
    Write-Progress -Activity "Calculando SHA-256" -Status $a.Name -PercentComplete ($i / $arquivos.Count * 100)
    try {
        $hash = (Get-FileHash -LiteralPath $a.FullName -Algorithm SHA256).Hash
    } catch {
        Write-Warning "Não foi possível ler: $($a.FullName)"
        $hash = 'ERRO_LEITURA'
    }
    [pscustomobject]@{
        Caminho = $a.FullName.Substring($Origem.Length + 1).Replace('\', '/')
        Tamanho = $a.Length
        SHA256  = $hash
    }
}
Write-Progress -Activity "Calculando SHA-256" -Completed

$linhas | Export-Csv -LiteralPath $Manifesto -NoTypeInformation -Encoding UTF8
$erros = @($linhas | Where-Object SHA256 -eq 'ERRO_LEITURA').Count

Write-Host ("`nManifesto: {0} ({1} entradas, {2} erros de leitura)" -f $Manifesto, $linhas.Count, $erros) -ForegroundColor Green
Stop-Transcript | Out-Null
Read-Host "Pressione Enter para sair"
