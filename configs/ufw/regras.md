# Regras do ufw

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH e VNC só pela VPN (interface tailscale0)
sudo ufw allow in on tailscale0 to any port 22 proto tcp comment 'SSH via Tailscale'
sudo ufw allow in on tailscale0 to any port 5900 proto tcp comment 'VNC via Tailscale'

sudo ufw enable
sudo ufw status verbose
```

Saída esperada (resumida):

```
Status: active
Default: deny (incoming), allow (outgoing), deny (routed)

To                         Action      From
--                         ------      ----
22/tcp on tailscale0       ALLOW IN    Anywhere
5900/tcp on tailscale0     ALLOW IN    Anywhere
```

Pela rede local ou pela internet, as portas 22 e 5900 aparecem **fechadas**.
