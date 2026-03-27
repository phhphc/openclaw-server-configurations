# openclaw-server-configurations

Fresh server setup script for Ubuntu. Installs packages, creates users, and configures the shell environment.

## What it does

- **Packages** — `git`, `unzip`, `file`, `ripgrep`, `libreoffice`, Python 3 libs (`pip`, `openpyxl`, `python-docx`), Node.js 24, Neovim, and Yazi (via snap)
- **Users** — Creates `clara` and `atlas`, enables systemd linger, and sets up `~/.config/systemd/user`
- **Neovim** — Installs [custom Neovim config](https://github.com/phhphc/neovim-config) for each user
- **Shell** — Appends a [Yazi `y` wrapper](https://yazi-rs.github.io/docs/quick-start#shell-wrapper) and [OpenClaw startup optimisations](https://docs.openclaw.ai/vps) to each user's `.bashrc` (idempotent)

## Install

Run as root on a fresh Ubuntu server:

```bash
curl -fsSL https://raw.githubusercontent.com/phhphc/openclaw-server-configurations/main/setup.sh | bash
```

Reboot after the script completes if prompted.

### Microsoft fonts (optional)

Installs Microsoft core fonts (Times New Roman, Arial, Courier New, etc.). Run separately as it requires interactive acceptance of the Microsoft EULA:

```bash
curl -fsSL https://raw.githubusercontent.com/phhphc/openclaw-server-configurations/main/setup_fonts.sh | bash
```
