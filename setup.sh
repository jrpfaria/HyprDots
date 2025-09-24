#!/bin/bash

INSTLOG="install.log"
CNT="[\e[1;36mINFO\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

PACKAGES=(
    "linux-headers"
    "linux-firmware"
    "git"
    "qt5-wayland"
    "qt6-wayland"
    "qt5ct"
    "kitty"
    "jq"
    "python-requests"

# Audio
    "pipewire"
    "lib32-pipewire"
    "pipewire-audio"
    "pipewire-docs"
    "pipewire-alsa"
    "pipewire-pulse"
    "wireplumber"
    "qpwgraph"
    "pamixer"
    "pwvucontrol"
    "easyeffects"
    "lsp-plugins-lv2"
    "pipewire-jack"
    "lib32-pipewire-jack"
    "wiremix"

# HyprLand
    "eww"
    "mako"
    "swww"
    "sway"
    "swaylock-effects"
    "swayidle"
    "vicinae-bin"
    "swappy"
    "grim"
    "slurp"
    "yazi"
    "polkit-kde-agent"
    "hyprland"
    "xdg-desktop-portal-hyprland"
    "hyprshell"

#Networking
    "network-manager-applet"
    "networkmanager-openvpn"
    "openssh"
    "zerotier-one"

# Fonts
    "ttf-jetbrains-mono-nerd"
    "ttf-bitstream-vera"
    "ttf-dejavu"
    "ttf-opensans"
    "noto-fonts-emoji"
    "noto-fonts-cjk"
    "noto-fonts-extra"

# Boot
    "grub"
    "os-prober"
    "efibootmgr"

# AMD Stuff
    "amd-ucode"
    "amdgpu_top"
    "corectrl"

# Certificates
    "ca-certificates"
    "ca-certificates-mozilla"
    "ca-certificates-utils"

# Graphic Drivers
    "mesa"
    "lib32-mesa"
    "vulkan-radeon"
    "lib32-vulkan-radeon"
    "xf86-video-amdgpu"
    "libva-mesa-driver"
    "lib32-libva-mesa-driver"
    "libva"

# Waydroid
    "waydroid"
    "python-gbinder"
    "python-pyclip"

# Misc packages
    "lxappearance"
    "xfce4-settings"
    "sddm-git"
    "tree"
    "qt5-svg"
    "qt5-quickcontrols2"
    "qt5-graphicaleffects"
    "qbittorrent"
    "firefox"
    "chromium"
    "visual-studio-code-bin"
    "fastfetch"
    "cifs-utils"
    "wget"
    "zsh"
    "nano"
    "vault"
    "man-db"
    "man-pages"
    "gvfs"
    "file-roller"
    "btop"
    "pacman-contrib"
    "obs-studio"
    "wine-staging"
    "openrazer-driver-dkms"
    "steam-native-runtime"
    "discord"
    "mangohud"
    "goverlay"
    "gamemode"
    "lib32-gamemode"
    "gamescope"
    "zenpower3-dkms"
    "unzip"
    "unrar"
    "winetricks"
    "protontricks"
    "fuse2"
    "ntfs-3g"
    "spotify-adblock"
    "wl-clipboard"
    "flameshot-git"
    "jdk21-openjdk"
    "opentabletdriver-git"
    "lutris"
)

clear

#### Check for package manager ####
echo -e "$CNT - Installing yay..."
ISYAY=/sbin/yay
if [ -f "$ISYAY" ]; then
    echo -e "$COK - Found yay"
else
    git clone https://aur.archlinux.org/yay.git &>> $INSTLOG
    cd yay
    makepkg -si --noconfirm &>> ../$INSTLOG
    cd ..
    # update the yay database
    echo -e "$CNT - Updating the yay database..."
    yay -Suy --noconfirm &>> $INSTLOG
fi


# function that will test for a package and if not found it will attempt to install it
install() {
    # First lets see if the package is there
    if yay -Q $1 &>> /dev/null ; then
        echo -e "$COK - $1 is already installed."
    else
        # no package found so installing
        echo -e "$CNT - Now installing $1 ..."
        yay -S --needed --noconfirm $1 &>> $INSTLOG
        # test to make sure package installed
        if yay -Q $1 &>> /dev/null ; then
            echo -e "\e[1A\e[K$COK - $1 was installed."
        else
            # if this is hit then a package is missing, exit to review log
            echo -e "\e[1A\e[K$CER - $1 install failed, please check the install.log"
            exit
        fi
    fi
}

# Install all the above packages
for PKG in ${PACKAGES[@]};
do
    install $PKG
done

# Start network services
echo -e "$CNT - Starting the Network Services..."
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now zerotier-one.service

# Enable the sddm login manager service
echo -e "$CNT - Enabling the SDDM Service..."
sudo systemctl enable sddm &>> $INSTLOG
sleep 2

# Clean out other portals
echo -e "$CNT - Cleaning out conflicting xdg portals..."
yay -R --noconfirm xdg-desktop-portal-gnome xdg-desktop-portal-gtk &>> $INSTLOG


# Copy the SDDM theme
echo -e "$CNT - Setting up the login screen."
sudo mkdir -p /usr/share/sddm/themes
sudo cp -R $PWD/Tools/sdt /usr/share/sddm/themes/
sudo chown -R $USER:$USER /usr/share/sddm/themes/sdt
sudo mkdir -p /etc/sddm.conf.d
echo -e "[Theme]\nCurrent=sdt" | sudo tee -a /etc/sddm.conf.d/10-theme.conf &>> $INSTLOG
cp $PWD/Dotfiles/wallpapers/sddm-background.png /usr/share/sddm/themes/sdt/wallpaper.png
WLDIR=/usr/share/wayland-sessions
if [ -d "$WLDIR" ]; then
    echo -e "$COK - $WLDIR found"
