#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/Vatnik12/Hakaton.git"
APP_DIR="/opt/svoi"
DEPLOY_USER="deploy"

if [ "$(id -u)" -ne 0 ]; then
  echo "Запустите через sudo: sudo bash deploy/setup-server.sh"
  exit 1
fi

apt-get update
apt-get install -y ca-certificates curl git openssh-server
if ! command -v docker >/dev/null 2>&1; then curl -fsSL https://get.docker.com | sh; fi
systemctl enable --now docker
systemctl enable --now ssh

if ! id "$DEPLOY_USER" >/dev/null 2>&1; then useradd -m -s /bin/bash "$DEPLOY_USER"; fi
usermod -aG docker "$DEPLOY_USER"
mkdir -p "$APP_DIR"
chown -R "$DEPLOY_USER":"$DEPLOY_USER" "$APP_DIR"

if [ ! -d "$APP_DIR/.git" ]; then
  sudo -u "$DEPLOY_USER" git clone "$REPO_URL" "$APP_DIR"
else
  sudo -u "$DEPLOY_USER" git -C "$APP_DIR" fetch origin main
  sudo -u "$DEPLOY_USER" git -C "$APP_DIR" reset --hard origin/main
fi

cat > /usr/local/bin/deploy-svoi <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
cd /opt/svoi
git fetch origin main
git reset --hard origin/main
docker compose up -d --build --remove-orphans
docker image prune -f >/dev/null 2>&1 || true
SCRIPT
chmod 755 /usr/local/bin/deploy-svoi
sudo -u "$DEPLOY_USER" /usr/local/bin/deploy-svoi

SSH_DIR="/home/$DEPLOY_USER/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
chown "$DEPLOY_USER":"$DEPLOY_USER" "$SSH_DIR"
TMP_KEY="$(mktemp -u /tmp/svoi-actions-key.XXXXXX)"
ssh-keygen -t ed25519 -N "" -C "github-actions-svoi" -f "$TMP_KEY" >/dev/null
cat "$TMP_KEY.pub" >> "$SSH_DIR/authorized_keys"
sort -u "$SSH_DIR/authorized_keys" -o "$SSH_DIR/authorized_keys"
chmod 600 "$SSH_DIR/authorized_keys"
chown -R "$DEPLOY_USER":"$DEPLOY_USER" "$SSH_DIR"

SERVER_IP="$(curl -4 -fsS https://api.ipify.org || hostname -I | awk '{print $1}')"
echo
echo "============================================================"
echo "Сайт запущен: http://$SERVER_IP"
echo "SERVER_HOST=$SERVER_IP"
echo "SERVER_USER=$DEPLOY_USER"
echo "SSH_PRIVATE_KEY:"
cat "$TMP_KEY"
echo "============================================================"
rm -f "$TMP_KEY" "$TMP_KEY.pub"
