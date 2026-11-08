# 06 · Conceitos técnicos aprendidos

O que aprendi neste projeto, explicado de forma simples, e **onde** cada conceito foi aplicado.

## Hardware e sistemas

| Conceito | O que é | Onde apliquei |
|---|---|---|
| **Linha de base (baseline)** | Medir o estado inicial para comparar depois | Boot e RAM medidos antes e depois ([01](01-diagnostico.md)) |
| **Gargalo (bottleneck)** | O componente que limita o desempenho | Descobri que o gargalo era o SO pesado, não o disco (que já era SSD) |
| **UEFI / GPT** | Firmware moderno e tabela de partições que substituem o BIOS/MBR | Instalação do Mint em modo UEFI |
| **Drivers / módulos do kernel** | Software que faz o hardware funcionar | Wi-Fi AR9565 com `ath9k`, reconhecido nativamente |
| **LTS (Long Term Support)** | Versão com atualizações de segurança por vários anos | Mint 22.3 com suporte até 2029, contra o Windows 10 já sem suporte |

## Integridade e backup

| Conceito | O que é | Onde apliquei |
|---|---|---|
| **Hash criptográfico (SHA-256)** | "Impressão digital" de um arquivo; qualquer alteração muda o hash | Manifesto do backup e conferência da ISO |
| **Integridade** (o "I" da tríade CIA) | Garantir que os dados não foram alterados | Restauração conferida arquivo a arquivo (11.759 idênticos) |
| **Regra 3-2-1** | 3 cópias, 2 suportes, 1 fora do local | Pendrive + HDD + Google Drive ([02](02-backup-e-restauracao.md)) |
| **Backup ≠ snapshot** | Backup protege dados; snapshot protege o estado do sistema | Backup manual dos arquivos + Timeshift para o sistema |
| **Disponibilidade** (o "A" da CIA) | O sistema estar funcional quando é preciso | Timeshift antes de updates, reboot remoto validado |

## Segurança

| Conceito | O que é | Onde apliquei |
|---|---|---|
| **Hardening** | Reduzir a superfície de ataque | Todo o [03-hardening.md](03-hardening.md) |
| **Privilégio mínimo** | Cada conta/ferramenta só tem o acesso que precisa | Usuário sem sudo; rclone em `drive.readonly`; `AllowUsers suporte` |
| **Separação de funções** | Uso diário e administração em contas diferentes | Conta `suporte` oculta vs. conta do usuário |
| **Default deny** | Bloquear tudo e liberar só o necessário | `ufw default deny incoming` |
| **Defesa em profundidade** | Várias camadas, para que a falha de uma não comprometa tudo | VPN + firewall por interface + SSH por chave + senha VNC |
| **Gestão de vulnerabilidades / CVE** | Identificar e corrigir falhas conhecidas | WinRAR vulnerável (CVE-2023-38831) removido; updates automáticos |
| **Cadeia de confiança de software** | Só instalar software de origem verificável | ISO conferida por hash; repo sem chave GPG (`NO_PUBKEY`) desativado; Office pirata removido |

## Redes e acesso remoto

| Conceito | O que é | Onde apliquei |
|---|---|---|
| **VPN / WireGuard** | Túnel cifrado entre computadores | Tailscale entre o meu notebook e o CCE |
| **NAT traversal** | Ligar computadores atrás de roteadors sem abrir portas | Tailscale dispensou o port forwarding |
| **Interfaces de rede** | Cada "placa" de rede (física ou virtual) tem nome próprio | Regras do ufw só em `tailscale0` |
| **Portas e serviços** | Cada serviço escuta em uma porta | SSH na 22, VNC na 5900 |
| **Criptografia assimétrica** | Par de chaves pública/privada | Chave SSH ED25519; a pública vai no servidor e a privada nunca sai do meu notebook |
| **Autenticação forte** | Mais do que "algo que você sabe" | Chave (algo que tenho) + passphrase (algo que sei) |

## Linux e automação

| Conceito | O que é | Onde apliquei |
|---|---|---|
| **systemd / serviços** | Gerenciador que inicia e monitora serviços | x11vnc como serviço; `systemd-analyze` para medir o boot |
| **Gerenciador de pacotes e locks** | `apt`/`dpkg` protegem a base de pacotes com locks | [Incidente 7](05-incidentes.md): esperar, nunca apagar o lock |
| **Validação de entradas** | Nunca confiar que uma variável tem o valor esperado | [Incidente 4](05-incidentes.md): `rsync` com variável vazia |
| **Observabilidade / logs** | Conseguir ver o que um script fez | [Incidente 1](05-incidentes.md): `trap` + `Start-Transcript` |
| **Verificar o resultado** | Confirmar o efeito real, não a mensagem | [Incidente 6](05-incidentes.md): `authorized_keys` vazio com "OK" |

## Ligação com a carreira

Este projeto cobre, na prática, tarefas diárias de **Suporte Técnico / Service Desk** (diagnóstico, backup, reinstalação, suporte remoto) e fundamentos de **SOC/Segurança** (hardening, gestão de vulnerabilidades, controle de acesso, documentação de incidentes).
