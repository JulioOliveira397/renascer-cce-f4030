<#
.SYNOPSIS
    Verifica a saúde dos discos (somente leitura).
.DESCRIPTION
    Usa Get-PhysicalDisk e Get-StorageReliabilityCounter (dados SMART expostos
    pelo Windows): estado de saúde, temperatura, horas ligadas, erros de leitura
    e desgaste. Útil antes de confiar um backup a um disco externo.
.EXAMPLE
    Execute como administrador: .\checar-hdd.ps1
.NOTES
    Projeto Renascer CCE F4030 - Julio Oliveira
#>

$ErrorActionPreference = 'Stop'

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
          IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    Write-Warning "Execute como administrador para ver os contadores SMART completos."
}

foreach ($d in Get-PhysicalDisk) {
    Write-Host "`n==== $($d.FriendlyName) ====" -ForegroundColor Cyan
    [pscustomobject]@{
        Tipo        = $d.MediaType
        Barramento  = $d.BusType
        TamanhoGB   = [math]::Round($d.Size / 1GB)
        Saude       = $d.HealthStatus
        Operacional = ($d.OperationalStatus -join ', ')
    } | Format-List

    try {
        $c = $d | Get-StorageReliabilityCounter
        [pscustomobject]@{
            'Temperatura (°C)'       = $c.Temperature
            'Horas ligado'           = $c.PowerOnHours
            'Erros leitura (total)'  = $c.ReadErrorsTotal
            'Erros não corrigidos'   = $c.ReadErrorsUncorrected
            'Desgaste (%)'           = $c.Wear
        } | Format-List
    } catch {
        Write-Host "Contadores SMART indisponíveis para este disco (comum em USB)." -ForegroundColor Yellow
    }

    if ($d.HealthStatus -ne 'Healthy') {
        Write-Host "ATENÇÃO: disco com estado '$($d.HealthStatus)'. Não use como único backup." -ForegroundColor Red
    }
}

Read-Host "`nPressione Enter para sair"
