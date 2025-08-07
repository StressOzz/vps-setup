#!/bin/bash
set -e

VERSION="v1.6"

# Очистка экрана
clear

# Цвета
GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m' # сброс цвета

# 🎨 Баннер
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

echo -e "${GREEN}Версия скрипта: $VERSION${NC}"
echo -n "🚀 Запуск скрипта"; for i in {1..5}; do echo -n "."; sleep 0.3; done; echo -e "\n"

# Параметры
PASS="Str3\$\$0zz!98!"
PORT="11953"

echo -e "${GREEN}1️⃣ Обновляем систему...${NC}"
apt update
apt install -y sudo

sudo apt update
sudo apt list --upgradable || true
sudo apt full-upgrade -y

echo -e "${GREEN}2️⃣ Отключаем пинг (ICMP echo-request)...${NC}"
sudo nft add table inet filter 2>/dev/null || true
sudo nft add chain inet filter input '{ type filter hook input priority 0; policy accept; }' 2>/dev/null || true
sudo nft add rule inet filter input icmp type echo-request drop
sudo nft list ruleset | sudo tee /etc/nftables.conf > /dev/null
sudo systemctl enable nftables
sudo mkdir -p /etc/systemd/system/nftables.service.d
echo -e '[Service]\nExecStart=\nExecStart=/usr/sbin/nft -f /etc/nftables.conf' | sudo tee /etc/systemd/system/nftables.service.d/override.conf > /dev/null
sudo systemctl daemon-reexec
sudo systemctl restart nftables

echo -e "${GREEN}3️⃣ Меняем SSH-порт на ${CYAN}${PORT}${NC}${GREEN}...${NC}"
sudo sed -i "s/^#Port 22/Port $PORT/" /etc/ssh/sshd_config
sudo systemctl restart sshd

echo -e "${GREEN}4️⃣ Устанавливаем пароль root...${NC}"
echo "root:$PASS" | sudo chpasswd

# Финальная информация
IP=$(hostname -I | tr ' ' '\n' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n1)
echo -e "${GREEN}✅ Все настройки выполнены!${NC}"
echo -e "${GREEN}=============================="
echo -e "🌐 IP сервера: ${CYAN}${IP}${NC}"
echo -e "📦 Порт SSH:   ${CYAN}${PORT}${NC}"
echo -e "🔑 Пароль root: ${CYAN}${PASS}${NC}"
echo -e "==============================${NC}"

echo -ne "${GREEN}Перезагрузить систему сейчас? (Y/n): ${NC}"
read REBOOT_ANSWER
REBOOT_ANSWER=${REBOOT_ANSWER:-Y}

if [[ "$REBOOT_ANSWER" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Перезагрузка...${NC}"
    sudo reboot
else
    echo -e "${GREEN}Перезагрузка отменена. Скрипт завершён.${NC}"
fi
