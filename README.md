# 🔄 Renascer CCE F4030

> Recuperação de um notebook antigo e lento: de **Windows 10 sem suporte** para **Linux Mint 22.3 XFCE**, com backup verificado por hash, hardening, acesso remoto seguro e documentação completa, incluindo os erros que cometi e como os corrigi.

![Status](https://img.shields.io/badge/status-conclu%C3%ADdo-success)
![SO](https://img.shields.io/badge/Linux%20Mint-22.3%20XFCE-87CF3E?logo=linuxmint&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-scripts-5391FE?logo=powershell&logoColor=white)
![Python](https://img.shields.io/badge/Python-3-3776AB?logo=python&logoColor=white)
![Tailscale](https://img.shields.io/badge/acesso%20remoto-Tailscale%20%2B%20SSH-242424)

🇬🇧 [Read in English](README.en.md)

---

## 📌 Contexto

Um familiar tinha um notebook de entrada (CCE F40-30, Celeron, 4 GB de RAM) que demorava mais de 2 minutos para ligar e ficava praticamente inutilizável com o navegador aberto. Além disso, o Windows 10 deixou de receber atualizações de segurança em outubro de 2025.

O usuário **não é técnico**. Por isso, o sistema novo tinha que ter "cara de Windows", ser simples e se manter seguro sozinho. Eu também precisava dar suporte **à distância**, porque moro em outro país.

## 🎯 Objetivos

1. Salvar **todos** os arquivos do usuário, com prova de que nada se perdeu.
2. Trocar o sistema por um mais leve e com suporte de longo prazo.
3. Aplicar **hardening** adequado a um usuário leigo.
4. Configurar **acesso remoto seguro** para suporte, sem expor portas à internet.
5. Documentar tudo como projeto de portfólio.

## 📊 Resultados (medidos)

| Métrica | Antes (Windows 10 Pro 22H2) | Depois (Linux Mint 22.3 XFCE) |
|---|---|---|
| Tempo de boot | 115–133 s | **29,0 s** (`systemd-analyze`) |
| Memória RAM | 0,85 GB livre com apps abertos | **0,9 GB usada / 2,8 GB disponível** em repouso |
| Suporte de segurança | Encerrado (out/2025) | **LTS até 2029** |
| Drivers | Vários manuais | **Todos nativos** |
| Arquivos preservados | — | **11.769 arquivos / 12,5 GB**, conferidos por SHA-256 |

O boot ficou cerca de **4× mais rápido** sem trocar nenhuma peça.

## 🧭 Etapas do projeto

```
1. Diagnóstico ─▶ 2. Backup + manifesto SHA-256 ─▶ 3. Instalação do Mint
        │                                                   │
        ▼                                                   ▼
  Achados de segurança                       4. Restauração + conferência por hash
                                                            │
                                                            ▼
                         6. Acesso remoto ◀─ 5. Hardening ◀─┘
                                 │
                                 ▼
                    7. Validação remota (snapshot → update → reboot)
```

## 📂 Estrutura do repositório

```
renascer-cce-f4030/
├── README.md
├── README.en.md               # versão em inglês
├── docs/
│   ├── 01-diagnostico.md          # hardware, medições e achados de segurança
│   ├── 02-backup-e-restauracao.md # estratégia 3-2-1, manifesto SHA-256, rclone
│   ├── 03-hardening.md            # contas, firewall, updates, snapshots
│   ├── 04-acesso-remoto.md        # Tailscale + SSH por chave + VNC
│   ├── 05-incidentes.md           # 7 erros reais, causa e lição
│   ├── 06-conceitos.md            # conceitos técnicos aprendidos e onde foram aplicados
│   └── guia-do-usuario.md         # guia de 1 página para o usuário final
├── scripts/
│   ├── windows/
│   │   ├── diagnostico.ps1        # inventário de hardware/software (somente leitura)
│   │   ├── backup-verify.ps1      # gera manifesto SHA-256 do backup
│   │   ├── checar-hdd.ps1         # saúde dos discos (SMART/Storage Reliability)
│   │   └── verificar-iso.ps1      # confere o hash da ISO antes de gravar
│   └── linux/
│       ├── verificar-manifesto.py # confere a restauração contra o manifesto
│       └── auditoria-hardening.sh # checagem rápida do hardening (somente leitura)
└── configs/                       # exemplos sanitizados das configurações usadas
    ├── sshd/99-hardening.conf
    ├── systemd/x11vnc.service
    └── ufw/regras.md
```

## 🛠️ Tecnologias e ferramentas

**Sistemas:** Windows 10, Linux Mint 22.3 XFCE (base Ubuntu 24.04)
**Scripts:** PowerShell, Python 3, Bash
**Backup:** Get-FileHash (SHA-256), rclone (escopo `drive.readonly`), Timeshift (rsync)
**Segurança:** ufw, OpenSSH (chave ED25519), contas com privilégio mínimo, uBlock Origin
**Acesso remoto:** Tailscale (WireGuard), SSH, x11vnc + TigerVNC Viewer
**Diagnóstico:** `systemd-analyze`, `free`, `lsblk`, `inxi`, CIM/WMI no PowerShell

## 🔐 Destaques de segurança

- Encontrei e removi **software vulnerável e de origem duvidosa** no sistema antigo: WinRAR 5.00 beta (vulnerável à CVE-2023-38831), Office não oficial, um `.bat` que desativava o Windows Update e um HDD externo com Windows modificado e cracks. Detalhes em [01-diagnostico.md](docs/01-diagnostico.md).
- O usuário do dia a dia **não tem sudo**. A administração fica em uma conta `suporte` separada e oculta no tela de login.
- **Nenhuma porta exposta à internet.** SSH (22) e VNC (5900) só aceitam conexões pela interface da VPN `tailscale0`.
- SSH **só com chave** (senha desativada, root bloqueado, `AllowUsers` restrito).

## 🧯 Erros que cometi (e aprendi)

Documentei **7 incidentes reais** em [05-incidentes.md](docs/05-incidentes.md). O mais grave foi um `rsync` com uma variável vazia que virou `rsync /`, encheu o disco com 84 GB em loop e me ensinou a **validar sempre as entradas** antes de comandos destrutivos.

## 🔒 Privacidade

Este repositório **não contém** arquivos, nomes de arquivos, nomes de usuário, hostname, número de série, IPs ou chaves do computador. Os exemplos em `configs/` usam valores genéricos.

## 👤 Autor

**Julio Oliveira**, estudante de Cibersegurança (Cisco CCST Redes + Ciber)
[GitHub](https://github.com/JulioOliveira397) · [LinkedIn](https://www.linkedin.com/in/julio-oliver-tech)

Licença: [MIT](LICENSE)
