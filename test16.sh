#!/bin/bash

clear

# Цвета для терминала
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
PLAIN='\033[0m'

LOG_FILE="/var/log/3x-ui_install_log.txt"
ERROR_LOG="/var/log/3x-ui_install_error.log"
exec > >(tee -a "$LOG_FILE") 2> >(tee -a "$ERROR_LOG" >&2)

# Функция чередования цветов
step_count=0
color_step() {
    step_count=$((step_count+1))
    case $((step_count % 5)) in
        1) echo -e "${YELLOW}$1${PLAIN}" ;;
        2) echo -e "${GREEN}$1${PLAIN}" ;;
        3) echo -e "${CYAN}$1${PLAIN}" ;;
        4) echo -e "${BLUE}$1${PLAIN}" ;;
        0) echo -e "${MAGENTA}$1${PLAIN}" ;;
    esac
}

step_color() { color_step "$1"; }

step_color "=== 3X-UI Установка и настройка ==="

# Проверка root
step_color "Проверка прав root..."
if [[ $EUID -ne 0 ]]; then
  step_color "Ошибка: скрипт нужно запускать от root"
  exit 1
fi
step_color "Root проверка пройдена."

# Проверка jq
if ! command -v jq &>/dev/null; then
    step_color "Ошибка: требуется jq для работы скрипта"
    exit 1
fi

# Проверка существующей панели
step_color "Проверка существующей панели x-ui..."
if command -v x-ui &> /dev/null; then
    step_color "Обнаружена установленная панель x-ui."
    echo -en "${YELLOW}Вы хотите переустановить x-ui? [y/N]: ${PLAIN}"
    read confirm
    confirm=${confirm,,}
    if [[ "$confirm" != "y" && "$confirm" != "yes" ]]; then
        step_color "Отмена. Скрипт завершает работу."
        exit 1
    fi

    step_color "Удаляем старую x-ui..."
    systemctl stop x-ui 2>/dev/null
    [[ -d /usr/local/x-ui ]] && rm -rf /usr/local/x-ui
    [[ -d /etc/x-ui ]] && rm -rf /etc/x-ui
    [[ -f /usr/bin/x-ui ]] && rm -f /usr/bin/x-ui
    [[ -f /etc/systemd/system/x-ui.service ]] && rm -f /etc/systemd/system/x-ui.service
    systemctl daemon-reexec
    systemctl daemon-reload
    [[ -f /root/3x-ui.txt ]] && rm -f /root/3x-ui.txt
    step_color "Старая панель удалена."
fi

# Порт панели
PORT=8080

# Генерация случайных данных
step_color "Генерация случайного логина, пароля и BasePath..."
gen_random_string() { local length="$1"; LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1; }
USERNAME=$(gen_random_string 10)
PASSWORD=$(gen_random_string 10)
WEBPATH=$(gen_random_string 18)

# Определение ОС
step_color "Определяем операционную систему..."
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
    step_color "ОС определена как: $release"
else
    step_color "Не удалось определить ОС"
    exit 1
fi

# Определяем архитектуру
step_color "Определяем архитектуру системы..."
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
step_color "Архитектура определена как: $ARCH"

# Проверка GLIBC
step_color "Проверяем версию GLIBC..."
glibc_version=$(ldd --version 2>/dev/null | head -n1 | awk '{print $NF}' || echo "0")
required_version="2.32"
if [[ "$(printf '%s\n' "$required_version" "$glibc_version" | sort -V | head -n1)" != "$required_version" ]]; then
    step_color "GLIBC слишком старая ($glibc_version), требуется >= 2.32."
    exit 1
fi
step_color "Версия GLIBC подходит."

# Скачиваем и распаковываем 3x-ui
step_color "Скачиваем последнюю версию 3x-ui..."
cd /usr/local/ || exit 1
tag_version=$(curl -Ls "https://api.github.com/repos/MHSanaei/3x-ui/releases/latest" \
               | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
[[ -z "$tag_version" ]] && step_color "Не удалось получить версию релиза 3x-ui" && exit 1
step_color "Версия релиза: $tag_version"

wget -4 -q -O x-ui-linux-${ARCH}.tar.gz \
     https://github.com/MHSanaei/3x-ui/releases/download/${tag_version}/x-ui-linux-${ARCH}.tar.gz
[[ ! -f x-ui-linux-${ARCH}.tar.gz ]] && step_color "Ошибка: не удалось скачать архив 3x-ui" && exit 1

step_color "Распаковываем архив..."
rm -rf /usr/local/x-ui/
tar -xzf x-ui-linux-${ARCH}.tar.gz
rm -f x-ui-linux-${ARCH}.tar.gz

cd x-ui || exit 1
chmod +x x-ui

# Настройка сервиса
step_color "Настраиваем сервис x-ui..."
cp -f x-ui.service /etc/systemd/system/
wget -4 -q -O /usr/bin/x-ui https://raw.githubusercontent.com/MHSanaei/3x-ui/main/x-ui.sh
chmod +x /usr/local/x-ui/x-ui.sh /usr/bin/x-ui

step_color "Применяем настройки панели..."
/usr/local/x-ui/x-ui setting -username "$USERNAME" -password "$PASSWORD" -port "$PORT" -webBasePath "$WEBPATH" >> "$LOG_FILE" 2>&1
/usr/local/x-ui/x-ui migrate >> "$LOG_FILE" 2>&1

systemctl daemon-reload
systemctl enable x-ui
systemctl start x-ui

# Финальный вывод данных панели
SERVER_IP=$(curl -s --max-time 3 https://api.ipify.org || curl -s --max-time 3 https://4.ident.me)

step_color "=== Установка завершена! ==="
step_color "Адрес панели: http://${SERVER_IP}:${PORT}/${WEBPATH}"
step_color "Логин: ${USERNAME}"
step_color "Пароль: ${PASSWORD}"

# Сохраняем данные панели в лог
echo -e "Адрес панели: http://${SERVER_IP}:${PORT}/${WEBPATH}\nЛогин: ${USERNAME}\nПароль: ${PASSWORD}" > /root/3x-ui.txt
