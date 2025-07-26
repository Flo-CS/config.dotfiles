#!/usr/bin/env bash

WALLPAPERS_PATH="$DOTS_DIR/assets/wallpapers"

set_wallpaper() {
	ln -sfT $WALLPAPERS_PATH/$1 $WALLPAPERS_PATH/current
}

list_wallpapers() {
	find "$WALLPAPERS_PATH" -mindepth 1 -maxdepth 1 -type f ! -lname '*' -printf '%f\n'
}

select_wallpaper() {
	gum choose --header "Select a wallpaper" $(list_wallpapers)
}

set_wallpaper $(select_wallpaper)
