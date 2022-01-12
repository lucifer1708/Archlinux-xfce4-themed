#!/bin/bash
# ----------------------------------------
# Define Variables
# ----------------------------------------

LCLST="en_US"
# Format is language_COUNTRY where language is lower case two letter code
# and country is upper case two letter code, separated with an underscore

KEYMP="us"
# Use lower case two letter country code

KEYMOD="pc105"
# pc105 and pc104 are modern standards, all others need to be researched

MYUSERNM="live"
# use all lowercase letters only

MYHOSTNM="arch"
# Pick a hostname for the machine

# ----------------------------------------
# Functions
# ----------------------------------------

# Test for root user
rootuser () {
  if [[ "$EUID" = 0 ]]; then
    continue
  else
    echo "Please Run As Root"
    sleep 2
    exit
  fi
}

# Display line error
handlerror () {
clear
set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
}

# Clean up working directories
cleanup () {
[[ -d ./archreleng ]] && rm -r ./archreleng
[[ -d ./work ]] && rm -r ./work
[[ -d ./out ]] && mv ./out ../
sleep 2
}

# Requirements and preparation
prepreqs () {
pacman -S --noconfirm archlinux-keyring
pacman -S --needed --noconfirm archiso mkinitcpio-archiso
}

# Copy archreleng to working directory
cparchreleng () {
cp -r /usr/share/archiso/configs/releng/ ./archreleng
rm -r ./archreleng/efiboot
rm -r ./archreleng/syslinux
}

# Copy arch to opt
cparch () {
cp -r ./opt/arch /opt/
}

# Remove arch from opt
rmarch () {
rm -r /opt/arch
}

# Delete automatic login
nalogin () {
[[ -d ./archreleng/airootfs/etc/systemd/system/getty@tty1.service.d ]] && rm -r ./archreleng/airootfs/etc/systemd/system/getty@tty1.service.d
}

# Remove cloud-init and other stuff
rmunitsd () {
[[ -d ./archreleng/airootfs/etc/systemd/system/cloud-init.target.wants ]] && rm -r ./archreleng/airootfs/etc/systemd/system/cloud-init.target.wants
[[ -f ./archreleng/airootfs/etc/systemd/system/multi-user.target.wants/iwd.service ]] && rm ./archreleng/airootfs/etc/systemd/system/multi-user.target.wants/iwd.service
[[ -f ./archreleng/airootfs/etc/xdg/reflector/reflector.conf ]] && rm ./archreleng/airootfs/etc/xdg/reflector/reflector.conf
}

# Add NetworkManager, lightdm, cups, & haveged systemd links
addnmlinks () {
[[ ! -d ./archreleng/airootfs/etc/systemd/system/sysinit.target.wants ]] && mkdir -p ./archreleng/airootfs/etc/systemd/system/sysinit.target.wants
[[ ! -d ./archreleng/airootfs/etc/systemd/system/network-online.target.wants ]] && mkdir -p ./archreleng/airootfs/etc/systemd/system/network-online.target.wants
[[ ! -d ./archreleng/airootfs/etc/systemd/system/multi-user.target.wants ]] && mkdir -p ./archreleng/airootfs/etc/systemd/system/multi-user.target.wants
[[ ! -d ./archreleng/airootfs/etc/systemd/system/printer.target.wants ]] && mkdir -p ./archreleng/airootfs/etc/systemd/system/printer.target.wants
[[ ! -d ./archreleng/airootfs/etc/systemd/system/sockets.target.wants ]] && mkdir -p ./archreleng/airootfs/etc/systemd/system/sockets.target.wants
[[ ! -d ./archreleng/airootfs/etc/systemd/system/timers.target.wants ]] && mkdir -p ./archreleng/airootfs/etc/systemd/system/timers.target.wants
ln -sf /usr/lib/systemd/system/NetworkManager-wait-online.service ./archreleng/airootfs/etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service
ln -sf /usr/lib/systemd/system/NetworkManager.service ./archreleng/airootfs/etc/systemd/system/multi-user.target.wants/NetworkManager.service
ln -sf /usr/lib/systemd/system/NetworkManager-dispatcher.service ./archreleng/airootfs/etc/systemd/system/dbus-org.freedesktop.nm-dispatcher.service
ln -sf /usr/lib/systemd/system/lightdm.service ./archreleng/airootfs/etc/systemd/system/display-manager.service
ln -sf /usr/lib/systemd/system/haveged.service ./archreleng/airootfs/etc/systemd/system/sysinit.target.wants/haveged.service
ln -sf /usr/lib/systemd/system/cups.service ./archreleng/airootfs/etc/systemd/system/printer.target.wants/cups.service
ln -sf /usr/lib/systemd/system/cups.socket ./archreleng/airootfs/etc/systemd/system/sockets.target.wants/cups.socket
ln -sf /usr/lib/systemd/system/cups.path ./archreleng/airootfs/etc/systemd/system/multi-user.target.wants/cups.path
ln -sf /usr/lib/systemd/system/plocate-updatedb.timer ./archreleng/airootfs/etc/systemd/system/timers.target.wants/plocate-updatedb.timer
}

