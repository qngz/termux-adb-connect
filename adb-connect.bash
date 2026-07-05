#!/bin/bash

check_interface() {
    interface_type="$1"

    if ! ifconfig 2>/dev/null | grep -q $interface_type; then
        echo -ne "\033[2K\rинтерфейс $interface_type не включён. вернутся к меню?"
        read -n 1 -s
        return 1
    fi
    return 0
}

select_option() {
    opts=("localhost" "10.105.42.0/24" "192.168.0.0/24" "info")
    opts_len=${#opts[@]}
    cur=0

    echo "Выберите вариант (влево, вправо):"

    while true; do
        echo -ne "\r"
        for i in "${!opts[@]}"; do
            if [ $i -eq $cur ]; then
                echo -ne "\e[93m[${opts[i]}]\e[0m"
            else
                echo -ne " ${opts[i]} "
            fi
        done

        read -sn 1 key
        case $key in
            D) # лево
                cur=$(( (cur + opts_len - 1) % opts_len ));;
            C) # право
                cur=$(( (cur + 1) % opts_len ));;
            "") # Enter
                case $cur in
                    0)
                        if check_interface wlan0; then
                            connect_local_adb
                            return 0
                        fi
                        continue;;
                    1)
                        if check_interface ap0; then
                            connect_network_adb "10.105.42."
                            return 0
                        fi
                        continue;;
                    2)
                        if check_interface wlan0; then
                            connect_network_adb "192.168.0."
                            return 0
                        fi
                        continue;;
                    3)
                        echo -e "\n"
                        ifconfig 2> /dev/null
                        adb devices
                        read -n 1 -s -p "вернутся к меню?"
                        continue;;
                esac
        esac
    done
}

connect_network_adb() {
    echo
    ip_prefix="$1"
    read -p "adb pair " -e -i "$ip_prefix" paring_addres
    adb pair "$paring_addres"

    connection_ip="${paring_addres%:*}"

    read -p "adb connect $connection_ip:" connection_port
    adb connect "$connection_ip:$connection_port"
}

connect_local_adb() {
    am start -n com.android.settings/.SubSettings \
      -e :android:show_fragment \
      "com.android.settings.development.WirelessDebuggingFragment" > /dev/null

    old_text=$(termux-clipboard-get)

    while true; do
        new_text=$(termux-clipboard-get 2> /dev/null)
        if [ "$new_text" != "$old_text" ]; then
            if [[ "$new_text" =~ ^[0-9.]+:[0-9]+$ ]]; then
                port="${new_text#*:}"
                echo
                adb connect "127.0.0.1:$port"
                return 0
            fi
        fi
    done
}

select_option
