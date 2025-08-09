#!/bin/sh

echo "=== Установка luci-app-xray ==="

# Проверка наличия wget и unzip
opkg update
opkg install wget unzip

# Временная папка
TMP_DIR="/tmp/luci-xray"
rm -rf $TMP_DIR
mkdir -p $TMP_DIR
cd $TMP_DIR

# Скачивание последней версии с GitHub
echo "[1/3] Скачиваем luci-app-xray..."
wget -q --show-progress https://github.com/yichya/luci-app-xray/archive/refs/heads/main.zip -O luci-app-xray.zip
if [ $? -ne 0 ]; then
    echo "Ошибка: не удалось скачать luci-app-xray."
    exit 1
fi

# Распаковка
echo "[2/3] Распаковываем..."
unzip -q luci-app-xray.zip
cp -r luci-app-xray-main/* /usr/lib/lua/luci/

# Очистка
rm -rf $TMP_DIR

# Перезапуск сервисов LuCI
echo "[3/3] Перезапускаем LuCI..."
/etc/init.d/rpcd restart
/etc/init.d/uhttpd restart

echo "=== Установка luci-app-xray завершена ==="
echo "Открой веб-интерфейс LuCI и ищи 'Xray' в меню."
