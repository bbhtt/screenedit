#!/usr/bin/env sh

# License: GNU General Public License v3.0

# Dependencies:

# awk: https://www.gnu.org/s/gawk/manual/gawk.html
# gnome-screenshot: https://gitlab.gnome.org/GNOME/gnome-screenshot
# satty: https://github.com/gabm/Satty
# wl-copy: https://github.com/bugaevc/wl-clipboard
# notify-send: https://gitlab.gnome.org/GNOME/libnotify
# dbus-send: https://gitlab.freedesktop.org/dbus/dbus
# Filemanager implementing org.freedesktop.FileManager1
# Adwaita icon theme https://gitlab.gnome.org/GNOME/adwaita-icon-theme

set -e

help() {
    printf "Usage: screenedit [OPTION]
    Options:
    -f          Full Screenshot
    -a          Area Selection
    -w          Current Window
    -i          Interactive
    -h          Help\n"
    exit "$1"
}

flag=""
interactive=false

if ! ARGS=$(getopt -o fawih --long help -- "$@"); then
    help 1
fi

eval set -- "$ARGS"
while [ $# -gt 0 ]
do
    case "$1" in
    "-f")
                        flag=""
                        ;;
    "-a")
                        flag="-a"
                        ;;
    "-w")
                        flag="-w"
                        ;;
    "-i")
                        flag="-i"
                        interactive=true
                        ;;
    "-h" | "--help")
                        help 0
                        ;;
    "--")
        shift
        break
        ;;
    esac
    shift
done

checkcmd() {
    if ! command -v "$1" > /dev/null 2>&1; then
        echo "$1 not found"
        notify-send -i applets-screenshooter-symbolic -t 100 -a Screenedit -u critical "Screenshot cancelled" "$1 not found"
        exit 1
    fi
}

checkcmd "satty"
checkcmd "awk"
checkcmd "gnome-screenshot"
checkcmd "wl-copy"
checkcmd "notify-send"
checkcmd "dbus-send"

folder="${XDG_PICTURES_DIR:-$HOME/Pictures/Screenshots}"

if [ ! -d "$folder" ]; then
    mkdir -p "$HOME"/Pictures/Screenshots
fi

name="$(awk 'BEGIN {srand();printf "%d\n", (rand() * 10^8);}').png"
scpath="$folder/$name"
sattypath="$folder/modified_$name"

if [ "$interactive" = false ]; then
    gnome-screenshot "$flag" -f "$scpath"
else
    gnome-screenshot "$flag"
fi

if [ "$interactive" = false ] && [ ! -f "$scpath" ]; then
    echo "Screenshot cancelled"
    notify-send -i applets-screenshooter-symbolic -t 100 -a Screenedit -u critical "Screenshot cancelled" "The screenshot was cancelled by the user"
    exit 1
fi

if [ "$interactive" = false ]; then
    satty --filename "$scpath" --initial-tool brush --copy-command wl-copy --early-exit --save-after-copy --disable-notifications --output-filename "$sattypath"
    echo "Screenshot saved to $sattypath"

    if [ -f "$scpath" ] && [ -f "$sattypath" ]; then
        echo "Deleting original screenshot $scpath"
        rm "$scpath"
    fi

    if [ -f "$sattypath" ]; then
        notify-send -i applets-screenshooter-symbolic -t 100 -a Screenedit -u normal "Screenshot saved" "$sattypath"
    elif [ -f "$scpath" ]; then
        notify-send -i applets-screenshooter-symbolic -t 100 -a Screenedit -u normal "Screenshot saved" "$scpath"
    else 
        notify-send -i applets-screenshooter-symbolic -t 100 -a Screenedit -u normal "Screenshot saved" "$folder"
    fi

    if ! dbus-send --session --print-reply --dest=org.freedesktop.FileManager1 --type=method_call /org/freedesktop/FileManager1 org.freedesktop.DBus.Peer.Ping > /dev/null; then
        echo "org.freedesktop.FileManager1 interface is unavailable. Opening the file in filemanager will not work"
        exit 1
    fi 

    if [ -f "$scpath" ]; then
        dbus-send --session --dest=org.freedesktop.FileManager1 --type=method_call /org/freedesktop/FileManager1 org.freedesktop.FileManager1.ShowItems array:string:"file://$scpath" string:""
    elif [ -f "$sattypath" ]; then
        dbus-send --session --dest=org.freedesktop.FileManager1 --type=method_call /org/freedesktop/FileManager1 org.freedesktop.FileManager1.ShowItems array:string:"file://$sattypath" string:""
    else 
        dbus-send --session --dest=org.freedesktop.FileManager1 --type=method_call /org/freedesktop/FileManager1 org.freedesktop.FileManager1.ShowItems array:string:"file://$folder" string:""
    fi

fi
