# builder
FROM golang:alpine AS builder
LABEL maintainer="freeman <freeman@gmail.com>"
LABEL version="0.0.29"


#ENV GOPROXY=https://goproxy.cn,direct
WORKDIR /app

RUN apk add --no-cache git curl jq && \ 
    LATEST_VERSION_TAG=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases | jq -r '.[0].tag_name') && \
    git clone https://github.com/XTLS/Xray-core.git . && \
    git checkout $LATEST_VERSION_TAG && \
    go mod download -x && \
    go build -v -o xray /app/main/

# runner
FROM alpine:latest AS runner


ENV UUID=""
ENV DEST=""
ENV SERVERNAMES=""
ENV PRIVATEKEY=""
ENV SHORTIDS=""
ENV NETWORK=""
ENV INTERNAL_PORT=""
ENV HOSTMODE_PORT=""
ENV TZ=Asia/Shanghai

WORKDIR /

COPY entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh
RUN ls -lah /entrypoint.sh

COPY config.json /config.json

COPY --from=builder /app/xray /

RUN apk add --no-cache tzdata ca-certificates jq curl libqrencode-tools && \
    mkdir -p /var/log/xray && \
    wget -O /geosite.dat https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat && \
    wget -O /geoip.dat https://github.com/v2fly/geoip/releases/latest/download/geoip.dat && \
    chmod +x /entrypoint.sh


ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 443
