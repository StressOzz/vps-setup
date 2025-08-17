#!/bin/bash

clear

# Цвета для терминала
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[1;34m'
cyan='\033[1;36m'
plain='\033[0m'

LOG_FILE="/var/log/3x-ui_install_log.txt"
exec > >(tee -a "$LOG_FILE") 2>&1

echo -e "${blue}=== 3X-UI Установка и настройка ===${plain}"

# Проверка root
echo -e "${yellow}Проверка прав root...${plain}"
if [[ $EUID -ne 0 ]]; then
  echo -e "${red}Ошибка: скрипт нужно запускать от root${plain}"
  exit 1
fi
echo -e "${green}Root проверка пройдена.${plain}"

# Проверка существующей панели
echo -e "${yellow}Проверка существующей панели x-ui...${plain}"
if command -v x-ui &> /dev/null; then
    echo -e "${green}Обнаружена установленная панель x-ui.${plain}"

    read -p "Вы хотите переустановить x-ui? [y/N]: " confirm
    confirm=${confirm,,}

    if [[ "$confirm" != "y" && "$confirm" != "yes" ]]; then
        echo -e "${red}Отмена. Скрипт завершает работу.${plain}"
        exit 1
    fi

    echo -e "${yellow}Удаляем старую x-ui...${plain}"
    systemctl stop x-ui 2>/dev/null
    rm -rf /usr/local/x-ui /etc/x-ui /usr/bin/x-ui /etc/systemd/system/x-ui.service
    systemctl daemon-reexec
    systemctl daemon-reload
    rm -f /root/3x-ui.txt
    echo -e "${green}Старая панель удалена.${plain}"
fi

# Порт панели
PORT=8080

# Генерация случайных данных
echo -e "${yellow}Генерация случайного логина, пароля и пути панели...${plain}"
gen_random_string() {
    local length="$1"
    LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1
}
USERNAME=$(gen_random_string 10)
PASSWORD=$(gen_random_string 10)
WEBPATH=$(gen_random_string 18)

# Определение ОС
echo -e "${yellow}Определяем операционную систему...${plain}"
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
    echo -e "${green}ОС определена как: $release${plain}"
else
    echo -e "${red}Не удалось определить ОС${plain}"
    exit 1
fi

# Определяем архитектуру
echo -e "${yellow}Определяем архитектуру системы...${plain}"
arch() {
    case "$(uname -m)" in
        x86_64 | x64 | amd64) echo 'amd64' ;;
        i*86 | x86) echo '386' ;;
        armv8* | arm64 | aarch64) echo 'arm64' ;;
        armv7* | arm) echo 'armv7' ;;
        armv6*) echo 'armv6' ;;
        armv5*) echo 'armv5' ;;
        s390x) echo 's390x' ;;
        *) echo "unknown" ;;
    esac
}
ARCH=$(arch)
echo -e "${green}Архитектура определена как: $ARCH${plain}"

# Проверка GLIBC
echo -e "${yellow}Проверяем версию GLIBC...${plain}"
glibc_version=$(ldd --version | head -n1 | awk '{print $NF}')
required_version="2.32"
if [[ "$(printf '%s\n' "$required_version" "$glibc_version" | sort -V | head -n1)" != "$required_version" ]]; then
    echo -e "${red}GLIBC слишком старая ($glibc_version), требуется >= 2.32.${plain}"
    exit 1
fi
echo -e "${green}Версия GLIBC подходит.${plain}"

