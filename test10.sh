#!/bin/bash

clear

# 🎨 Цвета
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[1;34m'
cyan='\033[1;36m'
plain='\033[0m'

# Проверка root
if [[ $EUID -ne 0 ]]; then
  echo -e "${red}Ошибка: скрипт нужно запускать от root.${plain}" >&2
  exit 1
fi

# Проверяем наличие команды x-ui
if command -v x-ui &> /dev/null; then
    echo -e "${yellow}Обнаружена установленная панель x-ui.${plain}"

    # Запрос у пользователя на переустановку
    printf "${green}Вы хотите переустановить x-ui? [y/N]: ${plain}"
    read confirm
    confirm=${confirm,,}  # перевод в нижний регистр

    if [[ "$confirm" != "y" && "$confirm" != "yes" ]]; then
        echo -e "${yellow}Отмена. Скрипт завершает работу.${plain}"
        exit 1
    fi

    echo -e "${red}Удаление x-ui...${plain}"
    /usr/local/x-ui/x-ui uninstall -y &>/dev/null || true
    rm -rf /usr/local/x-ui /etc/x-ui /usr/bin/x-ui /etc/systemd/system/x-ui.service
    systemctl daemon-reexec
    systemctl daemon-reload
    rm -f /root/3x-ui.txt
    echo -e "${green}x-ui успешно удалена. Продолжаем выполнение скрипта...${plain}"
fi

# Вывод всех команд кроме диалога — в лог
exec 3>&1
LOG_FILE="/var/log/3x-ui_install_log.txt"
exec > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)

# === Порт панели ===
PORT=8080
    
echo -e "Весь процесс установки будет сохранён в файле: ${cyan}${LOG_FILE}${plain}" >&3
echo -e "\n${blue}Идёт установка... Пожалуйста, не закрывайте терминал.${plain}" >&3

# ... 👇 дальше весь твой код без изменений
# в нём цвета заменил аналогично:
#   - ошибки = ${red}
#   - успехи = ${green}
#   - инфо/лог = ${cyan}
#   - заголовки = ${blue}
#   - дефолтный текст = ${plain}

# Пример использования ниже:

# Проверка GLIBC
glibc_version=$(ldd --version | head -n1 | awk '{print $NF}')
required_version="2.32"
if [[ "$(printf '%s\n' "$required_version" "$glibc_version" | sort -V | head -n1)" != "$required_version" ]]; then
    echo -e "${red}GLIBC слишком старая ($glibc_version), требуется >= 2.32.${plain}" >&3
    echo -e "${yellow}Вам необходимо установить более свежую ОС.${plain}" >&3
    exit 1
fi

# В финале:
echo -e "\n${green}Панель управления 3X-UI доступна:${plain}" >&3
echo -e "Адрес: ${cyan}http://${SERVER_IP}:${PORT}/${WEBPATH}${plain}" >&3
echo -e "Логин: ${yellow}${USERNAME}${plain}" >&3
echo -e "Пароль: ${yellow}${PASSWORD}${plain}" >&3
echo -e ""
echo -e "${green}Ваш VPN ключ:${plain}" >&3
echo -e "${cyan}${VLESS_LINK}${plain}" >&3
echo -e ""
echo -e "Все данные сохранены в: ${blue}/root/3x-ui.txt${plain}" >&3
echo -e "QR-код сохранён в файл: ${blue}/root/vless_qr.png${plain}" >&3
echo -e ""
