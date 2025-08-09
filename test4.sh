#!/bin/bash

# Функция: цвет по позиции (радужный градиент)
rainbow() {
    local pos=$1
    local r=$(( (pos * 7) % 255 ))
    local g=$(( (pos * 13) % 255 ))
    local b=$(( (pos * 17) % 255 ))
    printf "\033[38;2;${r};${g};${b}m"
}

RESET='\033[0m'
DELAY=0.004  # Задержка для анимации

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

rows=${#LINES[@]}
cols=0
for line in "${LINES[@]}"; do
    (( ${#line} > cols )) && cols=${#line}
done

# Массив для статуса символов (0 = пусто, 1 = показано)
declare -A shown
for r in $(seq 0 $rows); do
    for c in $(seq 0 $cols); do
        shown["$r,$c"]=0
    done
done

# Максимальная диагональ
max_diag=$((rows + cols - 2))

# Появление по диагоналям
for diag in $(seq 0 $max_diag); do
    clear
    for r in $(seq 0 $rows); do
        out=""
        for c in $(seq 0 $cols); do
            if (( r < rows && c < ${#LINES[$r]} )); then
                if (( r + c <= diag )); then
                    shown["$r,$c"]=1
                fi
                if (( shown["$r,$c"] == 1 )); then
                    out+="$(rainbow $((r*cols+c)))${LINES[$r]:$c:1}"
                else
                    out+=" "
                fi
            fi
        done
        out+=$RESET
        echo -e "$out"
    done
