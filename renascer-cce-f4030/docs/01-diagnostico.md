# 01 · Diagnóstico

Antes de mexer em qualquer coisa, fiz o inventário do computador e medi o desempenho para ter uma **linha de base**. Sem medição "antes", não há como provar a melhoria "depois".

Script usado: [`scripts/windows/diagnostico.ps1`](../scripts/windows/diagnostico.ps1) (somente leitura).

## Hardware

| Componente | Detalhe |
|---|---|
| Modelo | CCE F40-30 (a placa se identifica como Lenovo F40-30) |
| CPU | Intel Celeron N2830 (Bay Trail), 2 núcleos / 2 threads |
| RAM | 4 GB DDR3L, 1 slot livre (máx. 8 GB) |
| Armazenamento | SSD Kingston A400 120 GB (já era SSD) |
| GPU | Intel HD Graphics (Bay Trail), integrada |
| Wi-Fi | Qualcomm Atheros AR9565 (driver `ath9k`) |
| Ethernet | Realtek RTL8168 |
| Firmware | UEFI, tabela de partições GPT, Secure Boot desativado |
| Bateria | ~73% da capacidade original |

**Conclusão importante:** o disco já era SSD. A lentidão não vinha do armazenamento, mas do **peso do sistema** (Windows 10 em 4 GB de RAM com um Celeron de 2 núcleos). Trocar o SO era a intervenção com melhor custo-benefício.

## Medições "antes"

| Métrica | Valor | Como medi |
|---|---|---|
| Boot | 115–133 s | cronômetro, do botão até a área de trabalho utilizável |
| RAM livre | 0,85 GB com o navegador e apps abertos | Gerenciador de Tarefas / `Get-CimInstance Win32_OperatingSystem` |
| Versão | Windows 10 Pro 22H2 | `winver` |

## Achados de segurança

| # | Achado | Risco |
|---|---|---|
| 1 | Windows 10 **fora de suporte** desde out/2025 | Vulnerabilidades novas nunca serão corrigidas |
| 2 | `.bat` que **desativava o Windows Update** | Mesmo os patches disponíveis não eram instalados |
| 3 | **WinRAR 5.00 beta** | Vulnerável à **CVE-2023-38831**: um arquivo compactado malicioso pode executar código quando o usuário abre um arquivo aparentemente inofensivo |
| 4 | **Office de origem não oficial** | Ativadores piratas são um vetor comum de malware |
| 5 | HDD externo com **Windows modificado (KernelOS)** e `.bat` de crack | Software adulterado, sem garantia de integridade; o disco foi limpo |

Esses achados reforçaram a decisão: em vez de "limpar" um sistema em que já não se pode confiar, **reinstalar do zero** a partir de uma ISO verificada.

## Medições "depois"

| Métrica | Valor | Como medi |
|---|---|---|
| Boot | **29,0 s** | `systemd-analyze` |
| RAM | **0,9 GB usada / 2,8 GB disponível** em repouso | `free -h` |
| Drivers | Todos reconhecidos nativamente | `inxi -Fxz`, `lspci -k` |
