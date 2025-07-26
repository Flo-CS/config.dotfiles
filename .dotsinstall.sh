#!/usr/bin/env bash

INSTALL_OPTIONS=(
	"1-bash"
	"1-terminal"
	"1-git"
	"2-hyprlandia"
	"3-audio"
	"3-bin"
	"3-bluetooth"
	"3-clipboard"
	"3-desktop"
	"3-disks"
	"3-docker"
	"3-files"
	"3-flatpak"
	"3-fonts"
	"3-grub"
	"3-manual"
	"3-multimedia"
	"3-neovim"
	"3-programming_languages"
	"3-sudoers"
	"3-system_backup"
	"3-system_controls"
	"3-system_monitoring"
	"3-xdg"
)

install() {
	local selected_install_options=$(gum filter --no-limit --header "What to install ?" "${INSTALL_OPTIONS[@]}" | sort -u)
	for option in $selected_install_options; do
		local fn=$(echo "$option" | cut -d"-" -f 2)
		"__install_${fn}"
	done
}

create_after_install_backup() {
	local do_backup=$(gum confirm "Do you want to create a system backup snapshot ?")
	if [[ $do_backup == "true" ]]; then
		local snapshot_description =$(gum input --placeholder "Snapshot description" --value "After system setup")
		sudo snapper -c root create --description $snapshot_description -u important=yes
	fi
}

__install_audio() {
	pacman_install sof-firmware
	pacman_install pipewire wireplumber pipewire-audio pipewire-pulse pipewire-jack
}

__install_bash() {
	symlink config/local/$DOTS_ID/.bashrc ~/.bashrc
	symlink config/local/$DOTS_ID/.bash_profile ~/.bash_profile
}

__install_bin() {
	symlink bin/wofi-emoji ~/.local/bin/wofi-emoji
}

__install_bluetooth() {
	sudo systemctl enable --now bluetooth.service
	yay_install bluetuith
}

__install_clipboard() {
	pacman_install wl-clipboard
}

__install_desktop() {
	# "Waybar"
	pacman_install waybar upower
	symlink config/default/waybar.jsonc ~/.config/waybar/config.jsonc
	symlink config/theme/current/waybar.css ~/.config/waybar/style.css

	# "QT Customization"
	pacman_install kvantum kvantum-qt5
	symlink config/default/kvantum.kvconfig ~/.config/Kvantum/kvantum.kvconfig
	symlink config/theme/current/kvantum ~/.config/Kvantum/current-theme

	# "Swaync"
	pacman_install swaync
	symlink config/default/swaync.json ~/.config/swaync/config.json
	symlink config/theme/current/swaync.css ~/.config/swaync/style.css

	# "Wofi"
	pacman_install wofi
	symlink config/default/wofi ~/.config/wofi/config
	symlink config/theme/current/wofi.css ~/.config/wofi/style.css

	# "Quickshell"
	pacman_install qt6-shadertools cli11
	if ! test -e ~/documents/quickshell; then
		git clone https://github.com/Flo-CS/quickshell.git ~/documents/quickshell
	else
		# TODO: Why sudo is required? How to install as user?
		cd ~/documents/quickshell &&
			git pull &&
			cmake -GNinja -B build -DCMAKE_BUILD_TYPE=ReleaseWithDebInfo -DCRASH_REPORTER=OFF &&
			cmake --build build &&
			sudo cmake --install build &&
			cd -
	fi

	# TODO: move it inside assets or other folder
	symlink config/default/quickshell ~/.config/quickshell

	# "GTK 3 Theming"

	# "GTK 4 Theming"

	# "GTK icons"

	# "Cursor icons"
	symlink config/theme/current/cursor-icons ~/.local/share/icons/cursor
}

__install_disks() {
	pacman_install gvfs udisks2
	pacman_install udiskie
	pacman_install dust
}

__install_docker() {
	pacman_install docker docker-compose
	yay_install lazydocker
	sudo systemctl enable --now docker.socket # Start on first usage, different from .service which start on boot
}

__install_files() {
	pacman_install bat
	symlink config/default/bat "$(bat --config-dir)/config"
	symlink config/theme/current/bat.tmTheme "$(bat --config-dir)/themes/current.tmTheme"
	bat cache --build

	pacman_install fzf
	symlink config/theme/current/fzf.sh ~/.local/bin/fzf/current-theme.sh

	pacman_install fd

	pacman_install ripgrep

	pacman_install zoxide

	pacman_install jq go-yq

	pacman_install thunar yazi ranger nnn

	pacman_install rclone syncthing rsync

	# FIXME:
	# pacman_install localsend
}

