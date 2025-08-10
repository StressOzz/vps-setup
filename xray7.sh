#!/bin/sh

echo "=== Установка luci-app-xray (ручной метод) ==="

while [ -f /var/lock/opkg.lock ]; do
    echo "opkg занят, жду..."
    sleep 3
done

opkg update
opkg install wget unzip

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

echo "[2/3] Распаковываем..."

unzip -q luci-app-xray.zip || {
    echo "Ошибка распаковки"
    exit 1
}

echo "[3/3] Копируем файлы..."

# Создаём папки для всех нужных директорий, если их нет
mkdir -p /usr/lib/lua/luci
mkdir -p /usr/lib/lua/luci/controller
mkdir -p /usr/lib/lua/luci/model/cbi/xray
mkdir -p /usr/lib/lua/luci/model/xray
mkdir -p /usr/lib/lua/luci/view/xray

# Копируем содержимое архива в папку LuCI
cp -r luci-app-xray-master/* /usr/lib/lua/luci/ || {
    echo "Ошибка копирования файлов"
    exit 1
}

rm -rf "$TMP_DIR"

echo "Перезапускаем LuCI..."
/etc/init.d/rpcd restart
/etc/init.d/uhttpd restart

echo "=== Установка luci-app-xray завершена ==="
echo "Проверь веб-интерфейс — должен появиться пункт Xray."
