#!/usr/bin/env bash

if [[ -z "$DOTS_DIR" ]]; then
	export DOTS_DIR=$(gum input --placeholder "Enter the path to your dotfiles directory" --value "$HOME/.dotfiles")
fi

if [[ -z "$DOTS_ID" ]]; then
	export DOTS_ID=$(gum input --placeholder "Enter your dots ID for machine specific files (e.g.: jean.desktop)" --value "$(basename "$DOTS_DIR")")
fi

source "$DOTS_DIR/.dotsutils.sh"
"$@"
