## xray_docker_xhttp_reality_relay

xray vless+xhttp+reality 中转 (relay/落地链式) docker 镜像

## 网络拓扑

```
client --> VPS A (本镜像, vless+xhttp+reality 中转) --> VPS B (reality 镜像, 落地)
```

VPS A 对客户端而言是一个完整的 vless+xhttp+reality 服务端（与 `xhttp_reality` 镜像配置方式相同，
拥有自己的 UUID / 私钥 / SERVERNAMES / XHTTP_PATH）。客户端解密后的流量不会直接从 VPS A 出站，
而是作为客户端再次通过一条 vless+reality(tcp) 连接转发给 VPS B（运行 `reality` 镜像）。
最终出站 IP 为 VPS B 的 IP。

## VPS B 准备

VPS B 直接使用本仓库的 `reality` 镜像正常部署即可，无需任何修改。
部署完成后从 VPS B 的 `/config_info.txt` 中获取以下信息，供 VPS A 使用：
UUID、PUBLICKEY、SERVERNAMES（取一个作为 SNI）、PORT、SHORTID（如有）。

## 构建docker镜像
```
docker build -t xray_docker_xhttp_reality_relay:latest -f Dockerfile .
```

## 懒人一键安装（docker已经准备好）

将 `VPSB_*` 替换为 VPS B `/config_info.txt` 中的对应值

```
EXTERNAL_PORT=2333 && \
docker run -d --name xray_xhttp_reality_relay_freeman --restart=always --log-opt max-size=100m --log-opt max-file=3 \
  -p $EXTERNAL_PORT:443 \
  -e EXTERNAL_PORT=$EXTERNAL_PORT \
  -e VPSB_ADDR="VPSB_IP_OR_DOMAIN" \
  -e VPSB_UUID="VPSB_UUID" \
  -e VPSB_PUBLICKEY="VPSB_PUBLICKEY" \
  -e VPSB_SERVERNAME="VPSB_SERVERNAME" \
  xray_docker_xhttp_reality_relay:latest \
&& sleep 3 && docker exec -it xray_xhttp_reality_relay_freeman cat /config_info.txt
```

## 懒人一键安装（IP6，服务器需要支持IP6）
```
EXTERNAL_PORT=1234 && \
docker run -d --name xray_xhttp_reality_relay_freeman \
  --network host \
  --restart=always \
  --log-opt max-size=100m --log-opt max-file=3 \
  -e HOSTMODE_PORT=$EXTERNAL_PORT \
  -e EXTERNAL_PORT=$EXTERNAL_PORT \
  -e VPSB_ADDR="VPSB_IP_OR_DOMAIN" \
  -e VPSB_UUID="VPSB_UUID" \
  -e VPSB_PUBLICKEY="VPSB_PUBLICKEY" \
  -e VPSB_SERVERNAME="VPSB_SERVERNAME" \
  xray_docker_xhttp_reality_relay:latest \
&& sleep 3 \
&& docker exec -it xray_xhttp_reality_relay_freeman cat /config_info.txt
```

## 懒人一键安装（docker已经准备好），指定PRIVATEKEY, UUID
```
EXTERNAL_PORT=2333 && \
docker run -d --name xray_xhttp_reality_relay_freeman --restart=always --log-opt max-size=100m --log-opt max-file=3 \
  -p $EXTERNAL_PORT:443 \
  -e EXTERNAL_PORT=$EXTERNAL_PORT \
  -e PRIVATEKEY="XXX" -e UUID="XXX" \
  -e VPSB_ADDR="VPSB_IP_OR_DOMAIN" \
  -e VPSB_UUID="VPSB_UUID" \
  -e VPSB_PUBLICKEY="VPSB_PUBLICKEY" \
  -e VPSB_SERVERNAME="VPSB_SERVERNAME" \
  xray_docker_xhttp_reality_relay:latest \
&& sleep 3 && docker exec -it xray_xhttp_reality_relay_freeman cat /config_info.txt
```

## 基础使用方法

如果你没有安装 docker 请先安装 docker

```
curl -fsSL https://get.docker.com | sh
```

### 端口映射模式
如果你已经安装 docker，可以直接使用下面的命令，运行后会自动下载镜像并启动容器，
EXTERNAL_PORT 为你想要使用的端口，如下所示，你将使用443端口

