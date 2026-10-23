#!/usr/bin/env bash
# EOPanel installer for Ubuntu/Debian.
#
# First node (runs the panel):
#   curl -sSL https://raw.githubusercontent.com/erikein/eopanel-install/main/install.sh | sudo bash
#
# Additional cluster nodes (no panel; joins the Swarm of the first node):
#   sudo bash install.sh --join <manager-ip> --token <join token from Settings > Cluster>
#
set -euo pipefail

IMAGE="${EOPANEL_IMAGE:-ghcr.io/erikein/eopanel:latest}"
DATA_DIR="${EOPANEL_DATA_DIR:-/etc/eopanel}"
JOIN_ADDR=""
JOIN_TOKEN=""

while [ $# -gt 0 ]; do
  case "$1" in
    --join) JOIN_ADDR="$2"; shift 2 ;;
    --token) JOIN_TOKEN="$2"; shift 2 ;;
    --image) IMAGE="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root (sudo)." >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com | sh
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker daemon is not running." >&2
  exit 1
fi

# ---- join mode: become a node of an existing EOPanel cluster ----
if [ -n "$JOIN_ADDR" ] || [ -n "$JOIN_TOKEN" ]; then
  if [ -z "$JOIN_ADDR" ] || [ -z "$JOIN_TOKEN" ]; then
    echo "--join and --token must be used together." >&2
    exit 1
  fi
  case "$JOIN_ADDR" in *:*) ;; *) JOIN_ADDR="$JOIN_ADDR:2377" ;; esac
  STATE="$(docker info --format '{{.Swarm.LocalNodeState}}')"
  if [ "$STATE" = "active" ]; then
    echo "This host is already part of a Swarm (state: active). Leave it first: docker swarm leave" >&2
    exit 1
  fi
  echo "Joining the cluster at $JOIN_ADDR"
  docker swarm join --token "$JOIN_TOKEN" "$JOIN_ADDR"
  echo
  echo "Joined. The node now appears in Settings > Cluster of the panel."
  echo "Tip: label it there (e.g. zone=b) and use labels in service Placement."
  exit 0
fi

# ---- panel mode ----
mkdir -p "$DATA_DIR"

if docker image inspect "$IMAGE" >/dev/null 2>&1 && [ "${EOPANEL_PULL:-auto}" != "always" ]; then
  echo "Using local image $IMAGE"
else
  echo "Pulling $IMAGE"
  docker pull "$IMAGE"
fi

echo "Running setup (Swarm init or reuse, networks, Traefik, panel service)"
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$DATA_DIR":/etc/eopanel \
  -e EOPANEL_PANEL_IMAGE="$IMAGE" \
  "$IMAGE" setup

IP="$(curl -4fsS https://ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
echo
echo "EOPanel is starting. Open http://${IP}:3000 to create the admin user."
echo "State lives in $DATA_DIR. To update later: docker pull $IMAGE && docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $DATA_DIR:/etc/eopanel $IMAGE setup"
echo "To add cluster nodes: sudo bash install.sh --join ${IP} --token <token from Settings > Cluster>"