else
    echo -e "$CWR - $WLDIR NOT found, creating..."
    sudo mkdir $WLDIR
fi

# Install GRUB theme
echo -e "$CNT - Installing and configuration GRUB Virtuaverse Theme..."
sudo $PWD/Dotfiles/grub/install_script_grub.sh &>> $INSTLOG

# stage the .desktop file
sudo cp $PWD/Tools/hyprland.desktop /usr/share/wayland-sessions/
sudo sed -i 's/Exec=Hyprland/Exec=\/home\/'$USER'\/.start-hypr/' /usr/share/wayland-sessions/hyprland.desktop

# Install and configure oh my zsh / theme / plugins
if [ ! -d "~/.oh-my-zsh" ]
then
    echo -e "$CNT - Installing and configuration Oh-My-Zsh..."
    RUNZSH=no #Stop the omz installer from starting zsh during installation
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/themes/powerlevel10k
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting
    sudo chsh -s $(which zsh) $(whoami)
else
    echo -e "$CNT - Oh-My-Zsh already installed..."
fi

# # Create the config directories
echo -e "$COK - Creating Config Directories..."
CONFIG_DIRECTORIES=( "dconf" "end-rs" "eww" "gtk-3.0" "hypr" "kitty" "fastfetch" "qt5ct" "swaylock" "Thunar" "xfce4" "Code/User" "wallpapers" "mako/icons" "btop/themes")
for DIR in ${CONFIG_DIRECTORIES[@]};
do
    mkdir -p ~/.config/$DIR
done

# These config directories are not in the .config directory
ROOT_DIRECTORIES=(".themes" ".scripts")
for DIR in ${ROOT_DIRECTORIES[@]};
do
    mkdir -p ~/$DIR
done

# Link the configs
echo -e "$COK - Linking configurations..."
ln -sf $PWD/Dotfiles/kitty/kitty.conf ~/.config/kitty/kitty.conf
ln -sf $PWD/Dotfiles/kitty/curr_theme.conf ~/.config/kitty/curr_theme.conf
ln -sf $PWD/Dotfiles/mako/conf/config-dark ~/.config/mako/config
cp -r $PWD/Dotfiles/mako/icons/* ~/.config/mako/icons/
ln -sf $PWD/Dotfiles/swaylock/config ~/.config/swaylock/config
ln -sf $PWD/Dotfiles/waybar/conf/config.jsonc ~/.config/waybar/config.jsonc
ln -sf $PWD/Dotfiles/waybar/style/style.css ~/.config/waybar/style.css
ln -sf $PWD/Dotfiles/wofi/config ~/.config/wofi/config
ln -sf $PWD/Dotfiles/wofi/style/style.css ~/.config/wofi/style.css_
ln -sf $PWD/Themes/GTK/Tokyo-Night/Tokyonight-Storm-BL-LB  ~/.themes/Tokyonight-Storm-BL-LB
ln -sf $PWD/Themes/GTK/Graphite-Dark  ~/.themes/Graphite-Dark
ln -sf $PWD/Dotfiles/gtk-3.0/settings.ini ~/.config/gtk-3.0/settings.ini && gsettings set org.gnome.desktop.interface gtk-theme "Tokyonight-Storm-BL-LB" && gsettings set org.gnome.desktop.wm.preferences theme "Tokyonight-Storm-BL-LB"
ln -sf $PWD/Dotfiles/hypr/hyprland.conf ~/.config/hypr/hyprland.conf
ln -sf $PWD/Dotfiles/zsh/.zshrc ~/.zshrc
ln -sf $PWD/Dotfiles/zsh/.p10k.zsh ~/.p10k.zsh
ln -sf $PWD/Dotfiles/scripts/aliases ~/.scripts/aliases
ln -sf $PWD/Dotfiles/scripts/swww ~/.scripts/swww
ln -sf $PWD/Dotfiles/scripts/updater ~/.scripts/updater
ln -sf $PWD/Dotfiles/scripts/mediaplayer.py ~/.scripts/mediaplayer.py
ln -sf $PWD/Dotfiles/fastfetch/config.jsonc ~/.config/fastfetch/config.jsonc
ln -sf $PWD/Assets/ASCII/cat.txt ~/.config/fastfetch/cat.txt
ln -sf $PWD/Assets/ASCII/dog.txt ~/.config/fastfetch/dog.txt
ln -sf $PWD/Assets/ASCII/punpun.txt ~/.config/fastfetch/punpun.txt
ln -sf $PWD/Assets/ASCII/mac.txt ~/.config/fastfetch/mac.txt
ln -sf $PWD/Dotfiles/rtorrent.rc ~/.rtorrent.rc
ln -sf $PWD/Dotfiles/Thunar/accels.scm ~/.config/Thunar/accels.scm
ln -sf $PWD/Dotfiles/Thunar/ucl.xml ~/.config/Thunar/ucl.xml
ln -sf $PWD/Dotfiles/vscode/settings.json ~/.config/Code/User/settings.json
ln -sf $PWD/Dotfiles/wallpapers/desktop-background.png ~/.config/wallpapers/desktop-background.png
ln -sf $PWD/Dotfiles/btop/btop.conf ~/.config/btop/btop.conf
ln -sf $PWD/Themes/btop/tokyo-storm.theme ~/.config/btop/themes/tokyo-storm.theme
ln -sf $PWD/Dotfiles/end-rs/config.toml ~/.config/end-rs/config.toml
ln -sf $PWD/Dotfiles/eww ~/.config/eww


echo -e "$COK - Installation Complete, Rebooting to Hyprland..."
sudo reboot 0
