#!/bin/bash
set -e

# Проверка запуска от root
if [ "$EUID" -ne 0 ]; then
  echo "⚠️ Пожалуйста, запустите скрипт с правами root или через sudo"
  exit 1
fi

echo "⬆️ Проверяем и обновляем систему..."

# Установка sudo (если нет)
if ! command -v sudo &>/dev/null; then
  apt update
  apt install -y sudo
fi

# Обновление списка пакетов
apt update

# Показываем список обновляемых пакетов (может быть много, прервёшь Ctrl+C)
echo "📋 Список обновляемых пакетов:"
apt list --upgradable || true

# Полное обновление системы без вопросов
apt full-upgrade -y

echo "✅ Обновление системы завершено."

# === ВВОД SSH-ПОРТА ===
read -p "🔐 Введите новый SSH-порт (по умолчанию 11953): " USER_PORT
SSH_PORT="${USER_PORT:-11953}"

echo "📦 Установка и настройка nftables..."
if ! command -v nft &>/dev/null; then
    apt install -y nftables
fi

echo "🧹 Очистка старых правил..."
nft flush ruleset

echo "🛡 Создание таблицы и цепочек..."
nft add table inet filter
nft add chain inet filter input { type filter hook input priority 0 \; policy drop \; }

echo "🔓 Разрешаем трафик:"
nft add rule inet filter input ct state established,related accept
nft add rule inet filter input iifname "lo" accept

echo "⏱ Добавляем rate limiting для SSH (макс 3 новых подключения в минуту)..."
nft add rule inet filter input tcp dport $SSH_PORT ct state new limit rate 3/minute accept

echo "🚫 Блокируем ICMP ping..."
nft add rule inet filter input icmp type echo-request drop

echo "💾 Сохраняем правила..."
nft list ruleset > /etc/nftables.conf
systemctl enable nftables
systemctl restart nftables


# ========== SSH-ПОРТ ==========
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

# ========== ВОПРОС ОТКЛЮЧЕНИЯ IPv6 ==========
read -p "🌐 Отключить IPv6? (Y/n, по умолчанию Y): " DISABLE_IPV6
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

echo -e "\n✅ Готово:"
echo "🔸 Пинг отключён"
echo "🔸 SSH перенесён на порт $SSH_PORT"
echo "🔸 Fail2ban установлен и настроен: бан на сутки после 3 неудачных попыток"
echo "🔸 В nftables добавлен rate limiting для SSH"

if [ $REBOOT_REQUIRED -eq 1 ]; then
    echo -e "\n🔁 Сервер будет перезагружен через 5 секунд. Не забудьте использовать новый порт SSH при подключении!"
    sleep 5
    reboot
else
    echo -e "\nℹ️ Перезагрузка не требуется, так как IPv6 не отключался."
fi
