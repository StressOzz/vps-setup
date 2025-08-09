    echo -e "\e[31m ██████ \e[33m▄▄▄█████▓ \e[32m██▀███  \e[36m▓█████   \e[34m ██████   \e[35m██████ \e[0m"
    echo -e "\e[31m▒██    ▒ \e[33m▓  ██▒ ▓▒\e[32m▓██ ▒ ██▒\e[36m▓█   ▀ \e[34m▒██    ▒ \e[35m▒██    ▒ \e[0m"
    echo -e "\e[31m░ ▓██▄   \e[33m▒ ▓██░ ▒░\e[32m▓██ ░▄█ ▒\e[36m▒███   \e[34m░ ▓██▄   \e[35m░ ▓██▄   \e[0m"
    echo -e "\e[31m  ▒   ██▒\e[33m░ ▓██▓ ░ \e[32m▒██▀▀█▄  \e[36m▒▓█  ▄   \e[34m▒   ██▒  \e[35m▒   ██▒\e[0m"
    echo -e "\e[31m▒██████▒▒\e[33m  ▒██▒ ░ \e[32m░██▓ ▒██▒\e[36m░▒████▒\e[34m▒██████▒▒\e[35m▒██████▒▒\e[0m"
    echo -e "\e[31m▒ ▒▓▒ ▒ ░\e[33m  ▒ ░░   \e[32m░░▒▓ ░▒▓░\e[36m░░ ▒░ ░\e[34m▒ ▒▓▒ ▒ ░\e[35m▒ ▒▓▒ ▒ ░\e[0m"
    echo -e "\e[31m░ ░▒  ░ ░\e[33m    ░    \e[32m ░░▒ ░ ▒░\e[36m ░ ░  ░\e[34m░ ░▒  ░ ░\e[35m░ ░▒  ░ ░\e[0m"
    echo -e "\e[31m░  ░  ░  \e[33m   ░      \e[32m ░   ░  \e[36m  ░    ░ \e[34m ░  ░  \e[35m   ░  ░  \e[0m"
    echo -e "\e[31m      ░  \e[33m   ░    \e[32m       ░  \e[36m   ░   \e[34m       ░ \e[35m      ░  \e[0m"
echo -e "111"

#!/bin/bash

