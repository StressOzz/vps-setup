#!/bin/bash
set -e

VERSION="v1.8"

clear

# Цвета
GREEN='\033[1;32m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
RED='\033[1;91m'
PURPLE='\033[1;35m'
YELLOW='\033[1;33m'
RESET='\033[0m'

print_banner() {
  echo ""
  echo "  ██████ ▄▄▄█████▓ ██▀███  ▓█████   ██████   ██████ "
  echo "▒██    ▒ ▓  ██▒ ▓▒▓██ ▒ ██▒▓█   ▀ ▒██    ▒ ▒██    ▒ "
  echo "░ ▓██▄   ▒ ▓██░ ▒░▓██ ░▄█ ▒▒███   ░ ▓██▄   ░ ▓██▄   "
  echo "  ▒   ██▒░ ▓██▓ ░ ▒██▀▀█▄  ▒▓█  ▄   ▒   ██▒  ▒   ██▒"
  echo "▒██████▒▒  ▒██▒ ░ ░██▓ ▒██▒░▒████▒▒██████▒▒▒██████▒▒"
  echo "▒ ▒▓▒ ▒ ░  ▒ ░░   ░ ▒▓ ░▒▓░░░ ▒░ ░▒ ▒▓▒ ▒ ░▒ ▒▓▒ ▒ ░"
  echo "░ ░▒  ░ ░    ░      ░▒ ░ ▒░ ░ ░  ░░ ░▒  ░ ░░ ░▒  ░ ░"
  echo "░  ░  ░    ░        ░░   ░    ░   ░  ░  ░  ░  ░  ░  "
  echo "      ░              ░        ░  ░      ░        ░  "
  echo ""
}
print_banner

echo -e "Версия скрипта: ${VERSION}"
echo ""

# Флаги изменений
SSH_PORT_CHANGED=0
ROOT_PASS_CHANGED=0
ICMP_DISABLED=0

# 🔧 Обновление системы
echo -e "\n${PURPLE}🔹 Обновляем систему...${RESET}"
echo ""
echo ""
if ! apt update -qq; then
    echo -e "${RED}❌ Ошибка обновления пакетов.${RESET}"
    exit 1
fi
apt install -y sudo -qq
if ! apt full-upgrade -y -qq; then
    echo -e "${RED}❌ Ошибка обновления системы.${RESET}"
    exit 1
fi

# >>>> Проверка curl перед использованием
if ! command -v curl >/dev/null 2>&1; then
    echo -e "${CYAN}📦 Устанавливаем curl...${RESET}"
    apt install -y curl
fi

clear
print_banner

echo -e "\n${GREEN}✅ Система обновлена.${RESET}"
echo ""

# 🔐 Изменение SSH порта

# Получаем текущий порт из sshd_config, учитывая и комментированные строки, берём последний активный (не закомментированный) или последний вообще
CURRENT_PORT=$(grep -E '^\s*Port\s+[0-9]+' /etc/ssh/sshd_config | tail -n1 | awk '{print $2}')
if [[ -z "$CURRENT_PORT" ]]; then
  # Если не нашли явно, пробуем взять из любой строки с Port (даже закомментированной)
  CURRENT_PORT=$(grep -E '^\s*#?\s*Port\s+[0-9]+' /etc/ssh/sshd_config | tail -n1 | awk '{print $2}')
fi

echo -e "${WHITE}🔹Изменяем порт SSH${RESET}"
echo ""
echo -e "${CYAN}Текущий SSH порт: $CURRENT_PORT${RESET}"
echo -e "${RED}Введите новый SSH порт (оставьте пустым, чтобы не менять):${RESET} \c"
read -r NEW_SSH_PORT

