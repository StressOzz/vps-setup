#!/bin/bash
set -e

VERSION="v3.1"

clear

# Цвета
GREEN='\033[1;32m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
RED='\033[1;91m'
PURPLE='\033[1;35m'
YELLOW='\033[1;33m'
RESET='\033[0m'

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

echo -e "Версия скрипта: ${VERSION}"
echo ""

# 🔧 Обновление системы
echo -e "\n${PURPLE}🔹 Обновляем систему...${RESET}"
echo ""
echo ""
apt update && apt install -y sudo >/dev/null 2>&1
sudo apt update && sudo apt list --upgradable && sudo apt full-upgrade -y >/dev/null 2>&1

clear
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

echo -e "\n${GREEN}✅ Система обновлена.${RESET}"
echo ""

# 🔐 Изменение SSH порта
echo -e "${WHITE}🔹Изменяем порт SSH${RESET}"
echo -e "\n${RED}Введите новый SSH порт (оставьте пустым, чтобы не менять):${RESET} \c"
read -r NEW_SSH_PORT
if [[ -n "$NEW_SSH_PORT" ]]; then
    if [[ "$NEW_SSH_PORT" =~ ^[0-9]+$ && "$NEW_SSH_PORT" -ge 1 && "$NEW_SSH_PORT" -le 65535 ]]; then
        sed -i "s/^#\?Port .*/Port $NEW_SSH_PORT/" /etc/ssh/sshd_config
        systemctl restart sshd && echo -e "${GREEN}✅ SSH порт изменён на ${NEW_SSH_PORT}.${RESET}" || echo -e "${RED}⚠️ Не удалось перезапустить SSH!${RESET}"
    else
        echo -e "${RED}❌ Некорректный порт. Изменения отменены.${RESET}"
        NEW_SSH_PORT=$(grep ^Port /etc/ssh/sshd_config | awk '{print $2}')
    fi
else
    NEW_SSH_PORT=$(grep ^Port /etc/ssh/sshd_config | awk '{print $2}')
    echo -e "${GREEN}✅ SSH порт оставлен без изменений (${NEW_SSH_PORT}).${RESET}"
fi

# 🔑 Смена root-пароля
echo ""
echo -e "${WHITE}🔹Изменяем пароль root${RESET}"
echo -e "\n${RED}Введите новый пароль root (оставьте пустым, чтобы не менять):${RESET} \c"
read -rs NEW_ROOT_PASS
if [[ -n "$NEW_ROOT_PASS" ]]; then
    echo "root:$NEW_ROOT_PASS" | chpasswd
    echo -e "\n${GREEN}✅ Пароль root изменён.${RESET}"
else
    echo -e "\n${GREEN}✅ Пароль root оставлен без изменений.${RESET}"
fi

# 🚫 Отключение ICMP
if ! grep -q "net.ipv4.icmp_echo_ignore_all" /etc/sysctl.conf; then
    echo "net.ipv4.icmp_echo_ignore_all = 1" >> /etc/sysctl.conf
    sysctl -p >/dev/null 2>&1
    echo -e "\n${GREEN}✅ Пинг (ICMP echo-request) отключён.${RESET}"
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
[[ -n "$NEW_ROOT_PASS" ]] && echo -e "🔑 ${CYAN}Пароль root:${RESET}    ${YELLOW}$NEW_ROOT_PASS${RESET}"
echo -e "${WHITE}==============================${RESET}"

# 🔁 Перезагрузка
echo -e "\n${RED}Перезагрузить систему сейчас? (y/N):${RESET} \c"
echo ""
read -r REBOOT
if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${YELLOW}Перезагрузка через:${RESET}"
    for i in {5..1}; do
        echo -ne "${CYAN} $i${RESET} "
        sleep 1.5
    done
echo ""
    echo -e "\n${PURPLE}🚀 Перезагрузка...${RESET}"
    reboot
else
    echo -e "${CYAN}Перезагрузка отменена. Скрипт завершён.${RESET}"
echo ""
fi