text=(
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

# Массив цветов ANSI (код цвета - цифра после \e[ )
colors=(31 32 33 34 35 36 91 92 93 94 95 96)

# Функция для рандомного цвета из массива colors
rand_color() {
  echo ${colors[$RANDOM % ${#colors[@]}]}
}

# Вариант 1: каждый символ случайного цвета
color_variant_1() {
  for line in "${text[@]}"; do
    for ((i=0; i<${#line}; i++)); do
      char="${line:$i:1}"
      c=$(rand_color)
      echo -ne "\e[${c}m${char}\e[0m"
    done
    echo
  done
}

# Вариант 2: каждая строка своим цветом, буквы чередуются двумя цветами
color_variant_2() {
  local c1 c2
  for idx in "${!text[@]}"; do
    c1=${colors[$((idx % ${#colors[@]}))]}
    c2=${colors[$(((idx+1) % ${#colors[@]}))]}
    line="${text[$idx]}"
    for ((i=0; i<${#line}; i++)); do
      char="${line:$i:1}"
      if (( i % 2 == 0 )); then
        echo -ne "\e[${c1}m${char}\e[0m"
      else
        echo -ne "\e[${c2}m${char}\e[0m"
      fi
    done
    echo
  done
}

# Вариант 3: цвет меняется через один символ по циклу цветов
color_variant_3() {
  for line in "${text[@]}"; do
    for ((i=0; i<${#line}; i++)); do
      char="${line:$i:1}"
      c=${colors[$((i % ${#colors[@]}))]}
      echo -ne "\e[${c}m${char}\e[0m"
    done
    echo
  done
}

# Вариант 4: Градиент цвета слева направо (от 31 до 36)
color_variant_4() {
  local len=${#text[0]}
  for line in "${text[@]}"; do
    for ((i=0; i<len; i++)); do
      char="${line:$i:1}"
      c=$((31 + (i * 6 / len)))
      echo -ne "\e[${c}m${char}\e[0m"
    done
    echo
  done
}

# Вариант 5: Рандом с фиксированным сидом для повторяемости
color_variant_5() {
  RANDOM=42
  for line in "${text[@]}"; do
    for ((i=0; i<${#line}; i++)); do
      char="${line:$i:1}"
      c=$(rand_color)
      echo -ne "\e[${c}m${char}\e[0m"
    done
    echo
  done
}

# Теперь выводим 15 вариантов подряд, для примера возьмём 5 вариантов и повторим их три раза

for i in {1..3}; do
  echo -e "\n\e[1m=== Вариант $(( (i-1)*5 + 1 )) ===\e[0m"
  color_variant_1
  echo

  echo -e "\n\e[1m=== Вариант $(( (i-1)*5 + 2 )) ===\e[0m"
  color_variant_2
  echo

  echo -e "\n\e[1m=== Вариант $(( (i-1)*5 + 3 )) ===\e[0m"
  color_variant_3
  echo

  echo -e "\n\e[1m=== Вариант $(( (i-1)*5 + 4 )) ===\e[0m"
  color_variant_4
  echo

  echo -e "\n\e[1m=== Вариант $(( (i-1)*5 + 5 )) ===\e[0m"
  color_variant_5
  echo
done

#!/bin/bash

text=(
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

colors=(31 32 33 34 35 36 91 92 93 94 95 96)

rand_color() {
  echo ${colors[$RANDOM % ${#colors[@]}]}
}

color_variant_1() {
  for line in "${text[@]}"; do
    for ((i=0; i<${#line}; i++)); do
      char="${line:$i:1}"
      c=$(rand_color)
      echo -ne "\e[${c}m${char}\e[0m"
    done
    echo
  done
}

color_variant_2() {
  local c1 c2
  for idx in "${!text[@]}"; do
    c1=${colors[$((idx % ${#colors[@]}))]}
    c2=${colors[$(((idx+1) % ${#colors[@]}))]}
    line="${text[$idx]}"
    for ((i=0; i<${#line}; i++)); do
      char="${line:$i:1}"
      if (( i % 2 == 0 )); then
        echo -ne "\e[${c1}m${char}\e[0m"
      else
        echo -ne "\e[${c2}m${char}\e[0m"
      fi
    done
    echo
  done
}

color_variant_3() {
  for line in "${text[@]}"; do
    for ((i=0; i<${#line}; i++)); do
      char="${line:$i:1}"
      c=${colors[$((i % ${#colors[@]}))]}
      echo -ne "\e[${c}m${char}\e[0m"
    done
    echo
  done
}

color_variant_4() {
  local len=${#text[0]}
  for line in "${text[@]}"; do
    for ((i=0; i<len; i++)); do
      char="${line:$i:1}"
      c=$((31 + (i * 6 / len)))
      echo -ne "\e[${c}m${char}\e[0m"
    done
    echo
  done
}

color_variant_5() {
  RANDOM=42
  for line in "${text[@]}"; do
    for ((i=0; i<${#line}; i++)); do
      char="${line:$i:1}"
      c=$(rand_color)
      echo -ne "\e[${c}m${char}\e[0m"
    done
    echo
  done
}

color_variant_6() {
  # Паттерн: гласные красным, остальные синим
  vowels="аеёиоуыэюяAEЁИОУЫЭЮЯaeiouAEIOU"
  for line in "${text[@]}"; do
    for ((i=0; i<${#line}; i++)); do
      char="${line:$i:1}"
      if [[ "$vowels" == *"$char"* ]]; then
        echo -ne "\e[31m${char}\e[0m"
      else
        echo -ne "\e[34m${char}\e[0m"
      fi
    done
    echo
  done
}

color_variant_7() {
  # Чередование цвета по символам: даже — зелёный, нечет — жёлтый
  for line in "${text[@]}"; do
    for ((i=0; i<${#line}; i++)); do
      char="${line:$i:1}"
      if (( i % 2 == 0 )); then
        echo -ne "\e[32m${char}\e[0m"
      else
        echo -ne "\e[33m${char}\e[0m"
      fi
    done
    echo
  done
}

color_variant_8() {
  # Фон меняется: символы с белым фоном
  for line in "${text[@]}"; do
    for ((i=0; i<${#line}; i++)); do
      char="${line:$i:1}"
      c=$(rand_color)
      echo -ne "\e[${c};47m${char}\e[0m"
    done
    echo
  done
}

color_variant_9() {
  # Только заглавные буквы красным, остальные зелёным, пробелы без цвета
  for line in "${text[@]}"; do
    for ((i=0; i<${#line}; i++)); do
      char="${line:$i:1}"
      if [[ "$char" =~ [A-ZА-Я] ]]; then
        echo -ne "\e[31m${char}\e[0m"
      elif [[ "$char" == " " ]]; then
        echo -ne "${char}"
      else
        echo -ne "\e[32m${char}\e[0m"
      fi
    done
    echo
  done
}

color_variant_10() {
  # Моргающий текст (мигание)
  for line in "${text[@]}"; do
    for ((i=0; i<${#line}; i++)); do
      char="${line:$i:1}"
      c=$(rand_color)
      echo -ne "\e[${c};5m${char}\e[0m"
    done
    echo
  done
}

color_variant_11() {
  # Жирный и синий цвет
  for line in "${text[@]}"; do
    echo -e "\e[1;34m${line}\e[0m"
  done
}

color_variant_12() {
  # Градиент из красного в жёлтый по строкам (линейно)
  local lines=${#text[@]}
  for ((i=0; i<lines; i++)); do
    c=$((31 + i * 2))
    echo -e "\e[${c}m${text[i]}\e[0m"
  done
}

color_variant_13() {
  # Цвет фона и текста меняется на каждом символе
  for line in "${text[@]}"; do
    for ((i=0; i<${#line}; i++)); do
      char="${line:$i:1}"
      cfg=$((31 + i % 6))
      bkg=$((41 + i % 6))
      echo -ne "\e[${cfg};${bkg}m${char}\e[0m"
    done
    echo
  done
}

color_variant_14() {
  # Обратный цвет (инверсия)
  for line in "${text[@]}"; do
    echo -e "\e[7m${line}\e[0m"
  done
}

color_variant_15() {
  # Рандомные цвета с жирным шрифтом
  for line in "${text[@]}"; do
    for ((i=0; i<${#line}; i++)); do
      char="${line:$i:1}"
      c=$(rand_color)
      echo -ne "\e[1;${c}m${char}\e[0m"
    done
    echo
  done
}

# Выводим все 15 вариантов подряд
for i in {1..15}; do
  echo -e "\n\e[1m=== Вариант $i ===\e[0m"
  color_variant_$i
done
