# 04 · Acesso remoto seguro

> O acesso remoto foi **autorizado pelo usuário** do computador. Acesso remoto sem consentimento é invasão.

## Requisitos

- Dar suporte a partir de outro país
- **Nenhuma porta aberta na internet** (nada de port forwarding no roteador)
- Funcionar mesmo que o IP da casa mude
- Autenticação forte

## Arquitetura

```
   Meu notebook (admin)                          Notebook do usuário
 ┌──────────────────────┐                      ┌──────────────────────────┐
 │ chave SSH ED25519    │   rede privada        │ tailscale0 (100.x.x.x)   │
 │ (com passphrase)     │◀──── Tailscale ─────▶│  ├─ :22   OpenSSH         │
 │ TigerVNC Viewer      │   (WireGuard,         │  └─ :5900 x11vnc          │
 └──────────────────────┘    cifrado E2E)       │ ufw: 22/5900 só em        │
                                                │      tailscale0           │
                                                └──────────────────────────┘
              Internet pública: nenhuma porta exposta
```

## Camadas

### 1. Tailscale (VPN mesh baseada em WireGuard)

- Cria uma rede privada entre os dois computadores, com tráfego **cifrado ponta a ponta**
- Atravessa NAT sozinho, sem precisar mexer no roteador
- Computador na conta do administrador, com **auto-update** ativo
- **Key expiry desativado** neste nó, para que o acesso não caia sozinho depois de 180 dias em um computador que eu não consigo reautenticar fisicamente

### 2. OpenSSH: só por chave

Configuração em [`configs/sshd/99-hardening.conf`](../configs/sshd/99-hardening.conf):

```
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
AllowUsers suporte
```

- Chave **ED25519** gerada no meu notebook e protegida com **passphrase**
- Mesmo que alguém descubra a senha da conta, **não entra por SSH sem a chave**
- Só a conta `suporte` pode fazer login remoto

```bash
# no meu notebook
ssh-keygen -t ed25519 -C "suporte-cce"
# copiar a chave pública para ~suporte/.ssh/authorized_keys no CCE
# e CONFERIR o conteúdo (ver incidente 6)
sudo sshd -t && sudo systemctl reload ssh
```

### 3. x11vnc: ver a tela do usuário

- Roda como **serviço systemd** ([`configs/systemd/x11vnc.service`](../configs/systemd/x11vnc.service)), por isso inicia sozinho a cada boot
- Senha guardada em `/etc/x11vnc.pass` (o protocolo VNC só usa **8 caracteres** de senha, e por isso **nunca** fica exposto fora da VPN)
- Cliente: **TigerVNC Viewer**

### 4. Firewall (ufw)

Regras em [`configs/ufw/regras.md`](../configs/ufw/regras.md):

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on tailscale0 to any port 22 proto tcp
sudo ufw allow in on tailscale0 to any port 5900 proto tcp
sudo ufw enable
```

## Validação do ciclo completo (remoto)

1. `sudo timeshift --create --comments "antes do upgrade"`, um snapshot de segurança
2. `sudo apt update && sudo apt full-upgrade -y`
3. `sudo reboot`
4. ✅ O computador voltou sozinho à rede Tailscale e aceitou SSH de novo

## Limitações conhecidas

- **Tampa fechada = suspensão = sem acesso.** O usuário precisa deixar o notebook aberto (ou ligado na tomada com a suspensão ajustada) quando precisar de suporte.
- Melhoria futura: fazer o x11vnc escutar **só** no IP da Tailscale (`-listen`) para não depender só do firewall.
