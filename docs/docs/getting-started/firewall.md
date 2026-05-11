# Firewall

GreymHatter uses `firewalld` with a default policy that allows SSH, Samba, HTTPS, and the web service ports. During troubleshooting, you may need to temporarily disable the firewall or add rules.

## Check Status

```bash
# Firewall state
sudo firewall-cmd --state

# List all allowed services and ports
sudo firewall-cmd --list-all
```

## Temporarily Disable

Useful when troubleshooting connectivity issues:

```bash
# Disable firewall (until next reboot)
sudo systemctl stop firewalld

# Re-enable firewall
sudo systemctl start firewalld
```

!!! warning
    Only disable the firewall temporarily for troubleshooting. Re-enable it when done.

## Permanently Disable

Not recommended, but available for isolated lab environments:

```bash
sudo systemctl disable --now firewalld
```

## Add a Service or Port

```bash
# Allow a service (e.g., http)
sudo firewall-cmd --add-service=http --permanent

# Allow a specific port
sudo firewall-cmd --add-port=9090/tcp --permanent

# Apply changes
sudo firewall-cmd --reload
```

## Remove a Service or Port

```bash
sudo firewall-cmd --remove-service=http --permanent
sudo firewall-cmd --remove-port=9090/tcp --permanent
sudo firewall-cmd --reload
```

## Default Allowed Services

| Service / Port | Purpose |
|---|---|
| `ssh` (22) | Remote shell access |
| `samba` (445) | File sharing |
| `https` (443) | Timesketch |
| 3000/tcp | Homepage dashboard |
| 3389/tcp | xRDP remote desktop |
| 5001/tcp | SpiderFoot |
| 5900/tcp | VNC |
| 8000/tcp | Course materials |
| 8080/tcp | CyberChef |
| 8888/tcp | Yeti |