if [[ -n "$NEW_SSH_PORT" ]]; then
    if [[ "$NEW_SSH_PORT" =~ ^[0-9]+$ && "$NEW_SSH_PORT" -ge 1 && "$NEW_SSH_PORT" -le 65535 ]]; then
        # Проверяем, занят ли порт кем-то кроме sshd (если это текущий порт sshd - разрешаем)
        if ss -tln | grep -q ":$NEW_SSH_PORT\b"; then
            # Если новый порт совпадает с текущим портом, разрешаем без изменений
            if [[ "$NEW_SSH_PORT" == "$CURRENT_PORT" ]]; then
                echo -e "${GREEN}✅ Новый порт совпадает с текущим SSH портом. Изменений не требуется.${RESET}"
                SSH_PORT_CHANGED=0
            else
                echo -e "${PURPLE}❌ Порт $NEW_SSH_PORT уже занят другим процессом.${RESET} ${GREEN}Изменения отменены.${RESET}"
                NEW_SSH_PORT=$CURRENT_PORT
            fi
        else
            sed -i "s/^#\?Port .*/Port $NEW_SSH_PORT/" /etc/ssh/sshd_config
            if systemctl restart sshd; then
                echo -e "${GREEN}✅ SSH порт изменён на $NEW_SSH_PORT.${RESET}"
                SSH_PORT_CHANGED=1
            else
                echo -e "${PURPLE}⚠️ Не удалось перезапустить SSH!${RESET}"
                NEW_SSH_PORT=$CURRENT_PORT
            fi
        fi
    else
        echo -e "${PURPLE}❌ Некорректный порт.${RESET} ${GREEN}Изменения отменены.${RESET}"
        NEW_SSH_PORT=$CURRENT_PORT
    fi
else
    NEW_SSH_PORT=$CURRENT_PORT
    echo -e "${GREEN}✅ SSH порт оставлен без изменений.${RESET}"
fi

# 🔑 Смена root-пароля
echo ""
echo -e "${WHITE}🔹Изменяем пароль root${RESET}"
echo -e "\n${CYAN}Пароль не будет отображаться при вводе.${RESET}"
echo -e "${RED}Введите новый пароль root (оставьте пустым, чтобы не менять):${RESET} \c"
read -rs NEW_ROOT_PASS
echo ""
if [[ -n "$NEW_ROOT_PASS" ]]; then
    echo "root:$NEW_ROOT_PASS" | chpasswd
    echo -e "${GREEN}✅ Пароль root изменён.${RESET}"
    ROOT_PASS_CHANGED=1
else
    echo -e "${GREEN}✅ Пароль root оставлен без изменений.${RESET}"
fi

# 🚫 Отключение ICMP
if ! grep -q "net.ipv4.icmp_echo_ignore_all" /etc/sysctl.conf; then
    echo "net.ipv4.icmp_echo_ignore_all = 1" >> /etc/sysctl.conf
    sysctl -p >/dev/null 2>&1
    echo -e "\n${GREEN}✅ Пинг (ICMP echo-request) отключён.${RESET}"
    ICMP_DISABLED=1
else
    echo -e "\n${GREEN}✅ Пинг уже был отключён ранее.${RESET}"
fi

# 🧾 Итог
IP_ADDR=$(curl -s https://ipinfo.io/ip)
echo -e "\n${GREEN}✅ Все настройки выполнены!${RESET}"
echo ""
echo -e "${WHITE}==============================${RESET}"
echo -e "🌐 ${CYAN}IP сервера:${RESET}     ${YELLOW}$IP_ADDR${RESET}"
echo -e "📡 ${CYAN}Порт SSH:${RESET}       ${YELLOW}$NEW_SSH_PORT${RESET}"
[[ -n "$NEW_ROOT_PASS" ]] && echo -e "🔑 ${CYAN}Пароль root:${RESET}    ${YELLOW}********${RESET}"
echo -e "${WHITE}==============================${RESET}"

# 🔁 Перезагрузка (только если были изменения)
if (( SSH_PORT_CHANGED + ROOT_PASS_CHANGED + ICMP_DISABLED > 0 )); then
    echo -e "\n${RED}Перезагрузить систему сейчас? (y/N):${RESET} \c"
    read -r REBOOT
    if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${YELLOW}Перезагрузка через:${RESET}"
        for i in {5..1}; do
            echo -ne "${CYAN} $i${RESET} "
            sleep 1
        done
        echo ""
        echo -e "\n${PURPLE}🚀 Перезагрузка...${RESET}"
        echo ""
        reboot
    else
        echo -e "${GREEN}✅ Перезагрузка отменена. Скрипт завершён.${RESET}"
        echo ""
    fi
else
    echo -e "\n${GREEN}✅ Изменений не было — перезагрузка не нужна.${RESET}"
    echo ""
fi