```
docker pull xray_docker_xhttp_reality_relay:latest
EXTERNAL_PORT=443
docker run -d --name xray_xhttp_reality_relay_freeman --restart=always --log-opt max-size=100m --log-opt max-file=3 \
  -p $EXTERNAL_PORT:443 \
  -e EXTERNAL_PORT=$EXTERNAL_PORT \
  -e VPSB_ADDR="VPSB_IP_OR_DOMAIN" \
  -e VPSB_UUID="VPSB_UUID" \
  -e VPSB_PUBLICKEY="VPSB_PUBLICKEY" \
  -e VPSB_SERVERNAME="VPSB_SERVERNAME" \
  xray_docker_xhttp_reality_relay:latest
```

### host 模式
如果你想使用 host 模式，你可以使用以下命令，运行后会自动下载镜像并启动容器，
HOSTMODE_PORT 为你想要使用的端口，如下所示，你将使用443端口
>请注意，如果你使用 host 模式，EXTERNAL_PORT 变量将不会生效，请使用 HOSTMODE_PORT 变量

```
docker pull xray_docker_xhttp_reality_relay:latest
HOSTMODE_PORT=443
docker run -d --name xray_xhttp_reality_relay_freeman --restart=always --log-opt max-size=100m --log-opt max-file=3 \
  --network host \
  -e HOSTMODE_PORT=$HOSTMODE_PORT \
  -e VPSB_ADDR="VPSB_IP_OR_DOMAIN" \
  -e VPSB_UUID="VPSB_UUID" \
  -e VPSB_PUBLICKEY="VPSB_PUBLICKEY" \
  -e VPSB_SERVERNAME="VPSB_SERVERNAME" \
  xray_docker_xhttp_reality_relay:latest
```

查看日志获取配置信息（包含 VPS A 自己的订阅链接/二维码），如下所示，按照提示配置客户端即可

```
docker logs -f xray_xhttp_reality_relay_freeman
```

## 进阶使用方法
如果你不想使用 443 端口，你可以自定义端口，例如使用 8443 端口，如下所示

```
EXTERNAL_PORT=8446
docker run -d --name xray_xhttp_reality_relay_freeman --restart=always --log-opt max-size=100m --log-opt max-file=3 \
  -p $EXTERNAL_PORT:443 \
  -e EXTERNAL_PORT=$EXTERNAL_PORT \
  -e VPSB_ADDR="VPSB_IP_OR_DOMAIN" \
  -e VPSB_UUID="VPSB_UUID" \
  -e VPSB_PUBLICKEY="VPSB_PUBLICKEY" \
  -e VPSB_SERVERNAME="VPSB_SERVERNAME" \
  xray_docker_xhttp_reality_relay:latest
```

如果你想启动多个 relay 服务，你可以使用不同的容器名，并注意端口不要冲突，如下所示你将启动两个 relay 服务，分别使用444和445端口

```
EXTERNAL_PORT=444
docker run -d --name xray_xhttp_reality_relay_freeman_1 --restart=always --log-opt max-size=100m --log-opt max-file=3 \
  -p $EXTERNAL_PORT:443 \
  -e EXTERNAL_PORT=$EXTERNAL_PORT \
  -e VPSB_ADDR="VPSB_IP_OR_DOMAIN" \
  -e VPSB_UUID="VPSB_UUID" \
  -e VPSB_PUBLICKEY="VPSB_PUBLICKEY" \
  -e VPSB_SERVERNAME="VPSB_SERVERNAME" \
  xray_docker_xhttp_reality_relay:latest

EXTERNAL_PORT=445
docker run -d --name xray_xhttp_reality_relay_freeman_2 --restart=always --log-opt max-size=100m --log-opt max-file=3 \
  -p $EXTERNAL_PORT:443 \
  -e EXTERNAL_PORT=$EXTERNAL_PORT \
  -e VPSB_ADDR="VPSB_IP_OR_DOMAIN" \
  -e VPSB_UUID="VPSB_UUID" \
  -e VPSB_PUBLICKEY="VPSB_PUBLICKEY" \
  -e VPSB_SERVERNAME="VPSB_SERVERNAME" \
  xray_docker_xhttp_reality_relay:latest
```

如果你不想使用默认参数，你可以自定义参数，例如使用自定义的 UUID, 以及自定义目标地址和服务器名称，如下所示，**支持的自定义参数请参考下方环境变量说明**

