#!/bin/sh

# Цвета
GREEN='\033[1;32m'
CYAN='\033[1;36m'
RED='\033[1;31m'
RESET='\033[0m'

echo "${CYAN}=== Установка luci-app-xray ===${RESET}"

# Ждём, если opkg занят
while [ -f /var/lock/opkg.lock ]; do
    echo "${RED}opkg занят другим процессом, жду...${RESET}"
    sleep 3
done

# Обновляем пакеты и ставим зависимости
opkg update
opkg install wget unzip xray-core

TMP_DIR="/tmp/luci-xray"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR" || exit 1

echo "${CYAN}[1/3] Скачиваем luci-app-xray...${RESET}"
wget --no-check-certificate https://codeload.github.com/yichya/luci-app-xray/zip/refs/heads/master -O luci-app-xray.zip
if [ $? -ne 0 ]; then
    echo "${RED}Ошибка: не удалось скачать luci-app-xray.${RESET}"
    exit 1
fi

echo "${CYAN}[2/3] Распаковываем и копируем...${RESET}"
unzip -q luci-app-xray.zip
cp -r luci-app-xray-master/* /usr/lib/lua/luci/ || {
    echo "${RED}Ошибка: не удалось скопировать файлы.${RESET}"
    exit 1
}

rm -rf "$TMP_DIR"

echo "${CYAN}[3/3] Перезапускаем LuCI...${RESET}"
/etc/init.d/rpcd restart
/etc/init.d/uhttpd restart

echo "${GREEN}=== Установка завершена ===${RESET}"
echo "${CYAN}Открой веб-интерфейс OpenWRT — в меню должен появиться пункт «Xray».${RESET}"
