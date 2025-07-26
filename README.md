# README

## ISO, USB, and Installation

Use Ventoy to create a bootable USB drive allowing to boot multiple ISO files from the same USB drive.

Note that the USB drive can still be used to store files other tha ISO files. Most commonly files to set up the system after installation.
They should be placed in a directory with a file named .ventoyignore.

## EndeavourOS

1) Install EndeavourOS
    - Connect to internet with nmtui
    - Use the installer
      - Select correct partitioning settings
      - Select no desktop environment
      - Select grub bootloader
      - Choose btfrs partition type
2) Install nvidia drivers with the EndeavourOS nvidia-installer: `nvidia-inst --closed` (IF NECESSARY)
3) Fetch dotfiles
4) Run `dots.sh`
