<#
.SYNOPSIS
  Normie‐proof installer for SSH TUNNEL over WSL2 on Windows.

.DESCRIPTION
  - Self‐elevates via UAC
  - Enables WSL2 & Virtual Machine Platform
  - Installs Ubuntu under WSL
  - Installs openssh-client & iproute2 in Ubuntu
  - Generates an ED25519 SSH key in WSL, exports public key to Windows
  - Prompts for your VPS IP & SSH user
  - Prompts for Start Menu group name & whether to add Desktop icons
  - Writes `tun-up.ps1` & `tun-down.ps1` helpers into ProgramData
  - Creates a README.txt in ProgramData explaining next steps
  - Creates Start Menu shortcuts (and Desktop icons if requested)

.NOTES
  - Run once, as Administrator
  - Designed for Windows 10/11 with built‐in OpenSSH & WSL2 support
#>

#region Self‐elevation
If (-Not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
  Write-Host "🚀 Elevating to Administrator..." -ForegroundColor Cyan
  Start-Process -FilePath pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
  Exit
}
#endregion

#region ExecutionPolicy Bypass
Write-Host "🔓 Bypassing PowerShell script policy for this session..." -ForegroundColor Cyan
Set-ExecutionPolicy Bypass -Scope Process -Force
#endregion

#region Prompts
$VPS_IP     = Read-Host "▶ Enter your VPS IP address (e.g. 203.0.113.5)"
$SSH_USER   = Read-Host "▶ Enter the SSH username on your VPS (e.g. ubuntu)"
$MenuGroup  = Read-Host "▶ Enter a name for the Start Menu folder (e.g. SSH Tunnel)"
$MakeDesktop = Read-Host "▶ Create Desktop icons? (Y/N)"
Write-Host ""
#endregion

#region Enable WSL2 & VM Platform
Write-Host "🛠️  Enabling WSL2 and Virtual Machine Platform features..." -ForegroundColor Cyan
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform       /all /norestart | Out-Null
#endregion

#region Install Ubuntu under WSL
Write-Host "⬇️  Installing Ubuntu (quietly)..." -ForegroundColor Cyan
wsl --install -d Ubuntu --quiet
wsl --set-default-version 2
#endregion

#region Install SSH client & iproute2 in WSL
Write-Host "🐧 Configuring Linux: updating & installing SSH client + iproute2..." -ForegroundColor Cyan
wsl -u root -- bash -lc "
  apt-get update -qq &&
  DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-client iproute2 >/dev/null
"
#endregion

#region Generate SSH key in WSL & export public key
Write-Host "🔑 Generating ED25519 SSH key in WSL (if none exists)..." -ForegroundColor Cyan
wsl -u root -- bash -lc '
  mkdir -p ~/.ssh && chmod 700 ~/.ssh
  if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" \
      -C "wsl-ssh-tun@$(hostname)"
  fi
  cp ~/.ssh/id_ed25519.pub /mnt/c/Users/Public/ssh-tunnel.pub
  chmod 644 /mnt/c/Users/Public/ssh-tunnel.pub
'
Write-Host "✔ Public key copied to C:\Users\Public\ssh-tunnel.pub" -ForegroundColor Green
Write-Host ""

#region Prepare installation folder
$InstallDir = "$env:ProgramData\SSH-Tunnel"
Write-Host "📁 Creating install directory: $InstallDir" -ForegroundColor Cyan
New-Item -Path $InstallDir -ItemType Directory -Force | Out-Null
#endregion

#region Write tun-up.ps1
Write-Host "✍️  Writing tun-up.ps1 helper..." -ForegroundColor Cyan
@"
param(
  [string]\$VPS_IP   = "$VPS_IP",
  [string]\$SSH_USER = "$SSH_USER"
)
# store current gateway
\$gw = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Where-Object NextHop -ne "0.0.0.0").NextHop
Set-Content -Path "\$env:ProgramData\wsl-tun-gateway.txt" -Value \$gw

# launch SSH tunnel over WSL
Start-Process wsl -ArgumentList "-u root -- ssh -N -w 0:0 -o Tunnel=point-to-point -i /root/.ssh/id_ed25519","\$SSH_USER@\$VPS_IP" -NoNewWindow

# configure tun0 & route inside WSL
wsl -u root -- bash -lc "ip addr add 10.99.99.2/30 dev tun0 2>/dev/null; ip link set tun0 up; ip route replace default via 10.99.99.1 dev tun0"

