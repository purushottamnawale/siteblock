# 🚫 siteblock

![License](https://img.shields.io/github/license/purushottamnawale/siteblock)
![Issues](https://img.shields.io/github/issues/purushottamnawale/siteblock)
![Pull Requests](https://img.shields.io/github/issues-pr/purushottamnawale/siteblock)

A simple, lightweight, and robust command-line tool to block distracting websites on Linux and macOS by modifying `/etc/hosts`.

## Features

- 🔒 **Block Websites**: Redirects distracting sites to localhost (127.0.0.1).
- ⚡ **Easy Configuration**: Manage sites via CLI commands or a simple text file.
- 🎨 **Visual Feedback**: Colored terminal output with clear status indicators.
- 🔄 **Smart DNS**: Automatic DNS cache flushing for immediate effect.
- 🛡️ **Safe**: Automatically backs up your original hosts file.
- 🌍 **Cross-Platform**: Works on Linux (Systemd, nscd) and macOS.

## Installation

### One-Line Install (Recommended)

You can install siteblock directly without cloning the repository:

**Using wget:**
```bash
wget -O - https://raw.githubusercontent.com/purushottamnawale/siteblock/main/install.sh | sudo bash
```

**Using curl:**
```bash
curl -fsSL https://raw.githubusercontent.com/purushottamnawale/siteblock/main/install.sh | sudo bash
```

### Manual Install (From Source)

```bash
git clone https://github.com/purushottamnawale/siteblock.git
cd siteblock
sudo ./install.sh
```

## Usage

### Basic Commands

| Command | Description |
|---------|-------------|
| `sudo siteblock block` | **Enable blocking** for all configured sites. |
| `sudo siteblock unblock` | **Disable blocking** (restore access to all sites). |
| `siteblock status` | Check if blocking is currently active. |
| `siteblock list` | View the list of sites currently configured to be blocked. |

### Managing Sites

| Command | Description |
|---------|-------------|
| `sudo siteblock add <domain>` | Add a domain (and its `www` subdomain) to the block list. |
| `sudo siteblock remove <domain>` | Remove a domain from the block list. |
| `sudo siteblock reload` | Reload the block list from the configuration file (useful after manual edits). |

### Other

| Command | Description |
|---------|-------------|
| `siteblock version` | Show the installed version. |
| `siteblock help` | Display the help message. |
| `sudo siteblock uninstall` | Uninstall siteblock from your system. |

### Examples

```bash
# Start focusing!
sudo siteblock block

# Add a new distraction
sudo siteblock add facebook.com

# Take a break
sudo siteblock unblock
```

## Configuration

While the CLI commands (`add`/`remove`) are recommended, you can also manually edit the configuration file.

**File Location:** `/etc/siteblock/sites.txt`

```bash
sudo nano /etc/siteblock/sites.txt
```

### sites.txt Format

```
# Comments start with #
# Format: <ip> <hostname>

127.0.0.1 facebook.com
127.0.0.1 www.facebook.com
127.0.0.1 twitter.com
127.0.0.1 www.twitter.com
```

> **Tip:** Always block both the root domain and `www.` subdomain for complete blocking.

## How It Works

siteblock works by appending entries to `/etc/hosts` that redirect specified domains to `127.0.0.1` (localhost). When your browser tries to access a blocked site, it gets redirected to your local machine instead, effectively blocking access.

The entries are wrapped in markers (`# SITEBLOCK-BEGIN` and `# SITEBLOCK-END`) so they can be easily identified and removed.

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SITEBLOCK_SITES_FILE` | Custom path to sites.txt | `/etc/siteblock/sites.txt` |

## Requirements

- **OS**: Linux (Ubuntu, Debian, Fedora, Arch, etc.) or macOS.
- **Shell**: Bash (recommended: Bash 4+)
- **Permissions**: Root/sudo access is required for modifying `/etc/hosts`.

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Uninstall

To remove siteblock from your system:

**Option 1: CLI (if installed)**
```bash
sudo siteblock uninstall
```

Remove everything (including `/etc/siteblock` and `/etc/hosts.siteblock.bak`):
```bash
sudo siteblock uninstall --all
```

**Option 2: One-Line Script**
```bash
curl -fsSL https://raw.githubusercontent.com/purushottamnawale/siteblock/main/uninstall.sh | sudo bash
```

Non-interactive full removal:
```bash
curl -fsSL https://raw.githubusercontent.com/purushottamnawale/siteblock/main/uninstall.sh | sudo bash -s -- --all
```