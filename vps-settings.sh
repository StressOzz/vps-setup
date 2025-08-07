#!/bin/bash
set -e

VERSION="v2.1"

clear

GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m'

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

# 1. Обновление системы
echo -e "${GREEN}1️⃣ Обновляем систему...${NC}"
apt update
apt install -y sudo
sudo apt update
sudo apt list --upgradable || true
sudo apt full-upgrade -y
echo -e "${GREEN}✅ Система обновлена.${NC}\n"

# 2. Ввод нового SSH-порта
read -rp "$(echo -e ${GREEN}2️⃣ Введите новый SSH порт (оставьте пустым, чтобы не менять):${NC} )" PORT
if [ -n "$PORT" ]; then
  while ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; do
    echo -e "${GREEN}Ошибка: введите корректный числовой порт от 1 до 65535.${NC}"
    read -rp "$(echo -e ${GREEN}Введите новый SSH порт (оставьте пустым, чтобы не менять):${NC} )" PORT
  done
  echo -e "${GREEN}Меняем SSH порт на ${CYAN}${PORT}${NC}...${NC}"
  if grep -q "^Port " /etc/ssh/sshd_config; then
    sudo sed -i "s/^Port .*/Port $PORT/" /etc/ssh/sshd_config
  else
    echo "Port $PORT" | sudo tee -a /etc/ssh/sshd_config > /dev/null
  fi
  sudo systemctl restart sshd
  echo -e "${GREEN}✅ SSH порт изменён на ${CYAN}${PORT}${NC}.${NC}\n"
else
  echo -e "${GREEN}SSH порт оставлен без изменений.${NC}\n"
fi

# 3. Ввод нового пароля root
read -rsp "$(echo -e ${GREEN}3️⃣ Введите новый пароль root (оставьте пустым, чтобы не менять):${NC} )" PASS
echo
if [ -n "$PASS" ]; then
  echo -e "${GREEN}Устанавливаем новый пароль root...${NC}"
  echo "root:$PASS" | sudo chpasswd
  echo -e "${GREEN}✅ Пароль root изменён.${NC}\n"
else
  echo -e "${GREEN}Пароль root оставлен без изменений.${NC}\n"
fi

# 4. Отключение пинга
echo -e "${GREEN}4️⃣ Отключаем пинг (ICMP echo-request)...${NC}"
sudo nft add table inet filter 2>/dev/null || true
sudo nft add chain inet filter input '{ type filter hook input priority 0; policy accept; }' 2>/dev/null || true
sudo nft add rule inet filter input icmp type echo-request drop
sudo nft list ruleset | sudo tee /etc/nftables.conf > /dev/null
sudo systemctl enable nftables
sudo mkdir -p /etc/systemd/system/nftables.service.d
echo -e '[Service]\nExecStart=\nExecStart=/usr/sbin/nft -f /etc/nftables.conf' | sudo tee /etc/systemd/system/nftables.service.d/override.conf > /dev/null
sudo systemctl daemon-reexec
sudo systemctl restart nftables
echo -e "${GREEN}✅ Пинг (ICMP echo-request) отключён.${NC}\n"

# 5. Итоговая информация
IP=$(hostname -I | tr ' ' '\n' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n1)
echo -e "${GREEN}✅ Все настройки выполнены!${NC}"
echo -e "${GREEN}=============================="
echo -e "🌐 IP сервера: ${CYAN}${IP}${NC}"
if [ -n "$PORT" ]; then
  echo -e "📦 Порт SSH:   ${CYAN}${PORT}${NC}"
else
  echo -e "📦 Порт SSH:   ${CYAN}оставлен прежним${NC}"
fi
if [ -n "$PASS" ]; then
  echo -e "🔑 Пароль root: ${CYAN}${PASS}${NC}"
else
  echo -e "🔑 Пароль root: ${CYAN}оставлен прежним${NC}"
fi
echo -e "==============================${NC}"

# 6. Перезагрузка
echo -ne "${GREEN}Перезагрузить систему сейчас? (Y/n): ${NC}"
read REBOOT_ANSWER
REBOOT_ANSWER=${REBOOT_ANSWER:-Y}

if [[ "$REBOOT_ANSWER" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Перезагрузка...${NC}"
    sudo reboot
else
    echo -e "${GREEN}Перезагрузка отменена. Скрипт завершён.${NC}"
fi
