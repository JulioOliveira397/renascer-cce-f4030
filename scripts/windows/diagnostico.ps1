<#
.SYNOPSIS
    Inventário de hardware e software do Windows (somente leitura).
.DESCRIPTION
    Coleta CPU, RAM, discos, rede, firmware, versão do SO, tempo desde o boot
    e programas instalados. Não altera nada no sistema.
    Gera um relatório em texto na pasta atual.
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\diagnostico.ps1
.NOTES
    Projeto Renascer CCE F4030 - Julio Oliveira
    Remova dados pessoais (usuário, hostname, serial) antes de publicar o relatório.
#>

$ErrorActionPreference = 'Stop'
$relatorio = Join-Path (Get-Location) ("diagnostico_{0:yyyyMMdd_HHmm}.txt" -f (Get-Date))
Start-Transcript -Path $relatorio | Out-Null

trap {
    Write-Host "`n[ERRO] $($_.Exception.Message)" -ForegroundColor Red
    Stop-Transcript | Out-Null
    Read-Host "Pressione Enter para sair"
    exit 1
}

function Secao($titulo) { Write-Host "`n==== $titulo ====" -ForegroundColor Cyan }

Secao "Sistema operacional"
$os = Get-CimInstance Win32_OperatingSystem
$os | Select-Object Caption, Version, BuildNumber, OSArchitecture | Format-List
$uptime = (Get-Date) - $os.LastBootUpTime
"Ligado há: {0:dd\.hh\:mm} (dias.horas:min)" -f $uptime

Secao "Modelo / firmware"
Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer, Model | Format-List
Get-CimInstance Win32_BIOS | Select-Object SMBIOSBIOSVersion, ReleaseDate | Format-List
try   { "Secure Boot ativo: $(Confirm-SecureBootUEFI)" }
catch { "Secure Boot: não suportado ou modo legado (BIOS)" }

Secao "CPU"
Get-CimInstance Win32_Processor |
    Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed | Format-List

Secao "Memória"
$totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$livreGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
"Total visível: $totalGB GB | Livre agora: $livreGB GB"
Get-CimInstance Win32_PhysicalMemory |
    Select-Object BankLabel, @{n='GB';e={$_.Capacity / 1GB}}, Speed, PartNumber | Format-Table -AutoSize
$slots = (Get-CimInstance Win32_PhysicalMemoryArray).MemoryDevices
"Slots de memória: $slots"

Secao "Discos"
Get-PhysicalDisk |
    Select-Object FriendlyName, MediaType, BusType, HealthStatus,
                  @{n='GB';e={[math]::Round($_.Size / 1GB)}} | Format-Table -AutoSize
Get-Volume | Where-Object DriveLetter |
    Select-Object DriveLetter, FileSystem,
                  @{n='TotalGB';e={[math]::Round($_.Size / 1GB, 1)}},
                  @{n='LivreGB';e={[math]::Round($_.SizeRemaining / 1GB, 1)}} | Format-Table -AutoSize

Secao "Rede"
Get-NetAdapter | Select-Object Name, InterfaceDescription, Status, LinkSpeed | Format-Table -AutoSize

Secao "Bateria"
$bat = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
if ($bat) { $bat | Select-Object Name, EstimatedChargeRemaining | Format-List }
else      { "Sem bateria detectada" }
"Para saúde detalhada: powercfg /batteryreport"

Secao "Windows Update"
Get-Service wuauserv | Select-Object Name, Status, StartType | Format-List
Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 5 HotFixID, InstalledOn | Format-Table -AutoSize

Secao "Programas instalados"
$chaves = @(
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
Get-ItemProperty $chaves -ErrorAction SilentlyContinue |
    Where-Object DisplayName |
    Sort-Object DisplayName |
    Select-Object DisplayName, DisplayVersion, Publisher | Format-Table -AutoSize

Stop-Transcript | Out-Null
Write-Host "`nRelatório salvo em: $relatorio" -ForegroundColor Green
Read-Host "Pressione Enter para sair"