# Copy files to customize the ISO
cpmyfiles () {
sudo chmod +x /etc/skel/.config/awesome/configuration/rofi/global/rofi-spotlight.sh
cp packages.x86_64 ./archreleng/
cp pacman.conf ./archreleng/
cp profiledef.sh ./archreleng/
cp -r efiboot ./archreleng/
cp -r syslinux ./archreleng/
cp -r usr ./archreleng/airootfs/
cp -r etc ./archreleng/airootfs/
cp -r opt ./archreleng/airootfs/
}

# Set hostname
sethostname () {
echo "${MYHOSTNM}" > ./archreleng/airootfs/etc/hostname
}

# Create passwd file
crtpasswd () {
echo "root:x:0:0:root:/root:/usr/bin/bash
"${MYUSERNM}":x:1010:1010::/home/"${MYUSERNM}":/bin/bash" > ./archreleng/airootfs/etc/passwd
}

# Create group file
crtgroup () {
echo "root:x:0:root
sys:x:3:"${MYUSERNM}"
adm:x:4:"${MYUSERNM}"
wheel:x:10:"${MYUSERNM}"
log:x:19:"${MYUSERNM}"
network:x:90:"${MYUSERNM}"
floppy:x:94:"${MYUSERNM}"
scanner:x:96:"${MYUSERNM}"
power:x:98:"${MYUSERNM}"
rfkill:x:850:"${MYUSERNM}"
users:x:985:"${MYUSERNM}"
storage:x:870:"${MYUSERNM}"
optical:x:880:"${MYUSERNM}"
lp:x:840:"${MYUSERNM}"
audio:x:890:"${MYUSERNM}"
autologin:x:1001:"${MYUSERNM}"
"${MYUSERNM}":x:1010:" > ./archreleng/airootfs/etc/group
}

# Create shadow file
crtshadow () {
usr_hash=$(openssl passwd -6 "${MYUSRPASSWD}")
root_hash=$(openssl passwd -6 "${RTPASSWD}")
echo "root:"${root_hash}":14871::::::
"${MYUSERNM}":"${usr_hash}":14871::::::" > ./archreleng/airootfs/etc/shadow
}

# create gshadow file
crtgshadow () {
echo "root:!*::root
"${MYUSERNM}":!*::" > ./archreleng/airootfs/etc/gshadow
}

# Set the keyboard layout
setkeylayout () {
echo "KEYMAP="${KEYMP}"" > ./archreleng/airootfs/etc/vconsole.conf
}

# Create 00-keyboard.conf file
crtkeyboard () {
mkdir -p ./archreleng/airootfs/etc/X11/xorg.conf.d
echo "Section \"InputClass\"
        Identifier \"system-keyboard\"
        MatchIsKeyboard \"on\"
        Option \"XkbLayout\" \""${KEYMP}"\"
        Option \"XkbModel\" \""${KEYMOD}"\"
EndSection" > ./archreleng/airootfs/etc/X11/xorg.conf.d/00-keyboard.conf
}

# Fix 40-locale-gen.hook and create locale.conf
crtlocalec () {
sed -i "s/en_US/"${LCLST}"/g" ./archreleng/airootfs/etc/pacman.d/hooks/40-locale-gen.hook
echo "LANG="${LCLST}".UTF-8" > ./archreleng/airootfs/etc/locale.conf
}

# Start mkarchiso
runmkarchiso () {
mkarchiso -v -w ./work -o ./out ./archreleng
}

# ----------------------------------------
# Run Functions
# ----------------------------------------

rootuser
handlerror
prepreqs
cleanup
cparchreleng
addnmlinks
cparch
nalogin
rmunitsd
cpmyfiles
sethostname
crtpasswd
crtgroup
crtshadow
crtgshadow
setkeylayout
crtkeyboard
crtlocalec
runmkarchiso
rmarch


