#!/bin/bash

clear

# Проверка root
if [[ $EUID -ne 0 ]]; then
  echo "Ошибка: скрипт нужно запускать от root" >&2
  exit 1
fi

# Проверяем наличие команды x-ui
if command -v x-ui &> /dev/null; then
    echo "Обнаружена установленная панель x-ui."

    # Запрос у пользователя на переустановку
    read -p "Вы хотите переустановить x-ui? [y/N]: " confirm
    confirm=${confirm,,}  # перевод в нижний регистр

    if [[ "$confirm" != "y" && "$confirm" != "yes" ]]; then
        echo "Отмена. Скрипт завершает работу."
        exit 1
    fi

    echo "Удаление x-ui..."
    /usr/local/x-ui/x-ui uninstall -y &>/dev/null || true
    rm -rf /usr/local/x-ui /etc/x-ui /usr/bin/x-ui /etc/systemd/system/x-ui.service
    systemctl daemon-reexec
    systemctl daemon-reload
    rm -f /root/3x-ui.txt
    echo "x-ui успешно удалена. Продолжаем выполнение скрипта..."
fi

# Вывод всех команд кроме диалога — в лог
exec 3>&1
LOG_FILE="/var/log/3x-ui_install_log.txt"
exec > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# === Порт панели ===
PORT=8080
    
echo -e "Весь процесс установки будет сохранён в файле: \033[0;36m${LOG_FILE}\033[0m" >&3
echo -e "\n\033[1;34mИдёт установка... Пожалуйста, не закрывайте терминал.\033[0m" >&3

# Генерация случайных данных
gen_random_string() {
    local length="$1"
    LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1
}
USERNAME=$(gen_random_string 10)
PASSWORD=$(gen_random_string 10)
WEBPATH=$(gen_random_string 18)

# Определение ОС
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
else
    echo "Не удалось определить ОС" >&3
    exit 1
fi

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

# Проверка GLIBC
glibc_version=$(ldd --version | head -n1 | awk '{print $NF}')
required_version="2.32"
if [[ "$(printf '%s\n' "$required_version" "$glibc_version" | sort -V | head -n1)" != "$required_version" ]]; then
    echo -e "${red}GLIBC слишком старая ($glibc_version), требуется >= 2.32.${plain}" >&3
    echo -e "${red}Вам необходимо установить более свежую ОС${plain}" >&3
    exit 1
fi

# Установка зависимостей
case "${release}" in
    ubuntu | debian | armbian)
        apt-get update > /dev/null 2>&1
        apt-get install -y -q wget curl tar tzdata jq xxd qrencode > /dev/null 2>&1
        ;;
    centos | rhel | almalinux | rocky | ol)
        yum -y update > /dev/null 2>&1
        yum install -y -q wget curl tar tzdata jq xxd qrencode > /dev/null 2>&1
        ;;
    fedora | amzn | virtuozzo)
        dnf -y update > /dev/null 2>&1
        dnf install -y -q wget curl tar tzdata jq xxd qrencode > /dev/null 2>&1
        ;;
    arch | manjaro | parch)
        pacman -Syu --noconfirm > /dev/null 2>&1
        pacman -S --noconfirm wget curl tar tzdata jq xxd qrencode > /dev/null 2>&1
        ;;
    opensuse-tumbleweed)
        zypper refresh > /dev/null 2>&1
        zypper install -y wget curl tar timezone jq xxd qrencode > /dev/null 2>&1
        ;;
    *)
        apt-get update > /dev/null 2>&1
        apt-get install -y wget curl tar tzdata jq xxd qrencode > /dev/null 2>&1
        ;;
esac

