AnarchyInTheUK

Reclaim Your Internet. Bypass Censorship. Empower Yourself.


---

💣 The Strategy

The UK is attempting to ban VPNs, block encryption, and impose identity verification to access the internet. This is not about safety. This is about control.

So we're fighting back with the ultimate loophole: SSH — a legitimate, industry-standard, pre-installed tool used by every developer and sysadmin on Earth.

Why SSH?

1. Ubiquitous – Installed on every Linux, Mac, and most Windows setups by default.


2. Essential – Banning SSH would break the tech industry.


3. Secure – True end-to-end encryption, no 3rd-party data logging.


4. Flexible – Create SOCKS proxies, port forwards, tunnels, and even obfuscation layers.



> If they want to ban this, they’ll have to ban the very infrastructure they depend on. Checkmate.




---

🧠 You Can't Stop the Signal

VPN apps can be banned. SSH cannot.

Cloud IPs can be blocked, but can they require ID for every one of millions of rotating VPSs?

Proxies can be traced, but ephemeral VPS tunnels can't.



---

⚡️ Benefits Over VPNs

Feature	SSH Tunnel	Commercial VPNs

True E2E Encryption	✅ Yes	❌ Sometimes (depends)
Zero Logging	✅ You control it	❌ Often logs exist
Real Anonymity	✅ Bring your own VPS	❌ ID often required
Speed	🚀 Unthrottled	🐢 Throttled/shared
Region Unlocking	✅ Any country you want	✅ Limited
Cost	💰$2–$5/mo VPS	💸 $10–$15/mo recurring


> Normies pay for slow spyware. We build faster, cheaper, private tunnels.




---

🚀 How to Install

You have two options:

🧪 Option 1: One-Liner (PowerShell)

Just open PowerShell as Administrator and paste this:

iex (iwr https://raw.githubusercontent.com/lmynl/AnarchyInTheUK/refs/heads/main/install-wsl-ssh-tun.ps1)

This will install everything, configure the tunnel, and create shortcuts.

🛠 Option 2: Manual Download

1. Download install-wsl-ssh-tun.ps1


2. Open PowerShell as Admin


3. Run:



Set-ExecutionPolicy Bypass -Scope Process -Force
./install-wsl-ssh-tun.ps1

It’ll prompt for your desired VPS address, generate your SSH keys, install WSL and OpenSSH, and create shortcuts (including desktop icons if you say yes).


---

🔐 VPS Configuration

After creating your VPS (see list below):

1. Harden SSH Config:

Edit /etc/ssh/sshd_config:

PasswordAuthentication no
PermitRootLogin no
LogLevel QUIET

2. Enable Key-Only Access:

mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys
# Paste in your public key
chmod 600 ~/.ssh/authorized_keys

3. Kill Logging:

Add this to your VPS provisioning script or manually run it as root:

# Disable persistent journald logs (without breaking logging entirely)
mkdir -p /etc/systemd/journald.conf.d
echo -e "[Journal]\nStorage=volatile\nSystemMaxUse=0" > /etc/systemd/journald.conf.d/anarchy.conf

# Wipe existing logs on boot (clean slate every time)
cat <<EOF > /etc/rc.local
#!/bin/bash
journalctl --vacuum-time=1s
truncate -s 0 /var/log/wtmp
truncate -s 0 /var/log/btmp
truncate -s 0 /var/log/lastlog
exit 0
EOF

chmod +x /etc/rc.local
systemctl enable rc-local


---

This keeps logging functional during runtime (so the system doesn't panic or misbehave) but non-persistent, and ensures logs are wiped at boot. It’s also distro-agnostic enough to work across most Debian-based and RHEL-based VPSes.
Use a tmpfs mount for /var/log if you want extra stealth.

4. Reboot for Clean Slate:

sudo reboot


---

💸 Some VPS Providers

Provider	Plan Name	CPU	RAM	Bandwidth	Est. Cost	Location Options

Hetzner	CX11	1	2GB	20TB	€4.15/mo	🇩🇪 🇫🇮 🇺🇸
Oracle Cloud	Always Free	4	24GB	10TB	Free*	🇺🇸 🇬🇧 🇮🇳 🇯🇵
Digital Ocean	Basic Droplet	1	1GB	1TB	$5/mo	🇺🇸 🇬🇧 🇸🇬 🇩🇪 🇯🇵
Linode	Nanode	1	1GB	1TB	$5/mo	🇺🇸 🇬🇧 🇩🇪 🇯🇵 🇸🇬
AWS Lightsail	Basic	1	0.5GB	1TB	$3.50/mo	🌍 Global


> *Oracle can be tricky to onboard due to account reviews. Use a burner domain & billing.




---

🛠 To-Do

[x] Windows installer

[x] Tunnel up/down scripts

[x] App group and desktop icons

[x] VPS config instructions

[ ] Easy VPS onboarding automation (coming soon)

[ ] QR codes for offline distribution



---

🧠 Final Thought: You Can't Ban Math

SSH is encryption. It’s math. You can’t legislate away math.

The more they crack down, the more elegant the resistance becomes. The people will route around the damage. You’re not a criminal — you’re a sysadmin of your own future.

Reclaim the internet. Reclaim your rights. Anarchy In The UK.


---

> Questions? Issues? Pull requests welcome.


# yes this is slop but thats how low effort it takes for uk gov bs



---

