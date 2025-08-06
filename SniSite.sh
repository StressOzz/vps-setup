#!/bin/bash
set -e

# Проверка дистрибутива
if ! grep -Eq "^(ID=debian|ID=ubuntu)" /etc/os-release; then
    echo "Поддерживаются только Debian/Ubuntu"
    exit 1
fi

# Ввод домена
read -p "Введите доменное имя: " DOMAIN
[[ -z "$DOMAIN" ]] && echo "Домен не может быть пустым" && exit 1

# Порт по умолчанию
read -p "Введите внутренний SNI Self порт (Enter для 9000): " SPORT
SPORT=${SPORT:-9000}

# Получение IP
external_ip=$(curl -s --max-time 3 https://api.ipify.org)
[[ -z "$external_ip" ]] && echo "Не удалось определить внешний IP" && exit 1

echo "Внешний IP сервера: $external_ip"

# Проверка A-записи
command -v dig >/dev/null || apt install -y dnsutils
domain_ip=$(dig +short A "$DOMAIN")
[[ -z "$domain_ip" ]] && echo "Нет A-записи для $DOMAIN" && exit 1
echo "A-запись домена $DOMAIN указывает на: $domain_ip"

# Сравнение IP
if [[ "$domain_ip" != "$external_ip" ]]; then
    echo "⚠️ A-запись не совпадает с внешним IP. Подробности: https://wiki.yukikras.net/ru/selfsni"
    exit 1
fi

# Проверка портов
for port in 443 80; do
    if ss -tuln | grep -q ":$port "; then
        echo "Порт $port занят. Освободите порт. Подробнее: https://wiki.yukikras.net/ru/selfsni"
        exit 1
    else
        echo "Порт $port свободен"
    fi
done

# Установка ПО
apt update
apt install -y nginx certbot python3-certbot-nginx git

# Скачивание сайта-заглушки
TEMP_DIR=$(mktemp -d)
git clone --depth 1 https://github.com/learning-zone/website-templates.git "$TEMP_DIR"
SITE_DIR=$(find "$TEMP_DIR" -mindepth 1 -maxdepth 1 -type d | shuf -n 1)
cp -r "$SITE_DIR"/* /var/www/html/

# Временный HTTP-конфиг для получения сертификата
cat > /etc/nginx/sites-enabled/temp.conf <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    root /var/www/html;
    index index.html;
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

systemctl reload nginx

# Получение сертификата
certbot --nginx -d "$DOMAIN" --agree-tos -m "admin@$DOMAIN" --non-interactive

# Удаление временного конфига
rm /etc/nginx/sites-enabled/temp.conf

# Финальный конфиг SNI Self
cat > /etc/nginx/sites-enabled/sni.conf <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 127.0.0.1:$SPORT ssl http2;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384";

    ssl_stapling on;
    ssl_stapling_verify on;

    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;

    real_ip_header proxy_protocol;
    set_real_ip_from 127.0.0.1;

    location / {
        root /var/www/html;
        index index.html;
    }
}
EOF

# Проверка и перезапуск nginx
nginx -t && systemctl reload nginx

# Очистка
rm -rf "$TEMP_DIR"

# Финальный вывод
echo ""
echo "✅ УСПЕШНО:"
echo "  Сертификат: /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
echo "  Ключ:       /etc/letsencrypt/live/$DOMAIN/privkey.pem"
echo ""
echo "➡️  Используйте следующие параметры:"
echo "  Dest: 127.0.0.1:$SPORT"
echo "  SNI:  $DOMAIN"
echo ""
echo "💡 Проверка конфигурации: https://wiki.yukikras.net/ru/selfsni"
