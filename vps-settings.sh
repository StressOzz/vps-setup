#!/bin/bash
set -e

clear

# Цвета
GREEN='\033[1;32m'
NC='\033[0m' # сброс цвета

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

echo -n "🚀 Запуск скрипта"; for i in {1..5}; do echo -n "."; sleep 0.3; done; echo -e "\n"

if [ "$EUID" -ne 0 ]; then
  echo "⚠️ Пожалуйста, запустите скрипт с правами root или через sudo"
  exit 1
fi

echo "⬆️ Проверяем и обновляем систему..."

if ! command -v sudo &>/dev/null; then
  apt update
  apt install -y sudo
fi

apt update
echo "📋 Список обновляемых пакетов:"
apt list --upgradable || true
apt full-upgrade -y
echo "✅ Обновление системы завершено."

echo -ne "${GREEN}🔐 Введите новый SSH-порт (по умолчанию 22): ${NC}"
read USER_PORT
SSH_PORT="${USER_PORT:-22}"

echo "🔐 Перенос SSH на порт $SSH_PORT..."
SSHD_CONFIG="/etc/ssh/sshd_config"
cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak-$(date +%F_%T)"

if grep -q "^#*Port " "$SSHD_CONFIG"; then
    sed -i "s/^#*Port .*/Port $SSH_PORT/" "$SSHD_CONFIG"
else
    echo "Port $SSH_PORT" >> "$SSHD_CONFIG"
fi

systemctl restart sshd

if ss -tln | grep -q ":$SSH_PORT"; then
    echo "✅ SSH слушает на порту $SSH_PORT"
else
    echo "❌ ВНИМАНИЕ: SSH не слушает на новом порту!"
    exit 1
fi

echo -ne "${GREEN}🌐 Отключить IPv6? (Y/n, по умолчанию Y): ${NC}"
read DISABLE_IPV6
DISABLE_IPV6=${DISABLE_IPV6:-Y}

REBOOT_REQUIRED=0

if [[ "$DISABLE_IPV6" =~ ^[Yy]$ ]]; then
    echo "🌐 Отключение IPv6..."
    GRUB_CONF="/etc/default/grub"

    if ! grep -q "ipv6.disable=1" "$GRUB_CONF"; then
        sed -i 's/^GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="ipv6.disable=1 /' "$GRUB_CONF"
        update-grub
    fi

    cat > /etc/sysctl.d/99-disable-ipv6.conf <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF

    sysctl --system
    echo "✅ IPv6 отключён (для полного эффекта нужна перезагрузка)"
    REBOOT_REQUIRED=1
else
    echo "ℹ️ IPv6 оставлен включённым"
fi

echo -ne "${GREEN}📵 Отключить отклик на ping (ICMP Echo)? (Y/n, по умолчанию Y): ${NC}"
read DISABLE_PING
DISABLE_PING=${DISABLE_PING:-Y}

if [[ "$DISABLE_PING" =~ ^[Yy]$ ]]; then
    echo "📵 Отключаем пинг через nftables..."

    if ! nft list table inet filter &>/dev/null; then
        nft add table inet filter
    fi

    if ! nft list chain inet filter input &>/dev/null; then
        nft add chain inet filter input { type filter hook input priority 0 \; policy accept \; }
    fi

    nft add rule inet filter input ip protocol icmp icmp type echo-request drop 2>/dev/null || true
    nft add rule inet filter input ip6 nexthdr icmpv6 icmpv6 type echo-request drop 2>/dev/null || true

    echo "✅ Пинг отключён (ICMP Echo-запросы блокируются)"
else
    echo "ℹ️ Пинг оставлен включённым"
fi

echo -ne "${GREEN}🔑 Хотите сменить пароль пользователя для SSH? (Y/n, по умолчанию Y): ${NC}"
read CHANGE_PASS
CHANGE_PASS=${CHANGE_PASS:-Y}

if [[ "$CHANGE_PASS" =~ ^[Yy]$ ]]; then
  echo "👤 Текущий пользователь: $SUDO_USER"
  TARGET_USER="${SUDO_USER:-root}"

  if id "$TARGET_USER" &>/dev/null; then
    echo "🔐 Введите новый пароль для пользователя '$TARGET_USER':"
    passwd "$TARGET_USER"
    echo "✅ Пароль для пользователя '$TARGET_USER' успешно изменён."
    echo -e "\n📌 Не забудьте сохранить новый пароль для пользователя '$TARGET_USER'!"
  else
    echo "❌ Пользователь '$TARGET_USER' не найден."
  fi
else
  echo "ℹ️ Пароль оставлен без изменений."
fi

echo -e "\n🎉 Всё готово:"
echo "────────────────────────────────────────────"
echo " ✅ SSH перенесён на порт: $SSH_PORT"
[[ "$DISABLE_IPV6" =~ ^[Yy]$ ]] && echo " ✅ IPv6 отключён"
[[ "$DISABLE_PING" =~ ^[Yy]$ ]] && echo " ✅ Пинг отключён"
[[ "$CHANGE_PASS" =~ ^[Yy]$ ]] && echo " ✅ Пароль пользователя '$TARGET_USER' обновлён"
echo "────────────────────────────────────────────"

if [ $REBOOT_REQUIRED -eq 1 ]; then
echo -e "\n\033[32m🔁 Сервер будет перезагружен, для отмены нажмите Ctrl+C.\033[0m"
echo -e "\033[31mПерезагрузка через:\033[0m"
for i in {5..1}; do
    echo -ne " \033[31m$i\033[0m"
    sleep 1.5
done
echo -e "\n\033[32m🚀 Перезагрузка!\033[0m"
reboot
else
    echo -e "\nℹ️ Перезагрузка не требуется."
fi