存在多个 SERVERNAMES 时使用空格分开，例如：addons.mozilla.org

请注意，如果你使用自定义参数，你需要自己保证参数的正确性，否则可能会导致容器无法启动
```
EXTERNAL_PORT=443
docker run -d --name xray_xhttp_reality_relay_freeman --restart=always --log-opt max-size=100m --log-opt max-file=3 \
  -p $EXTERNAL_PORT:443 \
  -e EXTERNAL_PORT=$EXTERNAL_PORT \
  -e UUID="XXX" \
  -e SERVERNAMES="addons.mozilla.org" \
  -e DEST="addons.mozilla.org:443" \
  -e PRIVATEKEY="XXX" \
  -e XHTTP_PATH="/xxxxxxxx" \
  -e VPSB_ADDR="VPSB_IP_OR_DOMAIN" \
  -e VPSB_PORT="443" \
  -e VPSB_UUID="VPSB_UUID" \
  -e VPSB_PUBLICKEY="VPSB_PUBLICKEY" \
  -e VPSB_SERVERNAME="VPSB_SERVERNAME" \
  -e VPSB_SHORTID="" \
  -e VPSB_FLOW="xtls-rprx-vision" \
  xray_docker_xhttp_reality_relay:latest
```

使用以下命令删除已经创建的容器，如下所示，需要将 xray_xhttp_reality_relay_freeman 替换为你自己的容器名 (--name 所设置的名称)

```
docker rm -f xray_xhttp_reality_relay_freeman
```

## 环境变量

你可以设置以下环境变量来自定义 XRay 的配置。

### 客户端连接 VPS A 所需（与 `xhttp_reality` 镜像一致）

* UUID：XRay 的唯一用户标识符。若未设置，脚本将自动生成一个随机 UUID。
* DEST：目标地址。默认值为 addons.mozilla.org:443。
* SERVERNAMES：服务器名称列表。默认值为 addons.mozilla.org。
* PRIVATEKEY：私钥。若未设置，脚本将自动生成一个新的私钥和对应的公钥。
* NETWORK：网络类型。默认值为 xhttp，不要进行修改。
* XHTTP_PATH：XHTTP 路径。若未设置，脚本将自动生成一个随机路径。
* EXTERNAL_PORT：客户端连接端口（端口映射模式下用于生成订阅链接/二维码）。默认值为 443。
* HOSTMODE_PORT：host 网络模式下的实际监听端口，设置后会覆盖 EXTERNAL_PORT。

### 转发到 VPS B 所需（取自 VPS B 的 config_info.txt）

| 变量            | 必填 | 默认值          | 说明                              |
|-----------------|------|-----------------|------------------------------------|
| VPSB_ADDR       | 是   | 无              | VPS B 的 IP / 域名                 |
| VPSB_PORT       | 否   | 443             | VPS B 监听端口                     |
| VPSB_UUID       | 是   | 无              | VPS B 上配置的 UUID                |
| VPSB_PUBLICKEY  | 是   | 无              | VPS B 的 PUBLICKEY/PASSWORD        |
| VPSB_SERVERNAME | 是   | 无              | VPS B 的 SERVERNAMES 中任选一个     |
| VPSB_SHORTID    | 否   | ""              | VPS B 的 shortId（默认空）          |
| VPSB_FLOW       | 否   | xtls-rprx-vision| VPS B inbound 的 flow              |

> VPS A 转发到 VPS B 的端口由 `VPSB_PORT` 单独控制（默认 443），与客户端连接 VPS A 的端口无关。

## 常量
* 客户端 <-> VPS A：flow 留空，security: reality，transport: xhttp
* VPS A <-> VPS B：flow: xtls-rprx-vision，security: reality，transport: tcp，shortIds 留空

## 注意事项

请确保在使用前已正确安装和配置 XRay 客户端。
为了保证安全和稳定，请勿将 UUID、私钥等敏感信息泄露给他人。

- 修改任意环境变量后，需要删除容器内的 `/config_info.txt` 并重启容器才会重新生成配置。
- VPS A 与 VPS B 之间的 vless+reality 连接使用 `xtls-rprx-vision`，请确保两端均使用 `tcp` 传输。
- VPS B 上的路由规则（屏蔽 CN/私有 IP、视频网站等）依然生效，最终出站仍以 VPS B 的策略为准。
