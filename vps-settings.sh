#!/bin/bash
set -e

VERSION="v2.6"

clear

# Цвета
GREEN='\033[1;32m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
RED='\033[1;91m'
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

# 🔧 Обновление системы
echo -e "\n${RED}🔹 Обновляем систему...${RESET}"
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

echo -e "${GREEN}✅ Система обновлена.${RESET}"

# 🔐 Изменение SSH порта
echo -e "\n${RED}🔹 Введите новый SSH порт (оставьте пустым, чтобы не менять):${RESET} \c"
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
    echo -e "${CYAN}ℹ️ SSH порт оставлен без изменений (${NEW_SSH_PORT}).${RESET}"
fi

# 🔑 Смена root-пароля
echo -e "\n${RED}🔹 Введите новый пароль root (оставьте пустым, чтобы не менять):${RESET} \c"
read -rs NEW_ROOT_PASS
if [[ -n "$NEW_ROOT_PASS" ]]; then
    echo "root:$NEW_ROOT_PASS" | chpasswd
    echo -e "${GREEN}✅ Пароль root изменён.${RESET}"
else
    echo -e "\n${CYAN}ℹ️ Пароль root оставлен без изменений.${RESET}"
fi

# 🚫 Отключение ICMP
echo -e "\n${RED}🔹 Отключаем пинг (ICMP echo-request)...${RESET}"
if ! grep -q "net.ipv4.icmp_echo_ignore_all" /etc/sysctl.conf; then
    echo "net.ipv4.icmp_echo_ignore_all = 1" >> /etc/sysctl.conf
    sysctl -p >/dev/null 2>&1
    echo -e "${GREEN}✅ Пинг (ICMP echo-request) отключён.${RESET}"
else
    echo -e "${GREEN}✅ Пинг уже был отключён ранее.${RESET}"
fi

# 🧾 Итог
IP_ADDR=$(curl -s https://ipinfo.io/ip)
echo -e "\n${GREEN}✅ Все настройки выполнены!${RESET}"
echo -e "${WHITE}==============================${RESET}"
echo -e "🌐 ${CYAN}IP сервера:${RESET}     ${WHITE}$IP_ADDR${RESET}"
echo -e "📡 ${CYAN}Порт SSH:${RESET}       ${WHITE}$NEW_SSH_PORT${RESET}"
[[ -n "$NEW_ROOT_PASS" ]] && echo -e "🔑 ${CYAN}Пароль root:${RESET}    ${WHITE}$NEW_ROOT_PASS${RESET}"
echo -e "${WHITE}==============================${RESET}"

# 🔁 Перезагрузка
echo -e "\n${RED}Перезагрузить систему сейчас? (y/N):${RESET} \c"
read -r REBOOT
if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
    echo -e "${WHITE}Перезагрузка через:${RESET}"
    for i in {5..1}; do
        echo -ne "${CYAN}  $i...${RESET}\r"
        sleep 1.5
    done
    echo -e "\n${RED}🚀 Перезагрузка...${RESET}"
    reboot
else
    echo -e "${CYAN}Перезагрузка отменена. Скрипт завершён.${RESET}"
fi
