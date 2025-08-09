#!/bin/bash

# Функция вывода оттенка серого (0–255)
gray() {
    local shade=$1
    printf "\033[38;2;${shade};${shade};${shade}m"
}

RESET='\033[0m'
STEPS=20       # Глубина градиента (от чёрного до белого)
DELAY=0.02     # Задержка между кадрами

# ASCII-текст
TEXT=$(cat << 'EOF'
  █████████   █████                                      
 ███░░░░░███ ░░███                                       
░███    ░░░  ███████   ████████   ██████   █████   █████ 
░░█████████ ░░░███░   ░░███░░███ ███░░███ ███░░   ███░░  
 ░░░░░░░░███  ░███     ░███ ░░░ ░███████ ░░█████ ░░█████ 
 ███    ░███  ░███ ███ ░███     ░███░░░   ░░░░███ ░░░░███
░░█████████   ░░█████  █████    ░░██████  ██████  ██████ 
 ░░░░░░░░░     ░░░░░  ░░░░░      ░░░░░░  ░░░░░░  ░░░░░░  
EOF
)

# Массив строк
IFS=$'\n' read -rd '' -a LINES <<< "$TEXT"

# Общая длина самого длинного ряда
max_len=0
for line in "${LINES[@]}"; do
    (( ${#line} > max_len )) && max_len=${#line}
done

# Анимация: идём по символам слева направо
for pos in $(seq 0 $max_len); do
    clear
    for line in "${LINES[@]}"; do
        out=""
        for (( i=0; i<${#line}; i++ )); do
            if (( i <= pos )); then
                # Плавный градиент для текущей точки
                shade=$(( 255 * (i+1) / (pos+1) ))
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

# Финальное белое отображение
clear
gray 255
echo "$TEXT"
echo -e "$RESET"
