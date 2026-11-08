# 03 · Hardening

**Hardening** é reduzir a superfície de ataque de um sistema: desligar o que não é preciso, limitar privilégios e garantir que ele continue atualizado. Aqui, o desafio extra era fazer isso **sem complicar a vida de um usuário leigo**.

## Por que Linux Mint XFCE

- Interface parecida com o Windows (menu iniciar, barra de tarefas), com curva de aprendizagem mínima
- XFCE é leve: cabe folgado em 4 GB de RAM
- Base Ubuntu LTS: **suporte até 2029**
- A ISO foi conferida por hash antes de gravar ([`verificar-iso.ps1`](../scripts/windows/verificar-iso.ps1))

## Medidas aplicadas

| Medida | O que faz | Princípio de segurança |
|---|---|---|
| **Atualizações automáticas** (Gerenciador de Atualizações) | Instala patches sem depender do usuário | Gestão de vulnerabilidades |
| **Timeshift** (2 diários + 2 semanais) | Volta o sistema atrás se um update der errado | Disponibilidade / recuperação |
| **ufw ativo** (nega entradas por padrão) | Bloqueia conexões não solicitadas | Default deny |
| Conta **`suporte`** administradora, **oculta** no login | Separa administração do uso diário | Separação de funções |
| Usuário do dia a dia **sem sudo** | Malware ou erro do usuário não consegue alterar o sistema | Privilégio mínimo |
| **Sem login automático** | Quem pega o notebook não entra direto | Controle de acesso |
| **Bloqueio ao suspender** | Fechar a tampa e reabrir pede senha | Controle de acesso físico |
| **uBlock Origin** no navegador | Bloqueia anúncios e domínios maliciosos | Redução de superfície de ataque |
| **WhatsApp como Web App** (Mint) | Evita apps de terceiros não oficiais | Software de origem confiável |
| Acesso remoto só via VPN | Ver [04-acesso-remoto.md](04-acesso-remoto.md) | Defesa em profundidade |

## Ajustes de repositórios

- O espelho `mirrors.up.pt` respondia **HTTP 503** → trocado para `archive.ubuntu.com`.
- O repositório do Spotify dava **`NO_PUBKEY`** (chave GPG faltando) → **desativado**. Um repositório sem assinatura válida não deve ficar ativo, porque não há garantia de que os pacotes são autênticos. Próximo passo: instalar o Spotify via Flatpak.

## Verificação

O script [`auditoria-hardening.sh`](../scripts/linux/auditoria-hardening.sh) confere estes pontos em modo somente leitura:

```bash
sudo bash auditoria-hardening.sh
```
