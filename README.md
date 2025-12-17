# 🚫 siteblock

A simple, lightweight command-line tool to block distracting websites on Linux by modifying `/etc/hosts`.

## Features

- ✅ Block websites by redirecting them to localhost
- ✅ Easy to configure via a simple text file
- ✅ Colored terminal output with status indicators
- ✅ Automatic DNS cache flushing
- ✅ Backup of original hosts file
- ✅ Reload functionality for updating block lists

## Installation

### Quick Install

```bash
git clone https://github.com/purushottamnawale/siteblock.git
cd siteblock
sudo ./install.sh
```

### Manual Install

```bash
# Copy the script
sudo cp siteblock.sh /usr/local/bin/siteblock
sudo chmod +x /usr/local/bin/siteblock

# Copy the config
sudo mkdir -p /etc/siteblock
sudo cp sites.txt /etc/siteblock/sites.txt
```

## Usage

```bash
# Block all configured sites
sudo siteblock block

# Unblock all sites
sudo siteblock unblock

# Reload block list after editing sites.txt
sudo siteblock reload

# Check current status
siteblock status

# List configured sites
siteblock list

# Show help
siteblock help
```

## Configuration

Edit the sites file to add or remove sites to block:

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

## Uninstallation

### Automatic Uninstall

```bash
sudo ./uninstall.sh
```

### Manual Uninstall

```bash
# Remove blocked sites first
sudo siteblock unblock

# Remove installed files
sudo rm /usr/local/bin/siteblock
sudo rm -rf /usr/local/share/siteblock
sudo rm -rf /etc/siteblock
```

## Requirements

- Linux (tested on Ubuntu, Debian, Fedora, Arch)
- Bash 4.0+
- Root/sudo access for blocking/unblocking

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Feel free to submit issues and pull requests.