# Скачиваем и распаковываем 3x-ui
echo -e "${yellow}Скачиваем последнюю версию 3x-ui...${plain}"
cd /usr/local/ || exit 1
tag_version=$(curl -Ls "https://api.github.com/repos/MHSanaei/3x-ui/releases/latest" \
               | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [[ -z "$tag_version" ]]; then
    echo -e "${red}Не удалось получить версию релиза 3x-ui${plain}"
    exit 1
fi
echo -e "${green}Версия релиза: $tag_version${plain}"

wget -4 -q -O x-ui-linux-${ARCH}.tar.gz \
     https://github.com/MHSanaei/3x-ui/releases/download/${tag_version}/x-ui-linux-${ARCH}.tar.gz

echo -e "${yellow}Распаковываем архив...${plain}"
systemctl stop x-ui 2>/dev/null
rm -rf /usr/local/x-ui/
tar -xzf x-ui-linux-${ARCH}.tar.gz
rm -f x-ui-linux-${ARCH}.tar.gz

cd x-ui || exit 1
chmod +x x-ui
XRAY_BIN=$(ls -1 bin/xray-* 2>/dev/null | head -n1)
if [[ -z "$XRAY_BIN" ]]; then
  echo -e "${red}Не найден бинарник xray в /usr/local/x-ui/bin${plain}"
  exit 1
fi
chmod +x "$XRAY_BIN"

# Настройка сервиса
echo -e "${yellow}Настраиваем сервис x-ui...${plain}"
cp -f x-ui.service /etc/systemd/system/
wget -4 -q -O /usr/bin/x-ui https://raw.githubusercontent.com/MHSanaei/3x-ui/main/x-ui.sh
chmod +x /usr/local/x-ui/x-ui.sh /usr/bin/x-ui

echo -e "${yellow}Применяем настройки панели...${plain}"
/usr/local/x-ui/x-ui setting -username "$USERNAME" -password "$PASSWORD" -port "$PORT" -webBasePath "$WEBPATH" >> "$LOG_FILE" 2>&1
/usr/local/x-ui/x-ui migrate >> "$LOG_FILE" 2>&1

systemctl daemon-reload >> "$LOG_FILE" 2>&1
systemctl enable x-ui >> "$LOG_FILE" 2>&1
systemctl start x-ui >> "$LOG_FILE" 2>&1

echo -e "${yellow}Ждём пока панель поднимется...${plain}"
for i in {1..30}; do
    curl -s "http://127.0.0.1:${PORT}/${WEBPATH}/login" >/dev/null && break
    sleep 0.5
done
echo -e "${green}Панель запущена.${plain}"

# Генерация ключей Reality
echo -e "${yellow}Генерация ключей Reality...${plain}"
KEYS=$("$XRAY_BIN" x25519)
PRIVATE_KEY=$(echo "$KEYS" | grep -i "Private" | sed -E 's/.*key:\s*//')
PUBLIC_KEY=$(echo "$KEYS" | grep -i "Public" | sed -E 's/.*key:\s*//')
SHORT_ID=$(head -c 8 /dev/urandom | xxd -p)
UUID=$(cat /proc/sys/kernel/random/uuid)
EMAIL=""

BEST_DOMAIN="docscenter.su"


# Авторизация и добавление инбаунда
COOKIE_JAR=$(mktemp)
LOGIN_RESPONSE=$(curl -s -c "$COOKIE_JAR" -X POST "http://127.0.0.1:${PORT}/${WEBPATH}/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\": \"${USERNAME}\", \"password\": \"${PASSWORD}\"}")

if ! echo "$LOGIN_RESPONSE" | grep -q '"success":true'; then
    echo -e "${red}Ошибка авторизации через cookie.${plain}"
    exit 1
fi

SETTINGS_JSON=$(jq -nc --arg uuid "$UUID" --arg email "$EMAIL" '{
  clients: [{id: $uuid, flow: "xtls-rprx-vision", email: $email}],
  decryption: "none"
}')
STREAM_SETTINGS_JSON=$(jq -nc --arg prk "$PRIVATE_KEY" --arg sid "$SHORT_ID" --arg dest "${BEST_DOMAIN}:443" --arg sni "$BEST_DOMAIN" '{
  network: "tcp",
  security: "reality",
  realitySettings: {show:false, dest:$dest, xver:0, serverNames:[$sni], privateKey:$prk, shortIds:[$sid]}
}')
SNIFFING_JSON=$(jq -nc '{enabled:true, destOverride:["http","tls"]}')
COUNTRY=$(curl -s ifconfig.io/country_code || echo "UNK")
case "$COUNTRY" in
    DE) COUNTRY_NAME="GER" ;;
    FI) COUNTRY_NAME="FIN" ;;
    NL) COUNTRY_NAME="NLD" ;;
    FR) COUNTRY_NAME="FRA" ;;
    RU) COUNTRY_NAME="RUS" ;;
    *) COUNTRY_NAME="$COUNTRY" ;;
esac
remark="Vless${COUNTRY_NAME}"

ADD_RESULT=$(curl -s -b "$COOKIE_JAR" -X POST "http://127.0.0.1:${PORT}/${WEBPATH}/panel/api/inbounds/add" \
  -H "Content-Type: application/json" \
  -d "$(jq -nc --argjson settings "$SETTINGS_JSON" --argjson stream "$STREAM_SETTINGS_JSON" --argjson sniffing "$SNIFFING_JSON" --arg remark "$remark" \
      '{enable:true, remark:$remark, listen:"0.0.0.0", port:443, protocol:"vless", settings:($settings|tostring), streamSettings:($stream|tostring), sniffing:($sniffing|tostring)}')"
)
rm -f "$COOKIE_JAR"

SERVER_IP=$(curl -s --max-time 3 https://api.ipify.org || curl -s --max-time 3 https://4.ident.me)
VLESS_LINK="vless://${UUID}@${SERVER_IP}:443?type=tcp&security=reality&encryption=none&flow=xtls-rprx-vision&sni=${BEST_DOMAIN}&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&spx=%2F#${EMAIL}"

# Финальный вывод
echo -e "\n${green}=== Установка завершена! ===${plain}"
echo -e "${cyan}Адрес панели: ${yellow}http://${SERVER_IP}:${PORT}/${WEBPATH}${plain}"
echo -e "${cyan}Логин: ${yellow}${USERNAME}${plain}"
echo -e "${cyan}Пароль: ${yellow}${PASSWORD}${plain}"
echo "$VLESS_LINK" > /root/3x-ui.txt
