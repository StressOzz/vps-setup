#!/bin/sh

echo "=== Установка luci-app-xray ==="

# Ждём, если opkg занят
while [ -f /var/lock/opkg.lock ]; do
    echo "opkg занят другим процессом, жду..."
    sleep 3
done

opkg update
opkg install wget unzip xray-core

TMP_DIR="/tmp/luci-xray"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR" || exit 1

echo "[1/3] Скачиваем luci-app-xray..."
wget --no-check-certificate https://codeload.github.com/yichya/luci-app-xray/zip/refs/heads/master -O luci-app-xray.zip
if [ $? -ne 0 ]; then
    echo "Ошибка: не удалось скачать luci-app-xray."
    exit 1
fi

echo "[2/3] Распаковываем и копируем..."

# Создаем нужную папку, если нет
mkdir -p /usr/lib/lua/luci

unzip -q luci-app-xray.zip

cp -r luci-app-xray-master/* /usr/lib/lua/luci/ || {
    echo "Ошибка: не удалось скопировать файлы."
    exit 1
}

rm -rf "$TMP_DIR"

echo "[3/3] Перезапускаем LuCI..."
/etc/init.d/rpcd restart
/etc/init.d/uhttpd restart

echo "=== Установка завершена ==="
echo "Открой веб-интерфейс OpenWRT — раздел «Xray» должен появиться."
