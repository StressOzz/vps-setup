#!/bin/bash
set -e
echo "📦 Проверка nftables..."
if ! command -v nft &>/dev/null; then
    apt update && apt install -y nftables
fi
echo "🧹 Очистка старых правил (не запрещаем ничего лишнего)..."
nft flush ruleset
echo "🛠 Создание базовой таблицы без блокировки портов..."
nft add table inet filter
nft add chain inet filter input { type filter hook input priority 0 \; policy accept\; }
echo "🚫 Блокировка входящих ping-запросов (ICMP echo-request)..."
nft add rule inet filter input icmp type echo-request drop
echo "💾 Сохраняем правила..."
nft list ruleset > /etc/nftables.conf
systemctl enable nftables
systemctl restart nftables
# ========== SSH-ПОРТ ==========
echo "🔐 Перенос SSH на порт 11953..."
SSHD_CONFIG="/etc/ssh/sshd_config"
cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak"
if grep -q "^#*Port " "$SSHD_CONFIG"; then
    sed -i 's/^#*Port .*/Port 11953/' "$SSHD_CONFIG"
else
    echo "Port 11953" >> "$SSHD_CONFIG"
fi
systemctl restart sshd
if ss -tln | grep -q ":11953"; then
    echo "✅ SSH успешно перенесён на порт 11953"
else
    echo "❌ ВНИМАНИЕ: SSH не слушает на новом порту!"
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
# ========== УДАЛЕНИЕ СКРИПТА ==========
echo "🧽 Удаление скрипта: $0"
rm -- "$0"
echo -e "\n✅ Готово. Пинг отключён, IPv6 отключён, SSH перенесён на 11953. Не забудь изменить порт SHH в настройках входа !."
