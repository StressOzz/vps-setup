#!/bin/bash
set -e

VERSION="v3.7"

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

# Проверка sudo
if ! command -v sudo >/dev/null 2>&1; then
    echo -e "${CYAN}📦 Устанавливаем sudo...${RESET}"
    apt update && apt install -y sudo
fi

# Проверка curl
if ! command -v curl >/dev/null 2>&1; then
    echo -e "${CYAN}📦 Устанавливаем curl...${RESET}"
    sudo apt install -y curl
fi

# Обновление системы
echo -e "\n${PURPLE}🔹 Обновляем систему...${RESET}"
sudo apt update
sudo apt list --upgradable
sudo apt full-upgrade -y

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

# Изменение SSH порта с проверкой
echo -e "${WHITE}🔹Изменяем порт SSH${RESET}"
echo -e "\n${RED}Введите новый SSH порт (оставьте пустым, чтобы не менять):${RESET} \c"
read -r NEW_SSH_PORT

if [[ -n "$NEW_SSH_PORT" ]]; then
    if [[ "$NEW_SSH_PORT" =~ ^[0-9]+$ && "$NEW_SSH_PORT" -ge 1 && "$NEW_SSH_PORT" -le 65535 ]]; then
        if ss -tuln | grep -q ":$NEW_SSH_PORT "; then
            echo -e "${RED}❌ Порт $NEW_SSH_PORT уже занят. Изменения отменены.${RESET}"
            NEW_SSH_PORT=$(grep ^Port /etc/ssh/sshd_config | awk '{print $2}')
        else
            sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%F)
            sudo sed -i "s/^#\?Port .*/Port $NEW_SSH_PORT/" /etc/ssh/sshd_config
            sudo systemctl restart sshd && echo -e "${GREEN}✅ SSH порт изменён.${RESET}" || echo -e "${RED}⚠️ Не удалось перезапустить SSH!${RESET}"
        fi
    else
        echo -e "${RED}❌ Некорректный порт. Изменения отменены.${RESET}"
        NEW_SSH_PORT=$(grep ^Port /etc/ssh/sshd_config | awk '{print $2}')
    fi
else
    NEW_SSH_PORT=$(grep ^Port /etc/ssh/sshd_config | awk '{print $2}')
    echo -e "${GREEN}✅ SSH порт оставлен без изменений.${RESET}"
fi

# Смена root-пароля с подтверждением
echo ""
echo -e "${WHITE}🔹Изменяем пароль root${RESET}"
echo -e "\n${RED}Введите новый пароль root (оставьте пустым, чтобы не менять):${RESET} \c"
read -rs NEW_ROOT_PASS

if [[ -n "$NEW_ROOT_PASS" ]]; then
    echo -e "\n${RED}Повторите новый пароль для подтверждения:${RESET} \c"
    read -rs NEW_ROOT_PASS_CONFIRM
    echo ""
    if [[ "$NEW_ROOT_PASS" == "$NEW_ROOT_PASS_CONFIRM" ]]; then
        echo "root:$NEW_ROOT_PASS" | sudo chpasswd
        echo -e "\n${GREEN}✅ Пароль root изменён.${RESET}"
    else
        echo -e "\n${RED}❌ Пароли не совпадают. Изменения отменены.${RESET}"
    fi
else
    echo -e "\n${GREEN}✅ Пароль root оставлен без изменений.${RESET}"
fi

# Отключение ICMP
if ! grep -q "net.ipv4.icmp_echo_ignore_all" /etc/sysctl.conf; then
    echo "net.ipv4.icmp_echo_ignore_all = 1" | sudo tee -a /etc/sysctl.conf >/dev/null
    sudo sysctl -p >/dev/null 2>&1
    echo -e "\n${GREEN}✅ Пинг (ICMP echo-request) отключён.${RESET}"
else
    echo -e "\n${GREEN}✅ Пинг уже был отключён ранее.${RESET}"
fi

# Итог
IP_ADDR=$(curl -s https://ipinfo.io/ip)
echo -e "\n${GREEN}✅ Все настройки выполнены!${RESET}"
echo ""
echo -e "${WHITE}==============================${RESET}"
echo -e "🌐 ${CYAN}IP сервера:${RESET}     ${YELLOW}$IP_ADDR${RESET}"
echo -e "📡 ${CYAN}Порт SSH:${RESET}       ${YELLOW}$NEW_SSH_PORT${RESET}"
[[ -n "$NEW_ROOT_PASS" && "$NEW_ROOT_PASS" == "$NEW_ROOT_PASS_CONFIRM" ]] && echo -e "🔑 ${CYAN}Пароль root:${RESET}    ${YELLOW}$NEW_ROOT_PASS${RESET}"
echo -e "${WHITE}==============================${RESET}"

# Перезагрузка
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
    sudo reboot
else
    echo -e "${GREEN}✅ Скрипт завершён.${RESET}"
    echo ""
fi
