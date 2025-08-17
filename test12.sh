#!/bin/bash

clear

# Цвета
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[1;34m'
cyan='\033[1;36m'
plain='\033[0m'

LOG_FILE="/var/log/3x-ui_install_log.txt"
OUTPUT_FILE="/root/3x-ui.txt"
exec > >(tee -a "$LOG_FILE") 2>&1

progress_step() {
    local msg="$1"
    echo -ne "${blue}>> ${msg}...${plain}"
    sleep 0.5
    echo -e "${green}done${plain}"
}

echo -e "${cyan}=== 3X-UI Установка и настройка ===${plain}"

# Проверка root
progress_step "Проверка прав root"
if [[ $EUID -ne 0 ]]; then
    echo -e "${red}Ошибка: скрипт нужно запускать от root${plain}"
    exit 1
fi

# Проверка существующей панели
progress_step "Проверка существующей панели x-ui"
if command -v x-ui &> /dev/null; then
    echo -e "${yellow}Обнаружена установленная панель x-ui.${plain}"
    read -p "Вы хотите переустановить x-ui? [y/N]: " confirm
    confirm=${confirm,,}
    if [[ "$confirm" != "y" && "$confirm" != "yes" ]]; then
        echo -e "${red}Отмена. Скрипт завершает работу.${plain}"
        exit 1
    fi
    progress_step "Удаляем старую x-ui"
    systemctl stop x-ui 2>/dev/null
    rm -rf /usr/local/x-ui /etc/x-ui /usr/bin/x-ui /etc/systemd/system/x-ui.service
    systemctl daemon-reexec
    systemctl daemon-reload
    rm -f "$OUTPUT_FILE"
fi

PORT=8080

# Генерация случайных данных
progress_step "Генерация логина, пароля и пути панели"
gen_random_string() { LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$1" | head -n1; }
USERNAME=$(gen_random_string 10)
PASSWORD=$(gen_random_string 10)
WEBPATH=$(gen_random_string 18)

# Определяем ОС и архитектуру
progress_step "Определение ОС"
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
else
    echo -e "${red}Не удалось определить ОС${plain}"
    exit 1
fi
progress_step "Определение архитектуры"
arch() {
    case "$(uname -m)" in
        x86_64|amd64) echo 'amd64' ;;
        i*86) echo '386' ;;
        armv7*|arm) echo 'armv7' ;;
        armv8*|aarch64) echo 'arm64' ;;
        armv6*) echo 'armv6' ;;
        armv5*) echo 'armv5' ;;
        s390x) echo 's390x' ;;
        *) echo 'unknown' ;;
    esac
}
ARCH=$(arch)

# Проверка GLIBC
progress_step "Проверка версии GLIBC"
glibc_version=$(ldd --version | head -n1 | awk '{print $NF}')
required_version="2.32"
if [[ "$(printf '%s\n' "$required_version" "$glibc_version" | sort -V | head -n1)" != "$required_version" ]]; then
    echo -e "${red}GLIBC слишком старая ($glibc_version), требуется >= 2.32.${plain}"
    exit 1
fi

