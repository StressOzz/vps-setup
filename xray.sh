#!/bin/sh
echo "=== Установка luci-app-xray ==="

opkg update
opkg install wget unzip

TMP_DIR="/tmp/luci-xray"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

echo "[1/3] Скачиваем luci-app-xray..."
wget -q --show-progress https://github.com/yichya/luci-app-xray/archive/refs/heads/main.zip -O luci-app-xray.zip || {
  echo "Ошибка: не удалось скачать luci-app-xray."
  exit 1
}

echo "[2/3] Распаковываем и копируем..."
unzip -q luci-app-xray.zip || {
  echo "Ошибка: не удалось распаковать архив."
  exit 1
}
cp -r luci-app-xray-main/* /usr/lib/lua/luci/ || {
  echo "Ошибка: не удалось скопировать файлы."
  exit 1
}

rm -rf "$TMP_DIR"

echo "[3/3] Перезапускаем LuCI..."
/etc/init.d/rpcd restart
/etc/init.d/uhttpd restart

echo "=== Установка завершена ==="
echo "Зайди в веб-интерфейс OpenWRT — должен появиться раздел «Xray»."

# Опционально: проверка архитектуры
ARCH=$(uname -m)
echo "Архитектура устройства: $ARCH (должна быть mipsel_24kc)"