__install_flatpak() {
	pacman_install flatpak
	flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

__install_fonts() {
	pacman_install ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols

	# FIXME:
	# cargo install --git https://github.com/loichyan/nerdfix.git
}

# Function from git.sh
__install_git() {
	pacman_install git git-filter-repo lazygit git-delta
	yay_install git-credential-oauth
	symlink config/local/$DOTS_ID/.gitconfig ~/.gitconfig
}

__install_grub() {
	# os-prober is disabled by default in grub config and it's better for security reasons. But it is useful to detect other OSes and then add them manually to grub.
	windows_boot_partition_path=$(sudo os-prober | grep "Windows Boot Manager" | head -n 1 | cut -d'@' -f1 || echo "")
	if [[ -n $windows_boot_partition_path ]]; then
		log_info "detected Windows Boot Manager at: $windows_boot_partition_path"
		windows_boot_partition_uuid=$(sudo blkid -s UUID -o value "$windows_boot_partition_path" 2>/dev/null)
		if [[ -z $windows_boot_partition_uuid ]]; then
			windows_boot_partition_uuid=$(lsblk -no UUID "$windows_boot_partition_path" 2>/dev/null)
			if [[ -z $windows_boot_partition_uuid ]]; then
				log_error "unable to retrieve UUID for Windows Boot Manager partition."
				exit 1
			fi
		fi

		log_info "Windows Boot Manager UUID: $windows_boot_partition_uuid"
		sudo -E ./.dotsenv.sh insert_with_marker /etc/grub.d/40_custom "windows" "
menuentry 'Windows Boot Manager' --class windows --class os {
    search --fs-uuid --no-floppy --set=root $windows_boot_partition_uuid
    chainloader /EFI/Microsoft/Boot/bootmgfw.efi
}
"
	else
		log_warn "no Windows Boot Manager found. Skipping Windows entry in GRUB."
	fi

	grep -q '^GRUB_DEFAULT=' /etc/default/grub && sudo sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' /etc/default/grub
}

__install_hyprlandia() {
	pacman_install hyprland hyprpaper hyprcursor hyprlock hypridle hyprland-qtutils hyprland-qt-support hyprpolkitagent
	pacman_install xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
	pacman_install qt6-wayland qt5-wayland
	symlink config/local/$DOTS_ID/hypr/hyprland.conf ~/.config/hypr/hyprland.conf
	symlink config/local/$DOTS_ID/hypr/hyprlock.conf ~/.config/hypr/hyprlock.conf
	symlink config/default/hypr/hypridle.conf ~/.config/hypr/hypridle.conf
	symlink config/default/hypr/hyprpaper.conf ~/.config/hypr/hyprpaper.conf
	hyprctl reload || log_warn "hyprctl reload failed, maybe hyprland is not running yet"

	pacman_install cmake meson cpio git gcc
	hyprpm add --force https://github.com/hyprwm/hyprland-plugins $DOTS_HYPRLAND_PLUGINS_VERSION || log_warn "hyprpm add failed"
	hyprpm update || log_warn "hyprpm update failed"
	hyprpm enable hyprexpo || log_warn "hyprpm enable hyprexpo failed"

	pacman_install uwsm libnewt
}

__install_manual() {
	pacman_install man-pages tldr
}

__install_multimedia() {
	pacman_install playerctl
}

__install_neovim() {
	pacman_install neovim
	symlink config/default/nvim ~/.config/nvim
	symlink config/theme/current/nvim.theme ~/.config/nvim/.theme
}

__install_programming_languages() {
	pacman_install python-j2cli

	pacman_install python-pip

	pacman_install nvm
	source ~/.bashrc
	nvm install --lts || log_error "nvm install failed, maybe nvm is not properly configured"

	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
}

__install_sudoers() {
	sudo -E ./.dotsenv.sh copy config/default/sudoers /etc/sudoers.d/sudoers-default
}

__install_system_backup() {
	pacman_install snapper snap-pac inotify-tools grub-btrfs

	# WARNING: The boot on snapshot part (managed by grub-btrfs) will only work with EndeavourOS because it uses dracut.
	# For raw ArchLinux systems, see grub-btrfs docs for more information and the alternative way to boot on snapshot.

	sudo snapper -c root create-config / || log_error "Failed to create snapper config, maybe root config already exists"

	sudo -E ./.dotsenv.sh backup /etc/snapper/configs/root

	sudo snapper -c root set-config ALLOW_USERS="$USER"
	sudo snapper -c root set-config TIMELINE_LIMIT_HOURLY="10"
	sudo snapper -c root set-config TIMELINE_LIMIT_DAILY="5"
	sudo snapper -c root set-config TIMELINE_LIMIT_WEEKLY="3"
	sudo snapper -c root set-config TIMELINE_LIMIT_MONTHLY="0"
	sudo snapper -c root set-config TIMELINE_LIMIT_YEARLY="0"

	sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer

	# WARNING: only work on EndeavourOS because it uses dracut
	sudo -E ./.dotsenv.sh backup /etc/default/grub-btrfs/config
	sudo -E ./.dotsenv.sh insert_with_marker /etc/default/grub-btrfs/config "custom" "GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS=\"rd.live.overlay.overlayfs=1\""

	sudo systemctl enable --now grub-btrfsd
}

__install_system_controls() {
	pacman_install brightnessctl power-profiles-daemon
}

__install_system_monitoring() {
	pacman_install fastfetch

	pacman_install btop
	symlink config/default/btop.conf ~/.config/btop/btop.conf
	symlink config/theme/current/btop.theme ~/.config/btop/current.theme
}

__install_terminal() {
	pacman_install glow gum

	curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

	pacman_install alacritty
	pacman_uninstall xterm || log_warn "xterm is already uninstalled, skipping"
	symlink config/default/alacritty.toml ~/.config/alacritty/alacritty.toml
	symlink config/theme/current/alacritty.toml ~/.config/alacritty/current-theme.toml
	sudo ln -sf /usr/bin/alacritty /usr/bin/xterm # Stupid workaround to allow to run .desktop files that require by default xterm (i don't know how to change it)

	pacman_install starship
	template config/default/starship.toml.j2
	symlink config/default/starship.toml ~/.config/starship.toml
}

__install_xdg() {
	symlink config/default/user-dirs.dirs ~/.config/user-dirs.dirs
}

install
create_after_install_backup
