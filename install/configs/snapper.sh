#!/usr/bin/env bash

source $DOTFILES_UTILS

# WARNING: The boot on snapshot part (managed by grub-btrfs) will only work with EndeavourOS because it uses dracut.
# For raw ArchLinux systems, see grub-btrfs docs for more information and the alternative way to boot on snapshot.

section "Snapper Config"
sudo snapper -c root create-config /

with_sudo create_backup /etc/snapper/configs/root

sudo snapper -c root set-config ALLOW_USERS="$USER"
sudo snapper -c root set-config TIMELINE_LIMIT_HOURLY="10"
sudo snapper -c root set-config TIMELINE_LIMIT_DAILY="5"
sudo snapper -c root set-config TIMELINE_LIMIT_WEEKLY="3"
sudo snapper -c root set-config TIMELINE_LIMIT_MONTHLY="0"
sudo snapper -c root set-config TIMELINE_LIMIT_YEARLY="0"

sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer

# WARNING: only work on EndeavourOS because it uses dracut
section "Grub-Btrfs Config"
with_sudo create_backup /etc/default/grub-btrfs/config
with_sudo insert_content_with_marker /etc/default/grub-btrfs/config "custom" "GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS=\"rd.live.overlay.overlayfs=1\""

sudo systemctl enable --now grub-btrfsd
