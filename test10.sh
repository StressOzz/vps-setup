#!/bin/bash

RESET='\033[0m'
STEPS=20
DELAY=0.005

gray() {
    local step=$1
    local value=$(( step * 255 / STEPS ))
    printf "\033[38;2;${value};${value};${value}m"
}

TEXT='███████╗████████╗██████╗ ███████╗███████╗███████╗
██╔════╝╚══██╔══╝██╔══██╗██╔════╝██╔════╝██╔════╝
███████╗   ██║   ██████╔╝█████╗  ███████╗███████╗
╚════██║   ██║   ██╔══██╗██╔══╝  ╚════██║╚════██║
███████║   ██║   ██║  ██║███████╗███████║███████║
╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝'

IFS=$'\n' read -r -a LINES <<< "$TEXT"

clear

for (( r=0; r<${#LINES[@]}; r++ )); do
    for (( step=0; step<=STEPS; step++ )); do
        clear
        for (( i=0; i<=r; i++ )); do
            if (( i < r )); then
                echo -e "\033[38;2;255;255;255m${LINES[$i]}$RESET"
            else
                echo -e "$(gray $step)${LINES[$i]}$RESET"
            fi
        done
        sleep $DELAY
    done
done
