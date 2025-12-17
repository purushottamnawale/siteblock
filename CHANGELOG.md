# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-17

### Added
- Initial release of siteblock.
- `block` command to block sites configured in `sites.txt`.
- `unblock` command to remove blocks.
- `add` command to easily add domains to the block list.
- `remove` command to remove domains from the block list.
- `status` command to check current blocking status.
- `list` command to view configured sites.
- `version` command to check installed version.
- `uninstall` command for easy removal.
- Automatic DNS cache flushing for Linux (systemd-resolved, resolvectl, nscd) and macOS.
- Backup of `/etc/hosts` before modification.
- Installation and uninstallation scripts.
