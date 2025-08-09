#!/bin/sh
echo "=== Установка luci-app-xray ==="

opkg update
opkg install wget unzip

TMP_DIR="/tmp/luci-xray"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

echo "[1/3] Скачиваем luci-app-xray..."
wget https://github.com/yichya/luci-app-xray/archive/refs/heads/main.zip -O luci-app-xray.zip
if [ $? -ne 0 ]; then
    echo "Ошибка: не удалось скачать luci-app-xray."
    exit 1
fi

echo "[2/3] Распаковываем и копируем..."
unzip -q luci-app-xray.zip
cp -r luci-app-xray-main/* /usr/lib/lua/luci/

rm -rf "$TMP_DIR"

echo "[3/3] Перезапускаем LuCI..."
/etc/init.d/rpcd restart
/etc/init.d/uhttpd restart

echo "=== Установка завершена ==="
echo "Зайди в веб-интерфейс OpenWRT — должен появиться раздел «Xray»."
