# ====================================

# 🔐 Bootcamp SSH - Autocommit Cron Setup

# ====================================

# Instructions for Fedora 43

# ====================================

## Quick Setup (Run these commands)

### 1. Make script executable

```bash
chmod +x /home/epti/Documents/epti-dev/bc-channel/bc-ssh/_scripts/autocommit.sh
```

### 2. Edit user crontab

```bash
crontab -e
```

### 3. Add this line (runs every 5 minutes)

```cron
*/5 * * * * /home/epti/Documents/epti-dev/bc-channel/bc-ssh/_scripts/autocommit.sh >> /home/epti/Documents/epti-dev/bc-channel/bc-ssh/_scripts/autocommit.log 2>&1
```

### 4. Verify cron is running (Fedora 43 uses cronie)

```bash
# Check if cronie is installed
rpm -q cronie

# If not installed
sudo dnf install cronie

# Enable and start cronie service
sudo systemctl enable crond
sudo systemctl start crond

# Check service status
sudo systemctl status crond
```

### 5. Verify crontab was saved

```bash
crontab -l
```

---

## Alternative: Systemd Timer (Recommended for Fedora)

Fedora prefers systemd timers over cron. Here's how to set it up:

### Create timer unit file

```bash
sudo nano /etc/systemd/user/bc-ssh-autocommit.timer
```

Content:

```ini
[Unit]
Description=Bootcamp SSH Autocommit Timer

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min
Unit=bc-ssh-autocommit.service

[Install]
WantedBy=timers.target
```

### Create service unit file

```bash
sudo nano /etc/systemd/user/bc-ssh-autocommit.service
```

Content:

```ini
[Unit]
Description=Bootcamp SSH Autocommit Service

[Service]
Type=oneshot
ExecStart=/home/epti/Documents/epti-dev/bc-channel/bc-ssh/_scripts/autocommit.sh
WorkingDirectory=/home/epti/Documents/epti-dev/bc-channel/bc-ssh

[Install]
WantedBy=default.target
```

### Enable the timer

```bash
systemctl --user daemon-reload
systemctl --user enable bc-ssh-autocommit.timer
systemctl --user start bc-ssh-autocommit.timer
```

### Check timer status

```bash
systemctl --user list-timers
systemctl --user status bc-ssh-autocommit.timer
```

---

## Useful Commands

### View autocommit log

```bash
tail -f /home/epti/Documents/epti-dev/bc-channel/bc-ssh/_scripts/autocommit.log
```

### Manually run the script

```bash
/home/epti/Documents/epti-dev/bc-channel/bc-ssh/_scripts/autocommit.sh
```

### Disable autocommit (cron)

```bash
crontab -e
# Comment or delete the autocommit line
```

### Disable autocommit (systemd)

```bash
systemctl --user stop bc-ssh-autocommit.timer
systemctl --user disable bc-ssh-autocommit.timer
```

---

## Commit Message Format

The script generates commits following this format:

```
<type>: <what> | <for> | <impact>
```

### Types (Conventional Commits)

- `feat`: New features (practices, projects)
- `docs`: Documentation (theory, resources, glossary)
- `style`: Visual assets (SVG diagrams)
- `chore`: Maintenance (scripts, configs)
- `refactor`: Content reorganization

### Examples

```
docs: week 1 theory modules | SSH concept learning | incremental progress
feat: week 2 practice exercises | hands-on skill development | significant content addition
chore: automation scripts | project maintenance | minor update
docs: bootcamp documentation | bootcamp documentation | major content milestone
```