# Скачиваем и распаковываем
progress_step "Скачиваем последнюю версию 3x-ui"
cd /usr/local/ || exit 1
tag_version=$(curl -Ls "https://api.github.com/repos/MHSanaei/3x-ui/releases/latest" \
               | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
wget -4 -q -O x-ui-linux-${ARCH}.tar.gz \
     https://github.com/MHSanaei/3x-ui/releases/download/${tag_version}/x-ui-linux-${ARCH}.tar.gz

progress_step "Распаковываем архив"
systemctl stop x-ui 2>/dev/null
rm -rf /usr/local/x-ui/
tar -xzf x-ui-linux-${ARCH}.tar.gz
rm -f x-ui-linux-${ARCH}.tar.gz
cd x-ui || exit 1
chmod +x x-ui
XRAY_BIN=$(ls -1 bin/xray-* 2>/dev/null | head -n1)
chmod +x "$XRAY_BIN"

# Настройка сервиса
progress_step "Настройка сервиса x-ui"
cp -f x-ui.service /etc/systemd/system/
wget -4 -q -O /usr/bin/x-ui https://raw.githubusercontent.com/MHSanaei/3x-ui/main/x-ui.sh
chmod +x /usr/local/x-ui/x-ui.sh /usr/bin/x-ui

progress_step "Применяем настройки панели"
/usr/local/x-ui/x-ui setting -username "$USERNAME" -password "$PASSWORD" -port "$PORT" -webBasePath "$WEBPATH" >> "$LOG_FILE" 2>&1
/usr/local/x-ui/x-ui migrate >> "$LOG_FILE" 2>&1
systemctl daemon-reload >> "$LOG_FILE" 2>&1
systemctl enable x-ui >> "$LOG_FILE" 2>&1
systemctl start x-ui >> "$LOG_FILE" 2>&1

progress_step "Ждём пока панель поднимется"
for i in {1..30}; do
    curl -s "http://127.0.0.1:${PORT}/${WEBPATH}/login" >/dev/null && break
    sleep 0.5
done

# Генерация ключей Reality
progress_step "Генерация ключей Reality"
KEYS=$("$XRAY_BIN" x25519)
PRIVATE_KEY=$(echo "$KEYS" | grep -i "Private" | sed -E 's/.*key:\s*//')
PUBLIC_KEY=$(echo "$KEYS" | grep -i "Public" | sed -E 's/.*key:\s*//')
SHORT_ID=$(head -c 8 /dev/urandom | xxd -p)
UUID=$(cat /proc/sys/kernel/random/uuid)
BEST_DOMAIN="docscenter.su"

# Авторизация и добавление инбаунда
progress_step "Добавляем inbound в панель"
COOKIE_JAR=$(mktemp)
curl -s -c "$COOKIE_JAR" -X POST "http://127.0.0.1:${PORT}/${WEBPATH}/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}" >/dev/null

SETTINGS_JSON=$(jq -nc --arg uuid "$UUID" --arg email "" '{clients:[{id:$uuid,flow:"xtls-rprx-vision",email:$email}],decryption:"none"}')
STREAM_SETTINGS_JSON=$(jq -nc --arg prk "$PRIVATE_KEY" --arg sid "$SHORT_ID" --arg dest "${BEST_DOMAIN}:443" --arg sni "$BEST_DOMAIN" '{network:"tcp",security:"reality",realitySettings:{show:false,dest:$dest,xver:0,serverNames:[$sni],privateKey:$prk,shortIds:[$sid]}}')
SNIFFING_JSON=$(jq -nc '{enabled:true,destOverride:["http","tls"]}')
remark="Vless"

curl -s -b "$COOKIE_JAR" -X POST "http://127.0.0.1:${PORT}/${WEBPATH}/panel/api/inbounds/add" \
    -H "Content-Type: application/json" \
    -d "$(jq -nc --argjson settings "$SETTINGS_JSON" --argjson stream "$STREAM_SETTINGS_JSON" --argjson sniffing "$SNIFFING_JSON" --arg remark "$remark" '{enable:true,remark:$remark,listen:"0.0.0.0",port:443,protocol:"vless",settings:($settings|tostring),streamSettings:($stream|tostring),sniffing:($sniffing|tostring)}')" >/dev/null
rm -f "$COOKIE_JAR"

SERVER_IP=$(curl -s --max-time 3 https://api.ipify.org || curl -s --max-time 3 https://4.ident.me)
VLESS_LINK="vless://${UUID}@${SERVER_IP}:443?type=tcp&security=reality&encryption=none&flow=xtls-rprx-vision&sni=${BEST_DOMAIN}&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&spx=%2F#"

# Финальный вывод
progress_step "Завершение установки"

cat > "$OUTPUT_FILE" << EOF
=== 3X-UI Установка завершена ===
Адрес панели: http://${SERVER_IP}:${PORT}/${WEBPATH}
Логин: ${USERNAME}
Пароль: ${PASSWORD}
VLESS Reality: ${VLESS_LINK}
EOF

echo -e "${green}\n=== Установка завершена! ===${plain}"
echo -e "${cyan}Адрес панели: ${yellow}http://${SERVER_IP}:${PORT}/${WEBPATH}${plain}"
echo -e "${cyan}Логин: ${yellow}${USERNAME}${plain}"
echo -e "${cyan}Пароль: ${yellow}${PASSWORD}${plain}"
echo -e "${cyan}VLESS Reality: ${green}${VLESS_LINK}${plain}"
echo -e "${green}Данные сохранены в ${OUTPUT_FILE}${plain}"
