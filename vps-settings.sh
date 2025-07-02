#!/bin/bash
set -e

# === ВВОД SSH-ПОРТА ===
read -p "🔐 Введите новый SSH-порт (по умолчанию 11953): " USER_PORT
SSH_PORT="${USER_PORT:-11953}"

echo "📦 Установка и настройка nftables..."
if ! command -v nft &>/dev/null; then
    apt update && apt install -y nftables
fi

echo "🧹 Очистка старых правил..."
nft flush ruleset

echo "🛡 Создание таблицы и цепочек..."
nft add table inet filter
nft add chain inet filter input { type filter hook input priority 0 \; policy drop \; }

echo "🔓 Разрешаем трафик:"
nft add rule inet filter input ct state established,related accept
nft add rule inet filter input iifname "lo" accept
nft add rule inet filter input tcp dport $SSH_PORT accept comment \"SSH-порт\"

echo "🚫 Блокируем ICMP ping..."
nft add rule inet filter input icmp type echo-request drop

echo "💾 Сохраняем правила..."
nft list ruleset > /etc/nftables.conf
systemctl enable nftables
systemctl restart nftables

# ========== SSH-ПОРТ ==========
echo "🔐 Перенос SSH на порт $SSH_PORT..."
SSHD_CONFIG="/etc/ssh/sshd_config"
cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak"

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

# ========== ОТКЛЮЧЕНИЕ IPv6 ==========
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

echo -e "\n✅ Готово:"
echo "🔸 Пинг отключён"
echo "🔸 IPv6 отключён (для полного отключения — reboot)"
echo "🔸 SSH перенесён на порт $SSH_PORT"