# route Windows through WSL interface
\$wslIP = (Get-NetIPAddress -InterfaceAlias 'vEthernet (WSL)' -AddressFamily IPv4).IPAddress
route delete 0.0.0.0
route add 0.0.0.0 mask 0.0.0.0 \$wslIP -p

Write-Host '✔ Tunnel is UP!' -ForegroundColor Green
"@ | Set-Content -Path "$InstallDir\tun-up.ps1" -Force
#endregion

#region Write tun-down.ps1
Write-Host "✍️  Writing tun-down.ps1 helper..." -ForegroundColor Cyan
@"
# stop SSH in WSL
wsl -u root -- pkill ssh

# teardown tun0 & restore WSL route
wsl -u root -- bash -lc 'ip link set tun0 down 2>/dev/null; ip route replace default via \$(ip route show default | awk \"{print \$3}\") dev eth0'

# restore Windows gateway
\$gwFile = "\$env:ProgramData\wsl-tun-gateway.txt"
if (Test-Path \$gwFile) {
  \$orig = Get-Content \$gwFile
  route delete 0.0.0.0
  route add 0.0.0.0 mask 0.0.0.0 \$orig -p
  Remove-Item \$gwFile -Force
  Write-Host "✔ Gateway restored to \$orig" -ForegroundColor Yellow
} else {
  Write-Warning "No saved gateway found; you may need to reboot."
}
Write-Host '✔ Tunnel is DOWN!' -ForegroundColor Red
"@ | Set-Content -Path "$InstallDir\tun-down.ps1" -Force
#endregion

#region Write README
Write-Host "📝 Creating README..." -ForegroundColor Cyan
@"
SSH-Tunnel Installer README
===========================

1) Your public key is here:
   C:\Users\Public\ssh-tunnel.pub
   └── Copy its contents into your VPS:
       mkdir -p ~/.ssh && chmod 700 ~/.ssh
       echo '<paste key>' >> ~/.ssh/authorized_keys
       chmod 600 ~/.ssh/authorized_keys

2) Launch 'Tunnel Up' to start the SSH-TUNNEL:
   - Routes ALL Windows traffic through your VPS.
   - Requires WSL2 & internet.

3) Launch 'Tunnel Down' to stop and restore your network.

4) If you reboot, run 'Tunnel Up' again before browsing.

Enjoy your private, SSH-based VPN! 🚀
"@ | Set-Content -Path "$InstallDir\README.txt" -Force
#endregion

#region Create Start Menu folder & shortcuts
$StartMenuDir = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\$MenuGroup"
Write-Host "📂 Creating Start Menu group: $MenuGroup" -ForegroundColor Cyan
New-Item -Path $StartMenuDir -ItemType Directory -Force | Out-Null
$shell = New-Object -ComObject WScript.Shell

foreach ($item in @(
  @{ Name="Tunnel Up"; Script="tun-up.ps1" },
  @{ Name="Tunnel Down"; Script="tun-down.ps1" }
)) {
  Write-Host "🔖 Creating shortcut: $($item.Name)" -ForegroundColor Cyan
  $lnk = $shell.CreateShortcut("$StartMenuDir\$($item.Name).lnk")
  $lnk.TargetPath     = "powershell.exe"
  $lnk.Arguments      = "-ExecutionPolicy Bypass -NoProfile -File `"$InstallDir\$($item.Script)`""
  $lnk.WorkingDirectory = $InstallDir
  $lnk.IconLocation   = "shell32.dll,10"
  $lnk.Save()
}
#endregion

#region Desktop Icons (optional)
if ($MakeDesktop.Trim().ToUpper() -eq 'Y') {
  $PublicDesktop = "$env:PUBLIC\Desktop"
  Write-Host "🖥️  Creating Desktop icons..." -ForegroundColor Cyan
  foreach ($item in @("Tunnel Up","Tunnel Down")) {
    $src = "$StartMenuDir\$item.lnk"
    $dst = "$PublicDesktop\$item.lnk"
    Copy-Item -Path $src -Destination $dst -Force
  }
}
#endregion

Write-Host "`n🎉 Installation COMPLETE!`n" -ForegroundColor Green
Write-Host "▶ Visit Start → $MenuGroup → Tunnel Up / Tunnel Down" -ForegroundColor Green
if ($MakeDesktop.Trim().ToUpper() -eq 'Y') {
  Write-Host "▶ You also have Desktop icons available." -ForegroundColor Green
}
Write-Host "▶ Read the README at $InstallDir\README.txt for next steps." -ForegroundColor Green
