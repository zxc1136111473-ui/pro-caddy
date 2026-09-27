#!/usr/bin/env bash
# 一次性初始化：把 Caddy 切成「一个域名一个文件」的结构，并装上 caddy-site 命令。
#   - 建 /etc/caddy/sites/
#   - /etc/caddy/Caddyfile 改成只有一行 import（原文件先备份）
#   - caddy-site 装到 /usr/local/bin
# 装完用 `caddy-site add <域名> <端口>` 加站点。
set -euo pipefail

[ "$(id -u)" = 0 ] || { echo "要 root：sudo bash install.sh" >&2; exit 1; }
command -v caddy >/dev/null 2>&1 || { echo "没装 caddy，先装 Caddy 再来：https://caddyserver.com/docs/install" >&2; exit 1; }

SRC="$(cd "$(dirname "$0")" && pwd)"
SITES_DIR=/etc/caddy/sites
CADDYFILE=/etc/caddy/Caddyfile

mkdir -p "$SITES_DIR"
install -m 0755 "$SRC/caddy-site" /usr/local/bin/caddy-site
echo "已装 /usr/local/bin/caddy-site"

if ! grep -q "import .*sites" "$CADDYFILE" 2>/dev/null; then
  if [ -f "$CADDYFILE" ]; then
    cp "$CADDYFILE" "$CADDYFILE.bak.$(date +%Y%m%d-%H%M%S)"
    echo "旧 Caddyfile 已备份（里面已有的站点块，装完请用 caddy-site add 重新加一遍）"
  fi
  printf 'import %s/*.caddy\n' "$SITES_DIR" > "$CADDYFILE"
  echo "Caddyfile 已改为：import $SITES_DIR/*.caddy"
fi

caddy validate --config "$CADDYFILE" --adapter caddyfile >/dev/null && echo "配置校验通过"
systemctl reload caddy 2>/dev/null || caddy reload --config "$CADDYFILE" --adapter caddyfile 2>/dev/null || true
echo
echo "完成。加站点：caddy-site add <域名> <本机端口>"
echo "        列站点：caddy-site list"
