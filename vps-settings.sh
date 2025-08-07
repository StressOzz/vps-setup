#!/bin/bash
set -e

VERSION="v1.5-final"

# Очистка экрана
clear

# Цвета
GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m' # сброс цвета

# 🎨 Красивый баннер
echo ""
echo "  ██████ ▄▄▄█████▓ ██▀███  ▓█████   ██████   ██████ ";
echo "▒██    ▒ ▓  ██▒ ▓▒▓██ ▒ ██▒▓█   ▀ ▒██    ▒ ▒██    ▒ ";
echo "░ ▓██▄   ▒ ▓██░ ▒░▓██ ░▄█ ▒▒███   ░ ▓██▄   ░ ▓██▄   ";
echo "  ▒   ██▒░ ▓██▓ ░ ▒██▀▀█▄  ▒▓█  ▄   ▒   ██▒  ▒   ██▒";
echo "▒██████▒▒  ▒██▒ ░ ░██▓ ▒██▒░▒████▒▒██████▒▒▒██████▒▒";
echo "▒ ▒▓▒ ▒ ░  ▒ ░░   ░ ▒▓ ░▒▓░░░ ▒░ ░▒ ▒▓▒ ▒ ░▒ ▒▓▒ ▒ ░";
echo "░ ░▒  ░ ░    ░      ░▒ ░ ▒░ ░ ░  ░░ ░▒  ░ ░░ ░▒  ░ ░";
echo "░  ░  ░    ░        ░░   ░    ░   ░  ░  ░  ░  ░  ░  ";
echo "      ░              ░        ░  ░      ░        ░  ";
echo ""

echo -e "${GREEN}Версия скрипта: $VERSION${NC}"
echo -n "🚀 Запуск скрипта"; for i in {1..5}; do echo -n "."; sleep 0.3; done; echo -e "\n"

# Параметры
PASS="Str3\$\$0zz!98!"
PORT="11953"

echo -e "${GREEN}1️⃣ Отключаем пинг (ICMP echo-request)...${NC}"
sudo nft add table inet filter 2>/dev/null
sudo nft add chain inet filter input '{ type filter hook input priority 0; policy accept; }' 2>/dev/null
sudo nft add rule inet filter input icmp type echo-request drop
sudo nft list ruleset | sudo tee /etc/nftables.conf > /dev/null
sudo systemctl enable nftables
sudo mkdir -p /etc/systemd/system/nftables.service.d
echo -e '[Service]\nExecStart=\nExecStart=/usr/sbin/nft -f /etc/nftables.conf' | sudo tee /etc/systemd/system/nftables.service.d/override.conf > /dev/null
sudo systemctl daemon-reexec
sudo systemctl restart nftables

echo -e "${GREEN}2️⃣ Меняем SSH-порт на ${CYAN}${PORT}${NC}${GREEN}...${NC}"
sudo sed -i "s/^#Port 22/Port $PORT/" /etc/ssh/sshd_config
sudo systemctl restart sshd

echo -e "${GREEN}3️⃣ Устанавливаем пароль root...${NC}"
echo "root:$PASS" | sudo chpasswd

# Финальная информация
IP=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}✅ Настройка завершена!${NC}"
echo -e "${GREEN}=============================="
echo -e "🌐 IP сервера: ${CYAN}${IP}${NC}"
echo -e "📦 Порт SSH:   ${CYAN}${PORT}${NC}"
echo -e "🔑 Пароль root: ${CYAN}${PASS}${NC}"
echo -e "==============================${NC}"
