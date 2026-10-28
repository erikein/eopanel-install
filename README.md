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

## Migrating from EasyPanel (same server)

Run the same installer on the EasyPanel server. It detects EasyPanel and installs EOPanel next
to it on port **3001**, leaving ports 80/443 to EasyPanel until you decide to cut over. Your
containers keep running the whole time.

1. `curl -sSL https://raw.githubusercontent.com/erikein/eopanel-install/main/install.sh | sudo bash`
2. Open `http://<server-ip>:3001` and create the admin user.
3. Export EasyPanel's configuration (projects, services, env, domains, users):
   ```bash
   docker run --rm -v /etc/easypanel:/etc/easypanel:ro -v /etc/eopanel:/etc/eopanel \
     ghcr.io/erikein/eopanel:latest migrate-export
   ```
   It writes `/etc/eopanel/easypanel-export.json` (it contains passwords and tokens: delete it
   afterwards).
4. In EOPanel: **Settings › Migration**, upload that file with *adopt existing paths* on and
   *deploy* off. Services appear in the panel but nothing changes in Docker yet.
5. In **Settings › General** set your own base domain for services (EasyPanel's
   `*.easypanel.host` names stop working after the cut-over) and the Let's Encrypt e-mail.
6. Cut over (HTTP routing switches in a few seconds; containers are not restarted):
   ```bash
   docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v /etc/eopanel:/etc/eopanel \
     -v /etc/easypanel:/etc/easypanel:ro -e EOPANEL_PORT=3001 \
     -e EOPANEL_PANEL_IMAGE=ghcr.io/erikein/eopanel:latest \
     ghcr.io/erikein/eopanel:latest easypanel-cutover
   ```
   EasyPanel and its Traefik are scaled to 0 (not removed), its Let's Encrypt certificates are
   reused, and EOPanel's Traefik takes 80/443. Rollback at any time with `easypanel-rollback`
   in place of `easypanel-cutover`.
7. After a week without issues: `docker service rm easypanel easypanel-traefik`.

Data stays where it is (`/etc/easypanel/projects/...` and the existing volumes); EOPanel mounts
the same paths. Private registry images keep their credentials. Services that fail to redeploy
later because their upstream tag disappeared fall back to the local image.

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