# Установка 3x-ui
cd /usr/local/ || exit 1
tag_version=$(curl -Ls "https://api.github.com/repos/MHSanaei/3x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [[ -z "$tag_version" ]]; then
    echo -e "${red}Не удалось получить версию релиза 3x-ui${plain}" >&3
    exit 1
fi

wget -q -O x-ui-linux-${ARCH}.tar.gz https://github.com/MHSanaei/3x-ui/releases/download/${tag_version}/x-ui-linux-${ARCH}.tar.gz
if [[ ! -s x-ui-linux-${ARCH}.tar.gz ]]; then
    echo -e "${red}Скачивание 3x-ui не удалось (архив пустой)${plain}" >&3
    exit 1
fi

systemctl stop x-ui 2>/dev/null
rm -rf /usr/local/x-ui/
tar -xzf x-ui-linux-${ARCH}.tar.gz
rm -f x-ui-linux-${ARCH}.tar.gz

cd x-ui || exit 1
chmod +x x-ui
XRAY_BIN=$(ls -1 bin/xray-* 2>/dev/null | head -n1)
if [[ -z "$XRAY_BIN" ]]; then
  echo -e "${red}Не найден бинарник xray в /usr/local/x-ui/bin${plain}" >&3
  exit 1
fi
chmod +x "$XRAY_BIN"

cp -f x-ui.service /etc/systemd/system/
wget -q -O /usr/bin/x-ui https://raw.githubusercontent.com/MHSanaei/3x-ui/main/x-ui.sh
chmod +x /usr/local/x-ui/x-ui.sh /usr/bin/x-ui

/usr/local/x-ui/x-ui setting -username "$USERNAME" -password "$PASSWORD" -port "$PORT" -webBasePath "$WEBPATH" >>"$LOG_FILE" 2>&1
/usr/local/x-ui/x-ui migrate >>"$LOG_FILE" 2>&1

systemctl daemon-reload >>"$LOG_FILE" 2>&1
systemctl enable x-ui >>"$LOG_FILE" 2>&1
systemctl start x-ui >>"$LOG_FILE" 2>&1

# Ждём пока панель поднимется
for i in {1..30}; do
  curl -s "http://127.0.0.1:${PORT}/${WEBPATH}/login" >/dev/null && break
  sleep 0.5
done

# Генерация Reality ключей
KEYS=$("$XRAY_BIN" x25519)
PRIVATE_KEY=$(echo "$KEYS" | grep -i "Private" | sed -E 's/.*key:\s*//')
PUBLIC_KEY=$(echo "$KEYS" | grep -i "Public" | sed -E 's/.*key:\s*//')
SHORT_ID=$(head -c 8 /dev/urandom | xxd -p)
UUID=$(cat /proc/sys/kernel/random/uuid)
EMAIL=""

# === Фиксированный SNI/DEST ===
BEST_DOMAIN="docscenter.su"
echo -e "${green}Используется фиксированный домен: ${BEST_DOMAIN}${plain}" >&3

# Авторизация
COOKIE_JAR=$(mktemp)
LOGIN_RESPONSE=$(curl -s -c "$COOKIE_JAR" -X POST "http://127.0.0.1:${PORT}/${WEBPATH}/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\": \"${USERNAME}\", \"password\": \"${PASSWORD}\"}")

if ! echo "$LOGIN_RESPONSE" | grep -q '"success":true'; then
    echo -e "${red}Ошибка авторизации через cookie.${plain}" >&3
    echo "$LOGIN_RESPONSE" >&3
    exit 1
fi

# Формирование JSON
SETTINGS_JSON=$(jq -nc --arg uuid "$UUID" --arg email "$EMAIL" '{
  clients: [
    {
      id: $uuid,
      flow: "xtls-rprx-vision",
      email: $email
    }
  ],
  decryption: "none"
}')

STREAM_SETTINGS_JSON=$(jq -nc --arg prk "$PRIVATE_KEY" --arg sid "$SHORT_ID" --arg dest "${BEST_DOMAIN}:443" --arg sni "$BEST_DOMAIN" '{
  network: "tcp",
  security: "reality",
  realitySettings: {
    show: false,
    dest: $dest,
    xver: 0,
    serverNames: [$sni],
    privateKey: $prk,
    shortIds: [$sid]
  }
}')

SNIFFING_JSON=$(jq -nc '{
  enabled: true,
  destOverride: ["http", "tls"]
}')

# === Определяем страну VPS для remark ===
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

# Добавление инбаунда
ADD_RESULT=$(curl -s -b "$COOKIE_JAR" -X POST "http://127.0.0.1:${PORT}/${WEBPATH}/panel/api/inbounds/add" \
  -H "Content-Type: application/json" \
  -d "$(jq -nc \
    --argjson settings "$SETTINGS_JSON" \
    --argjson stream "$STREAM_SETTINGS_JSON" \
    --argjson sniffing "$SNIFFING_JSON" \
    --arg remark "$remark" \
    '{
      enable: true,
      remark: $remark,
      listen: "0.0.0.0",
      port: 443,
      protocol: "vless",
      settings: ($settings | tostring),
      streamSettings: ($stream | tostring),
      sniffing: ($sniffing | tostring)
    }')"
)

rm -f "$COOKIE_JAR"

if echo "$ADD_RESULT" | grep -q '"success":true'; then
    echo -e "${green}Инбаунд успешно добавлен через API.${plain}" >&3
    systemctl restart x-ui >>"$LOG_FILE" 2>&1

    SERVER_IP=$(curl -s --max-time 3 https://api.ipify.org || curl -s --max-time 3 https://4.ident.me)
    VLESS_LINK="vless://${UUID}@${SERVER_IP}:443?type=tcp&security=reality&encryption=none&flow=xtls-rprx-vision&sni=${BEST_DOMAIN}&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&spx=%2F#${EMAIL}"

    echo -e "\n\033[0;32mVLESS Reality успешно создан!\033[0m" >&3
    echo -e "\033[1;36mВаш VPN ключ:\033[0m" >&3
    echo -e "${VLESS_LINK}" >&3
    echo -e ""
    qrencode -t ANSIUTF8 "$VLESS_LINK"
    qrencode -o /root/vless_qr.png "$VLESS_LINK"
    echo -e "QR-код также сохранён в файл: /root/vless_qr.png" >&3

    {
    echo "Ваш VPN ключ:"
    echo "$VLESS_LINK"
    echo ""
    echo "QR PNG сохранён: /root/vless_qr.png"
    } >> /root/3x-ui.txt
else
    echo -e "${red}Ошибка при добавлении инбаунда через API:${plain}" >&3
    echo "$ADD_RESULT" >&3
fi

# Финал
SERVER_IP=${SERVER_IP:-$(curl -s --max-time 3 https://api.ipify.org || curl -s --max-time 3 https://4.ident.me)}

echo -e "\n\033[1;32mПанель управления 3X-UI доступна:\033[0m" >&3
echo -e "Адрес: \033[1;36mhttp://${SERVER_IP}:${PORT}/${WEBPATH}\033[0m" >&3
echo -e "Логин: \033[1;33m${USERNAME}\033[0m" >&3
echo -e "Пароль: \033[1;33m${PASSWORD}\033[0m" >&3
echo -e "Все данные сохранены в: \033[1;36m/root/3x-ui.txt\033[0m" >&3
