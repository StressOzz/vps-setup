# Сохраним текст в переменную, чтобы потом проще рамку сделать
text=$(cat <<'EOF'
\e[31m ██████ \e[33m▄▄▄█████▓ \e[32m██▀███  \e[36m▓█████   \e[34m ██████   \e[35m██████ \e[0m
\e[31m▒██    ▒ \e[33m▓  ██▒ ▓▒\e[32m▓██ ▒ ██▒\e[36m▓█   ▀ \e[34m▒██    ▒ \e[35m▒██    ▒ \e[0m
\e[31m░ ▓██▄   \e[33m▒ ▓██░ ▒░\e[32m▓██ ░▄█ ▒\e[36m▒███   \e[34m░ ▓██▄   \e[35m░ ▓██▄   \e[0m
\e[31m  ▒   ██▒\e[33m░ ▓██▓ ░ \e[32m▒██▀▀█▄  \e[36m▒▓█  ▄   \e[34m▒   ██▒  \e[35m▒   ██▒\e[0m
\e[31m▒██████▒▒\e[33m  ▒██▒ ░ \e[32m░██▓ ▒██▒\e[36m░▒████▒\e[34m▒██████▒▒\e[35m▒██████▒▒\e[0m
\e[31m▒ ▒▓▒ ▒ ░\e[33m  ▒ ░░   \e[32m░ ▒▓ ░▒▓░\e[36m░░ ▒░ ░\e[34m▒ ▒▓▒ ▒ ░\e[35m▒ ▒▓▒ ▒ ░\e[0m
\e[31m░ ░▒  ░ ░\e[33m    ░    \e[32m  ░▒ ░ ▒░\e[36m ░ ░  ░\e[34m░ ░▒  ░ ░\e[35m░ ░▒  ░ ░\e[0m
\e[31m░  ░  ░  \e[33m   ░      \e[32m░░   ░  \e[36m  ░   ░ \e[34m  ░  ░  \e[35m  ░  ░  \e[0m
\e[31m      ░  \e[33m         ░    \e[32m   ░  ░  \e[36m     ░   \e[34m      ░ \e[35m      ░  \e[0m
EOF
)

# Подсчёт ширины — для правильной рамки игнорируем escape-последовательности
# Сначала удалим escape-последовательности цвета из текста:
plain_text=$(echo -e "$text" | sed -r 's/\x1B\[[0-9;]*[mK]//g')

# Найдём максимальную длину строки (без цветных кодов)
max_len=0
while IFS= read -r line; do
    len=${#line}
    (( len > max_len )) && max_len=$len
done <<< "$plain_text"

# Нарисуем рамку и выведем текст
border_top="╔$(printf '═%.0s' $(seq 1 $((max_len + 2))))╗"
border_bottom="╚$(printf '═%.0s' $(seq 1 $((max_len + 2))))╝"

echo -e "$border_top"
while IFS= read -r line; do
    # Чтобы рамка была ровной, добавим пробелы справа если надо
    plain_len=${#line}
    padding=$((max_len - plain_len))
    echo -e "║ $line$(printf ' %.0s' $(seq 1 $padding)) ║"
done <<< "$plain_text"
echo -e "$border_bottom"
