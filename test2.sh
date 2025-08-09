#!/bin/bash

# Функция: оттенок серого (0–255)
gray() {
    local shade=$1
    printf "\033[38;2;${shade};${shade};${shade}m"
}

RESET='\033[0m'
DELAY=0.005   # Задержка между шагами (очень быстрая)

# ASCII-текст
TEXT=$(cat << 'EOF'
███████╗████████╗██████╗ ███████╗███████╗███████╗
██╔════╝╚══██╔══╝██╔══██╗██╔════╝██╔════╝██╔════╝
███████╗   ██║   ██████╔╝█████╗  ███████╗███████╗
╚════██║   ██║   ██╔══██╗██╔══╝  ╚════██║╚════██║
███████║   ██║   ██║  ██║███████╗███████║███████║
╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝ 
EOF
)

# Разбиваем на строки
IFS=$'\n' read -rd '' -a LINES <<< "$TEXT"

# Максимальная длина строки
max_len=0
for line in "${LINES[@]}"; do
    (( ${#line} > max_len )) && max_len=${#line}
done

# Анимация появления
for pos in $(seq 0 $max_len); do
    clear
    for line in "${LINES[@]}"; do
        out=""
        for (( i=0; i<${#line}; i++ )); do
            if (( i <= pos )); then
                shade=$(( 100 + (155 * i / max_len) )) # быстрый рост яркости
                ((shade > 255)) && shade=255
                out+="$(gray $shade)${line:$i:1}"
            else
                out+="$(gray 0)${line:$i:1}"
            fi
        done
        out+=$RESET
        echo -e "$out"
    done
    sleep $DELAY
done

# Финальный белый текст
clear
gray 255
echo "$TEXT"
echo -e "$RESET"
