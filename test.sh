#!/bin/bash
set -e

VERSION="v3.5"

# Цвета
GREEN='\033[1;32m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
RED='\033[1;91m'
PURPLE='\033[1;35m'
YELLOW='\033[1;33m'
RESET='\033[0m'

print_stress_fade() {
  local colors=(
    '\033[1;37m'  # ярко-белый
    '\033[0;37m'  # светло-серый
    '\033[0;31m'  # красный
    '\033[0;31m'  # красный (дублируем для плавности)
    '\033[2;31m'  # темно-красный
  )
  local banner_lines=(
"  ██████ ▄▄▄█████▓ ██▀███  ▓█████   ██████   ██████ "
"▒██    ▒ ▓  ██▒ ▓▒▓██ ▒ ██▒▓█   ▀ ▒██    ▒ ▒██    ▒ "
"░ ▓██▄   ▒ ▓██░ ▒░▓██ ░▄█ ▒▒███   ░ ▓██▄   ░ ▓██▄   "
"  ▒   ██▒░ ▓██▓ ░ ▒██▀▀█▄  ▒▓█  ▄   ▒   ██▒  ▒   ██▒"
"▒██████▒▒  ▒██▒ ░ ░██▓ ▒██▒░▒████▒▒██████▒▒▒██████▒▒"
"▒ ▒▓▒ ▒ ░  ▒ ░░   ░ ▒▓ ░▒▓░░░ ▒░ ░▒ ▒▓▒ ▒ ░▒ ▒▓▒ ▒ ░"
"░ ░▒  ░ ░    ░      ░▒ ░ ▒░ ░ ░  ░░ ░▒  ░ ░░ ░▒  ░ ░"
"░  ░  ░    ░        ░░   ░    ░   ░  ░  ░  ░  ░  ░  "
"      ░              ░        ░  ░      ░        ░  "
  )
  local RESET='\033[0m'
  local steps=${#colors[@]}

  clear
  # Вывод баннера построчно сверху вниз
  for line in "${banner_lines[@]}"; do
    echo -e "${colors[0]}$line${RESET}"
    sleep 0.1
  done
  sleep 0.5

  # Постепенная смена цвета сверху вниз
  for ((step=1; step<steps; step++)); do
    clear
    for ((i=0; i<${#banner_lines[@]}; i++)); do
      if (( i < (step * ${#banner_lines[@]} / steps) )); then
        echo -e "${colors[step]}${banner_lines[i]}${RESET}"
      else
        echo -e "${colors[step-1]}${banner_lines[i]}${RESET}"
      fi
    done
    sleep 0.3
  done
}

# Вызов анимации баннера в начале
print_stress_fade
