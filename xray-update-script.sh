#!/bin/bash
set -e

CONTAINER="amnezia-xray"

echo "[*] Текущая версия Xray в контейнере:"
docker exec $CONTAINER xray --version || echo "Xray не найден"

# Получаем последнюю версию Xray с GitHub
LATEST=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')

if [ -z "$LATEST" ]; then
    echo "[!] Не удалось получить последнюю версию."
    exit 1
fi

echo "[*] Последняя версия: $LATEST"
URL="https://github.com/XTLS/Xray-core/releases/download/v$LATEST/Xray-linux-64.zip"

# Удаляем старый архив и распакованную папку внутри контейнера, если есть
docker exec $CONTAINER sh -c 'rm -f /tmp/Xray-linux-64.zip'
docker exec $CONTAINER sh -c 'rm -rf /tmp/xray-new'

# Скачиваем и распаковываем внутри контейнера
echo "[*] Скачиваем и распаковываем Xray $LATEST внутри контейнера..."
docker exec $CONTAINER sh -c "
wget -q -O /tmp/Xray-linux-64.zip $URL &&
unzip -oq /tmp/Xray-linux-64.zip -d /tmp/xray-new &&
cp /tmp/xray-new/xray /usr/bin/xray &&
chmod +x /usr/bin/xray
"

# Перезапускаем контейнер
echo "[*] Перезапускаем контейнер..."
docker restart $CONTAINER

# Проверяем версию после обновления
echo "[*] Новая версия Xray в контейнере:"
docker exec $CONTAINER xray --version

echo "[+] Обновление завершено!"
