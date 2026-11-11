# 🔄 Renascer CCE F4030

> Bringing an old, slow laptop back to life: from **unsupported Windows 10** to **Linux Mint 22.3 XFCE**, with a hash-verified backup, hardening, secure remote access and full documentation, including the mistakes I made and how I fixed them.

![Status](https://img.shields.io/badge/status-completed-success)
![OS](https://img.shields.io/badge/Linux%20Mint-22.3%20XFCE-87CF3E?logo=linuxmint&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-scripts-5391FE?logo=powershell&logoColor=white)
![Python](https://img.shields.io/badge/Python-3-3776AB?logo=python&logoColor=white)
![Tailscale](https://img.shields.io/badge/remote%20access-Tailscale%20%2B%20SSH-242424)

🇧🇷 [Ler em português](README.md)

> *"Renascer" means "reborn" in Portuguese. The detailed docs in `docs/` are in Portuguese; this page summarizes the whole project in English.*

---

## 📌 Context

A family member had an entry-level laptop (CCE F40-30, Celeron, 4 GB RAM) that took more than 2 minutes to boot and became almost unusable with a browser open. On top of that, Windows 10 stopped receiving security updates in October 2025.

The user is **not technical**, so the new system had to look like Windows, be simple and stay secure on its own. I also needed to support it **remotely**, because I live in another country.

## 🎯 Goals

1. Save **all** of the user's files, with proof that nothing was lost.
2. Replace the OS with a lighter one that has long-term support.
3. Apply **hardening** suited to a non-technical user.
4. Set up **secure remote access** for support, without exposing ports to the internet.
5. Document everything as a portfolio project.

## 📊 Results (measured)

| Metric | Before (Windows 10 Pro 22H2) | After (Linux Mint 22.3 XFCE) |
|---|---|---|
| Boot time | 115–133 s | **29.0 s** (`systemd-analyze`) |
| RAM | 0.85 GB free with apps open | **0.9 GB used / 2.8 GB available** at idle |
| Security support | Ended (Oct 2025) | **LTS until 2029** |
| Drivers | Several installed manually | **All native** |
| Files preserved | — | **11,769 files / 12.5 GB**, verified with SHA-256 |

Boot became about **4× faster** without replacing any hardware.

## 🧭 Project stages

```
1. Assessment ─▶ 2. Backup + SHA-256 manifest ─▶ 3. Mint installation
       │                                                │
       ▼                                                ▼
 Security findings                      4. Restore + hash verification
                                                        │
                                                        ▼
                       6. Remote access ◀─ 5. Hardening ◀┘
                               │
                               ▼
              7. Remote validation (snapshot → update → reboot)
```

## 🔍 Assessment and security findings

The SSD was already there, so the bottleneck was the **operating system's weight**, not storage. The old system also had:

- Windows 10 **out of support**, plus a `.bat` file that **disabled Windows Update**
- **WinRAR 5.00 beta**, vulnerable to **CVE-2023-38831** (code execution when opening a crafted archive)
- **Unofficial Office** activation (a common malware vector)
- An external HDD with a **modified Windows build** and crack scripts (wiped)

Instead of "cleaning" a system that could no longer be trusted, I **reinstalled from scratch** using a hash-verified ISO.

## 💾 Backup and restore

- **3-2-1 rule:** USB drive + external HDD + Google Drive (separate account)
- `backup-verify.ps1` builds a **SHA-256 manifest** (relative path, size, hash) of every file
- Restore with **rclone** using the **`drive.readonly`** scope (least privilege: it can read, never delete)
- `verificar-manifesto.py` checked the restore file by file: **11,759 identical files** in the main backup folder, none missing or different
- **Timeshift** (rsync mode) protects the *system*: 2 daily + 2 weekly snapshots, `/home` excluded

## 🛡️ Hardening

| Measure | Security principle |
|---|---|
| Automatic updates | Vulnerability management |
| Timeshift snapshots before risky changes | Availability / recovery |
| `ufw` active, incoming denied by default | Default deny |
| Hidden admin account `suporte`; daily user **without sudo** | Least privilege, separation of duties |
| No auto-login, lock on suspend | Access control |
| uBlock Origin, WhatsApp as a Mint Web App | Attack surface reduction, trusted software |
| Unsigned repository (`NO_PUBKEY`) disabled | Software supply chain trust |

## 🌐 Secure remote access

```
  My laptop (admin)                         User's laptop
 ┌─────────────────────┐                  ┌──────────────────────────┐
 │ ED25519 SSH key     │  private network │ tailscale0               │
 │ (with passphrase)   │◀── Tailscale ───▶│  ├─ :22   OpenSSH         │
 │ TigerVNC Viewer     │  (WireGuard,     │  └─ :5900 x11vnc          │
 └─────────────────────┘   E2E encrypted) │ ufw: 22/5900 only on      │
                                          │      tailscale0           │
                                          └──────────────────────────┘
             Public internet: no exposed ports
```

- **Tailscale** (WireGuard mesh VPN): encrypted end to end, works behind NAT with no port forwarding
- **OpenSSH key-only:** `PasswordAuthentication no`, `PermitRootLogin no`, `AllowUsers suporte`
- **x11vnc** as a systemd service, reachable only through the VPN
- Remote access was **authorized by the user**
- Validated end to end: snapshot → `apt full-upgrade` → remote reboot → the laptop came back online on its own

## 🧯 Mistakes I made (and learned from)

Seven real incidents are documented in [`docs/05-incidentes.md`](docs/05-incidentes.md) using a post-mortem format (what happened → cause → fix → lesson). Highlights:

- **`rsync` with an empty variable** turned into `rsync /`, copied the whole system in a loop and filled the disk with 84 GB. Lesson: **always validate inputs** and use `--dry-run` before bulk operations.
- A command run in the wrong shell left `authorized_keys` **empty while printing "OK"**. Lesson: **verify the result, not the message.**
- `apt` waiting on the `dpkg` lock while automatic updates ran. Lesson: wait; **never delete lock files**.

## 📂 Repository structure

```
renascer-cce-f4030/
├── README.md / README.en.md
├── docs/          # assessment, backup, hardening, remote access, incidents, concepts, user guide (PT)
├── scripts/
│   ├── windows/   # diagnostico.ps1, backup-verify.ps1, checar-hdd.ps1, verificar-iso.ps1
│   └── linux/     # verificar-manifesto.py, auditoria-hardening.sh
└── configs/       # sanitized examples: sshd, systemd (x11vnc), ufw
```

## 🛠️ Tools

**OS:** Windows 10, Linux Mint 22.3 XFCE (Ubuntu 24.04 base)
**Scripting:** PowerShell, Python 3, Bash
**Backup:** Get-FileHash (SHA-256), rclone, Timeshift
**Security:** ufw, OpenSSH (ED25519), least-privilege accounts
**Remote access:** Tailscale, SSH, x11vnc + TigerVNC

## 🔒 Privacy

This repository contains **no** files, file names, usernames, hostname, serial number, IP addresses or keys from the device. The examples in `configs/` use generic values.

## 👤 Author

**Julio Oliveira**, Cybersecurity student (Cisco CCST Networking + Cybersecurity)
[GitHub](https://github.com/JulioOliveira397) · [LinkedIn](https://www.linkedin.com/in/julio-oliver-tech)

License: [MIT](LICENSE)
