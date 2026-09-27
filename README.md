# pro-caddy

一台机器上跑多个项目、每个项目一个子域名时，用来管理 Caddy 反代的小工具。
加新项目就一条命令，不用手改一个大 Caddyfile，也不会因为一处写错就把所有站点的证书拖下水。

## 为什么

多个服务各绑在本机不同端口（`127.0.0.1:13000`、`8188`、`8613` …），
前面用一个 Caddy 按域名反代过去、自动申请续期 HTTPS。痛点是：
手改 `/etc/caddy/Caddyfile`，一个块写错，`reload` 整个失败，
连带别的站点证书也签不下来。

本工具把结构改成**一个域名一个文件**：

```
/etc/caddy/Caddyfile          →  只有一行： import /etc/caddy/sites/*.caddy
/etc/caddy/sites/a.example.com.caddy
/etc/caddy/sites/b.example.com.caddy
...
```

每次加/删都**先 `caddy validate` 通过再 `reload`**，配错自动回滚，不影响现有站点。

## 装

前提：已装 Caddy（系统服务方式），且它占着 80/443。

```bash
sudo bash install.sh
```

会建 `/etc/caddy/sites/`、把 `Caddyfile` 改成一行 `import`（原文件先备份）、
把 `caddy-site` 装到 `/usr/local/bin`。

> 如果原来的 `Caddyfile` 里已经有站点，装完用 `caddy-site add` 重新加一遍即可。

## 用

### 交互菜单（推荐，有新项目时最省事）

在终端直接敲，不带参数：

```bash
caddy-site
```

会列出当前站点；选「加站点」时**自动扫描本机服务**（Docker 容器 + 回环监听端口），
标出哪个已配域名、哪个还没配，选一个、填域名就配好。所以加新项目就三步：
①把服务绑到 `127.0.0.1:某端口` 起来 → ②`caddy-site` → ③选它、填域名。

### 命令行（脚本化用）

```bash
# 加：域名反代到本机某端口（会先查域名是否解析到本机，没解析直接拦住）
caddy-site add a.example.com 13000

# 反代到别的地址（默认 127.0.0.1）
caddy-site add a.example.com 8188 --host 172.17.0.1

# 域名还没解析好、只想先写上：
caddy-site add a.example.com 3000 --no-dns-check

# 删
caddy-site rm a.example.com

# 看所有站点和后端是否在线
caddy-site list

# 手动校验并重载
caddy-site reload
```

## 说明

- 只管反代和 HTTPS，不动各服务本身。服务请自己绑在 `127.0.0.1:<端口>`，
  这样除了 Caddy 谁都碰不到，公网只经过 80/443。
- `add` 的 DNS 预检是为了避免域名没解析就反复触发签发失败、撞
  [Let's Encrypt 限流](https://letsencrypt.org/docs/rate-limits/)。
- 证书由 Caddy 自动签发续期，本工具不碰证书文件。
