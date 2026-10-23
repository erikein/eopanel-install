# EOPanel installer

Public installer for [EOPanel](https://github.com/erikein/eopanel), a self-hosted PaaS on Docker
Swarm + Traefik: apps from GitHub/Git/Docker images, managed databases, Compose stacks, automatic
HTTPS, backups, monitoring, templates, per-container logs and shell, EasyPanel migration, an MCP
server for AI assistants and a built-in AI chat.

The panel image is published at `ghcr.io/erikein/eopanel`.

## Install (Ubuntu 22.04+/24.04, fresh server, ports 80, 443 and 3000 free)

```bash
curl -sSL https://raw.githubusercontent.com/erikein/eopanel-install/main/install.sh | sudo bash
```

Then open `http://<server-ip>:3000`, create the admin user and set the panel domain in Settings.

## Add a node to the cluster

On the new server:

```bash
curl -sSLo install.sh https://raw.githubusercontent.com/erikein/eopanel-install/main/install.sh
sudo bash install.sh --join <manager-ip> --token <token from Settings > Cluster>
```

## Update

```bash
docker pull ghcr.io/erikein/eopanel:latest
docker service update --force --image ghcr.io/erikein/eopanel:latest eopanel
```

## Options

| Variable / flag | Default | Purpose |
|---|---|---|
| `EOPANEL_IMAGE` | `ghcr.io/erikein/eopanel:latest` | image to run |
| `EOPANEL_DATA_DIR` | `/etc/eopanel` | state directory |
| `--join <addr> --token <tok>` | | join an existing cluster instead of installing the panel |
