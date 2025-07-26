#!/usr/bin/env bash

set -euo pipefail # Exit on error, undefined variable, or failed command in a pipeline

. ./.dotsenv.sh

OPTIONS=("install" "set theme" "set wallpaper")

selected_option=$(gum choose --header "What to do ?" "${OPTIONS[@]}")
case "$selected_option" in
"install")
	. ./.dotsinstall.sh
	;;
"set theme")
	. ./.dotstheme.sh
	;;
"set wallpaper")
	. ./.dotswallpaper.sh
	;;
esac
