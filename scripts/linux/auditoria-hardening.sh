#!/usr/bin/env bash
# Auditoria rápida do hardening (somente leitura - não altera nada).
# Uso: sudo bash auditoria-hardening.sh [usuario_do_dia_a_dia]
# Projeto Renascer CCE F4030 - Julio Oliveira

set -uo pipefail

[ "$(id -u)" -eq 0 ] || { echo "Execute com sudo."; exit 2; }

USUARIO="${1:-${SUDO_USER:-}}"
OK=0; FALHA=0
ok()    { printf '  \e[32m[OK]\e[0m    %s\n' "$1"; OK=$((OK+1)); }
falha() { printf '  \e[31m[FALHA]\e[0m %s\n' "$1"; FALHA=$((FALHA+1)); }
secao() { printf '\n\e[36m== %s ==\e[0m\n' "$1"; }

secao "Sistema"
. /etc/os-release && echo "  $PRETTY_NAME | kernel $(uname -r)"
systemd-analyze 2>/dev/null | head -1 | sed 's/^/  /'

secao "Firewall (ufw)"
if ufw status | grep -q "Status: active"; then ok "ufw ativo"; else falha "ufw inativo"; fi
if ufw status verbose | grep -q "deny (incoming)"; then ok "entrada negada por padrão"; else falha "política de entrada não é deny"; fi
if ufw status | grep -E '^(22|5900)' | grep -vq 'tailscale0'; then
    falha "porta 22/5900 liberada fora do tailscale0"
else
    ok "22/5900 só em tailscale0 (ou fechadas)"
fi

secao "SSH"
if command -v sshd >/dev/null; then
    CFG="$(sshd -T 2>/dev/null)"
    grep -qi '^passwordauthentication no'         <<<"$CFG" && ok "senha desativada"        || falha "PasswordAuthentication ativo"
    grep -qi '^kbdinteractiveauthentication no'   <<<"$CFG" && ok "kbd-interactive desativado" || falha "KbdInteractiveAuthentication ativo"
    grep -qi '^permitrootlogin no'                <<<"$CFG" && ok "root bloqueado"          || falha "PermitRootLogin não é 'no'"
    grep -qi '^allowusers'                        <<<"$CFG" && ok "AllowUsers definido"     || falha "AllowUsers não definido"
else
    echo "  OpenSSH server não instalado"
fi

secao "Tailscale"
if command -v tailscale >/dev/null && tailscale status >/dev/null 2>&1; then ok "tailscale conectado"; else falha "tailscale desconectado/ausente"; fi

secao "VNC"
systemctl is-active --quiet x11vnc && ok "x11vnc ativo" || falha "x11vnc inativo"
if [ -f /etc/x11vnc.pass ]; then
    PERM="$(stat -c '%a' /etc/x11vnc.pass)"
    [ "$PERM" -le 600 ] && ok "/etc/x11vnc.pass com permissão $PERM" || falha "/etc/x11vnc.pass com permissão $PERM (use 600)"
fi

secao "Contas"
if [ -n "$USUARIO" ]; then
    if id -nG "$USUARIO" | grep -qwE 'sudo|admin'; then falha "$USUARIO tem sudo"; else ok "$USUARIO sem sudo"; fi
else
    echo "  (informe o usuário do dia a dia como argumento para checar sudo)"
fi
if grep -rqsE '^\s*autologin-user\s*=\s*\S' /etc/lightdm/; then falha "login automático ativo"; else ok "sem login automático"; fi

secao "Atualizações e snapshots"
if systemctl list-timers 2>/dev/null | grep -q 'mintupdate-automation-upgrade' \
   || systemctl is-enabled --quiet unattended-upgrades 2>/dev/null; then
    ok "atualizações automáticas habilitadas"
else
    falha "atualizações automáticas não detectadas"
fi
if command -v timeshift >/dev/null && [ "$(timeshift --list 2>/dev/null | grep -c '>')" -gt 0 ]; then
    ok "Timeshift com snapshots"
else
    falha "Timeshift sem snapshots"
fi

printf '\nResultado: %d OK | %d FALHA\n' "$OK" "$FALHA"
[ "$FALHA" -eq 0 ]
