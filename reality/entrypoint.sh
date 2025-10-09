#!/bin/sh
if [ -f /config_info.txt ]; then
  echo "config.json exist"
else
  IPV6=$(curl -6 -sSL --connect-timeout 3 --retry 2  ip.sb || echo "null")
  IPV4=$(curl -4 -sSL --connect-timeout 3 --retry 2  ip.sb || echo "null")
  if [ -z "$UUID" ]; then
    echo "UUID is not set, generate random UUID "
    UUID="$(/xray uuid)"
    echo "UUID: $UUID"
  fi

  if [ -z "$EXTERNAL_PORT" ]; then
    echo "EXTERNAL_PORT is not set, use default value 443"
    EXTERNAL_PORT=443
  fi

  if [ -n "$HOSTMODE_PORT" ];then
    EXTERNAL_PORT=$HOSTMODE_PORT
    jq ".inbounds[0].port=$HOSTMODE_PORT" /config.json >/config.json_tmp && mv /config.json_tmp /config.json
  fi

  if [ -z "$DEST" ]; then
    echo "DEST is not set. default value www.apple.com:443"
    DEST="www.apple.com:443"
  fi

  if [ -z "$SERVERNAMES" ]; then
    echo "SERVERNAMES is not set. use default value [\"www.apple.com\",\"images.apple.com\"]"
    SERVERNAMES="www.apple.com images.apple.com"
  fi

# Check if PRIVATEKEY is set
if [ -z "$PRIVATEKEY" ]; then
  echo "PRIVATEKEY is not set. Generating new key pair..."
  /xray x25519 > /key
  PRIVATEKEY=$(awk -F ': ' '/Private/ {print $2}' /key)
  PUBLICKEY=$(awk -F ': ' '/Password/ {print $2}' /key)
else
  echo "PRIVATEKEY is set. Deriving public key..."
  PUBLICKEY=$(/xray x25519 -i "$PRIVATEKEY" | awk -F ': ' '/Password/ {print $2}')
fi

# Output results
echo "Private key: $PRIVATEKEY"
echo "Public key:  $PUBLICKEY"

  if [ -z "$NETWORK" ]; then
    echo "NETWORK is not set,set default value tcp"
    NETWORK="tcp"
  fi

  # change config
  jq ".inbounds[1].settings.clients[0].id=\"$UUID\"" /config.json >/config.json_tmp && mv /config.json_tmp /config.json
  jq ".inbounds[1].streamSettings.realitySettings.dest=\"$DEST\"" /config.json >/config.json_tmp && mv /config.json_tmp /config.json

  SERVERNAMES_JSON_ARRAY="$(echo "[$(echo $SERVERNAMES | awk '{for(i=1;i<=NF;i++) printf "\"%s\",", $i}' | sed 's/,$//')]")"
  jq --argjson serverNames "$SERVERNAMES_JSON_ARRAY" '.inbounds[1].streamSettings.realitySettings.serverNames = $serverNames' /config.json >/config.json_tmp && mv /config.json_tmp /config.json
  jq --argjson serverNames "$SERVERNAMES_JSON_ARRAY" '.routing.rules[0].domain = $serverNames' /config.json >/config.json_tmp && mv /config.json_tmp /config.json

  jq ".inbounds[1].streamSettings.realitySettings.privateKey=\"$PRIVATEKEY\"" /config.json >/config.json_tmp && mv /config.json_tmp /config.json
  jq ".inbounds[1].streamSettings.network=\"$NETWORK\"" /config.json >/config.json_tmp && mv /config.json_tmp /config.json



  FIRST_SERVERNAME=$(echo $SERVERNAMES | awk '{print $1}')
  # config info with green color
  echo -e "\033[32m" >/config_info.txt
  echo "IPV6: $IPV6" >>/config_info.txt
  echo "IPV4: $IPV4" >>/config_info.txt
  echo "UUID: $UUID" >>/config_info.txt
  echo "DEST: $DEST" >>/config_info.txt
  echo "PORT: $EXTERNAL_PORT" >>/config_info.txt
  echo "SERVERNAMES: $SERVERNAMES (任选其一)" >>/config_info.txt
  echo "PRIVATEKEY: $PRIVATEKEY" >>/config_info.txt
  echo "PUBLICKEY/PASSWORD: $PUBLICKEY" >>/config_info.txt
  echo "NETWORK: $NETWORK" >>/config_info.txt
  if [ "$IPV4" != "null" ]; then
    SUB_IPV4="vless://$UUID@$IPV4:$EXTERNAL_PORT?encryption=none&security=reality&type=$NETWORK&sni=$FIRST_SERVERNAME&fp=chrome&pbk=$PUBLICKEY&flow=xtls-rprx-vision#${IPV4}-freeman_docker_vless_reality_vision"
    echo "IPV4 订阅连接: $SUB_IPV4" >>/config_info.txt
    echo -e "IPV4 订阅二维码:\n$(echo "$SUB_IPV4" | qrencode -o - -t UTF8)" >>/config_info.txt
  fi
  if [ "$IPV6" != "null" ];then
    SUB_IPV6="vless://$UUID@$IPV6:$EXTERNAL_PORT?encryption=none&security=reality&type=$NETWORK&sni=$FIRST_SERVERNAME&fp=chrome&pbk=$PUBLICKEY&flow=xtls-rprx-vision#${IPV6}-freeman_docker_vless_reality_vision"
    echo "IPV6 订阅连接: $SUB_IPV6" >>/config_info.txt
    echo -e "IPV6 订阅二维码:\n$(echo "$SUB_IPV6" | qrencode -o - -t UTF8)" >>/config_info.txt
  fi


  echo -e "\033[0m" >>/config_info.txt

fi

# show config info
cat /config_info.txt

# run xray
exec /xray -config /config.json
