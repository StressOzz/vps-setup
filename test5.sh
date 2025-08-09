#!/bin/bash

# Функция: цвет по позиции (радужный)
rainbow() {
    local pos=$1
    local r=$(( (pos * 7) % 255 ))
    local g=$(( (pos * 13) % 255 ))
    local b=$(( (pos * 17) % 255 ))
    printf "\033[38;2;${r};${g};${b}m"
}

RESET='\033[0m'
DELAY=0.004

# ASCII-текст
read -r -d '' TEXT << 'EOF'
███████╗████████╗██████╗ ███████╗███████╗███████╗
██╔════╝╚══██╔══╝██╔══██╗██╔════╝██╔════╝██╔════╝
███████╗   ██║   ██████╔╝█████╗  ███████╗███████╗
╚════██║   ██║   ██╔══██╗██╔══╝  ╚════██║╚════██║
███████║   ██║   ██║  ██║███████╗███████║███████║
╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝
EOF

IFS=$'\n' read -rd '' -a LINES <<< "$TEXT"

rows=${#LINES[@]}
cols=0
for line in "${LINES[@]}"; do
    (( ${#line} > cols )) && cols=${#line}
done

declare -A shown
for (( r=0; r<rows; r++ )); do
    for (( c=0; c<cols; c++ )); do
        shown["$r,$c"]=0
    done
done

max_diag=$((rows + cols - 2))

for (( diag=0; diag<=max_diag; diag++ )); do
    clear
    for (( r=0; r<rows; r++ )); do
        out=""
        for (( c=0; c<${#LINES[$r]}; c++ )); do
            if (( r + c <= diag )); then
                shown["$r,$c"]=1
            fi
            if (( shown["$r,$c"] == 1 )); then
                out+="$(rainbow $((r*cols+c)))${LINES[$r]:$c:1}"
            else
                out+=" "
            fi
        done
        out+=$RESET
        echo -e "$out"
    done
    sleep $DELAY
done

clear
for (( r=0; r<rows; r++ )); do
    out=""
    for (( c=0; c<${#LINES[$r]}; c++ )); do
        out+="$(rainbow $((r*cols+c)))${LINES[$r]:$c:1}"
    done
    out+=$RESET
    echo -e "$out"
done
