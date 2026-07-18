# ⚡ TheTechSavage OpenVPN Master (Standalone Edition)

![Version](https://img.shields.io/badge/Version-1.0_Premium-cyan?style=for-the-badge) 
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge) 
![Platform](https://img.shields.io/badge/Platform-Ubuntu_20%2B-orange?style=for-the-badge)
![Security](https://img.shields.io/badge/Security-PAM_Sniper-red?style=for-the-badge)

**The Ultimate OpenVPN-Only Autoscript.** Built for administrators who need a lightweight, dedicated OpenVPN server without the bloat of multiple protocols. Features a dynamic CLI dashboard, PAM-based user authentication, a strict multi-login AutoKill Sniper, and automated Telegram cloud backups.

---

## 🚀 Key Features

* 🔐 **PAM Authentication Engine:** Strips away clunky static certificates. Authenticate users dynamically using Linux system accounts for instant creation, modification, and deletion.
* 🌍 **Universal Client Profile:** No more generating a new `.ovpn` file for every user. A single, universal `.ovpn` profile is automatically generated and hosted on a built-in Nginx file server (Port 85) for instant deployment.
* 🔫 **Multi-Login AutoKill (The Sniper):** Actively monitors the OpenVPN management port. If a user exceeds their allowed concurrent device limit, the Sniper instantly drops their connection and temporarily locks their account.
* ⏳ **Timed & Trial Accounts:** Generate temporary passes (e.g., 30 minutes) or 24-hour trials that automatically self-destruct from the server when time expires.
* 🧹 **Nightly Sweeper:** A background cronjob that hunts down and deletes expired accounts every night at 1:00 AM to keep your database clean.
* ☁️ **Automated Telegram Backups:** Zip your entire OpenVPN architecture, user limits, and configurations, send them to Google Drive, and instantly deliver the download link to your Telegram Bot.
* 📡 **Over-The-Air (OTA) Updates:** Push live script patches to your server directly from the master vault without ever reinstalling the OS.

---

## 📥 Installation

Run this command on a fresh **Ubuntu 20.04 / 22.04 / 24.04 LTS** or **Debian 10 / 11 / 12** VPS.

```bash
apt update && apt install -y wget && wget -q https://raw.githubusercontent.com/TheTechSavant/TheTechSavage_OpenVPN_Master/main/install/setup.sh && chmod +x setup.sh && ./setup.sh
```

### 🛠️ Setup Steps

1.  **Register your IP:** Ensure your server IP is whitelisted in your Master API database before running the installer.
2.  **Run the Installer:** Paste the installation command above into your terminal.
3.  **Network Configuration:** Follow the on-screen prompts to configure your IP, protocol (UDP recommended), and DNS resolvers. 
4.  **Completion:** The server will configure `iptables` NAT routing, deploy the UI, and start the OpenVPN engine. 

### 🖥️ Dashboard Access

Type `menu` to access the central control panel.

```bash
menu
```

---

## 🔌 Service Ports

| Service | Protocol | Port | Function |
| :--- | :--- | :--- | :--- |
| **OpenVPN Server** | UDP/TCP | 1194 | Primary VPN Tunnel |
| **Nginx Hub** | HTTP | 85 | Universal `.ovpn` File Server |
| **OVPN Management** | TCP | 7505 | Localhost API for the Sniper |

---

## ⚠️ Credits & Disclaimer

**Core OpenVPN Networking Engine, Dashboard, PAM Integration & Security Architecture:** Developed by [TheTechSavage](https://t.me/thetechsavage)

> *This project is for educational purposes and network management only. The developer is not responsible for misuse.*
