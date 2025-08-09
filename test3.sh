#!/bin/bash

# Функция: радуга по позиции
rainbow() {
    local pos=$1
    local r=$(( (pos * 7) % 255 ))
    local g=$(( (pos * 13) % 255 ))
    local b=$(( (pos * 17) % 255 ))
    printf "\033[38;2;${r};${g};${b}m"
}

RESET='\033[0m'
DELAY=0.004   # Очень быстрая анимация

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

# Разбиваем на строки
IFS=$'\n' read -rd '' -a LINES <<< "$TEXT"

# Максимальная длина строки
max_len=0
for line in "${LINES[@]}"; do
    (( ${#line} > max_len )) && max_len=${#line}
done

# Анимация появления радугой
for pos in $(seq 0 $max_len); do
    clear
    for line in "${LINES[@]}"; do
        out=""
        for (( i=0; i<${#line}; i++ )); do
            if (( i <= pos )); then
                out+="$(rainbow $((i*5+pos)))${line:$i:1}"
            else
                out+="\033[38;2;0;0;0m${line:$i:1}"
            fi
        done
        out+=$RESET
        echo -e "$out"
    done
    sleep $DELAY
done

# Финальный переливающийся текст
clear
for line in "${LINES[@]}"; do
    out=""
    for (( i=0; i<${#line}; i++ )); do
        out+="$(rainbow $((i*10)))${line:$i:1}"
    done
    out+=$RESET
    echo -e "$out"
done
