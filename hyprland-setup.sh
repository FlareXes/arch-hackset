#!/usr/bin/env bash

# Version: v0.2

set -e

# Check if a command is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}


# Check if a package is installed
package_installed() {
    pacman -Q "$1" >/dev/null 2>&1
}


setup_blackarch_repo() {
    wget https://blackarch.org/strap.sh -O /tmp/strap.sh
    chmod +x /tmp/strap.sh && cd /tmp/ && sudo ./strap.sh
}

setup_oh_my_zsh() {
    # Change shell to zsh
    sudo chsh -s /usr/bin/zsh $USER
    
    # Install oh-my-zsh
    sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
    
    # Install custom theme
    wget https://raw.githubusercontent.com/FlareXes/dotfiles/main/.oh-my-zsh/custom/themes/archcraft.zsh-theme -O $HOME/.oh-my-zsh/custom/themes/archcraft.zsh-theme
    
    # Overwrite the .zshrc
    wget https://raw.githubusercontent.com/FlareXes/dotfiles/main/.zshrc -O $HOME/.zshrc && source $HOME/.zshrc

    # Install Plugins
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
}


enable_systemd_services() {
    # Snap
    sudo systemctl enable --now snapd.socket
    sudo ln -s /var/lib/snapd/snap /snap
    
    # Docker
    sudo systemctl enable --now docker.service
    sudo systemctl start docker.service
    sudo systemctl restart docker
    sudo usermod -aG docker $USER
    sudo docker run hello-world
    
    # Ufw
    sudo systemctl enable --now ufw
    sudo systemctl start ufw
    sudo ufw default allow outgoing
    sudo ufw default deny incoming
    sudo ufw enable
}


install_basic_packages() {
    dependencies=("base-devel" "git" "gdb" "wget" "zsh" "curl" "go" "sed" "plocate" "net-tools" "ttf-jetbrains-mono-nerd" "flatpak" "reflector" "fastfetch" "neovim" "lsd" "mpv" "baobab" "expect" "axel" "pass-otp" "yt-dlp" "jq" "bc" "bat" "fzf" "unzip" "p7zip" "docker" "aws-cli" "ufw" "wireshark-qt" "timeshift" "python-pip" "bpython" "wtype" "macchanger" "firejail" "translate-shell" "obs-studio" "brightnessctl" "imagemagick" "swaylock" "grim" "slurp" "swappy" "rofi-wayland" "wl-clipboard")
    
    # Install missing dependencies
    for dependency in "${dependencies[@]}"; do
        if ! command_exists "$dependency"; then
            if ! package_installed "$dependency"; then
                sudo pacman -S --disable-download-timeout --noconfirm "$dependency"
            fi
        fi
    done
}


install_yay_packages() {
    yay_dependencies=("librewolf-bin" "brave-bin" "appimagelauncher" "portmaster-stub-bin" "pup" "mpv-thumbnail-script" "hyprpicker-git" )
    
    for dependency in "${yay_dependencies[@]}"; do
        if ! command_exists "$dependency"; then
            if ! package_installed "$dependency"; then
                yay -S --noconfirm "$dependency"
            fi
        fi
    done
}


install_snap_packages() {
    if ! command_exists "code-insiders"; then
        sudo snap install code-insiders --classic
    fi
}


install_flatpak_packages() {
    flatpak_dependencies=("md.obsidian.Obsidian" "io.freetubeapp.FreeTube" "com.github.tchx84.Flatseal" "org.gnome.World.PikaBackup")
    
    for dependency in "${yay_dependencies[@]}"; do
        if ! command_exists "$dependency"; then
            flatpak install flathub "$dependency"
        fi
    done
}


install_from_aur() {
    if ! command_exists "yay"; then
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay && makepkg -sirc --noconfirm
    fi
    
    if ! command_exists "snap"; then
        git clone https://aur.archlinux.org/snapd.git /tmp/snapd
        cd /tmp/snapd && makepkg -sirc --noconfirm
    fi
}


install_github_tools() {
    # Scripts
    scripts=(
        "fshare=https://raw.githubusercontent.com/FlareXes/fshare/main/fshare"
        "myman=https://raw.githubusercontent.com/FlareXes/Micro-Utils/main/bin/myman"
        "passrofi=https://raw.githubusercontent.com/FlareXes/passrofi/main/passrofi"
        "check-breach=https://raw.githubusercontent.com/FlareXes/check-breach/main/check-breach"
    )

    # Tools
    tools=(
        "offsync=https://github.com/FlareXes/offsync.git"
        "watodo=https://github.com/FlareXes/watodo.git"
    )

    # Install scripts from GitHub
    for script in "${scripts[@]}"; do
        name="${script%=*}"
        url="${script#*=}"
        if ! command_exists "$name"; then
            sudo wget "$url" -O "/usr/local/bin/$name"
            sudo chmod +x "/usr/local/bin/$name"
        fi
    done

    # Install tools from GitHub
    for tool in "${tools[@]}"; do
        name="${tool%=*}"
        url="${tool#*=}"
        temp_dir=$(mktemp -d -t $name.XXXXXXXXXX)
        if ! command_exists "$name"; then
            git clone "$url" "$temp_dir"
            cd "$temp_dir" && chmod +x setup.sh && ./setup.sh
        fi
    done
}


install_hacking_tools() {
    dependencies=("hashcat" "johnny" "haiti" "feroxbuster" "nmap" "whois")
    for dependency in "${dependencies[@]}"; do
        if ! command_exists "$dependency"; then
            if ! package_installed "$dependency"; then
                sudo pacman -S  --disable-download-timeout --noconfirm "$dependency"
            fi
        fi
    done
}


update_configs() {    
    # Neovim
    git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1
    sed -i "s/transparency = false/transparency = true/" ~/.config/nvim/lua/core/default_config.lua
}


miscellaneous() {
    sudo wget https://raw.githubusercontent.com/FlareXes/Micro-Utils/main/systemd-unit/macspoof@.service -O /etc/systemd/system/macspoof@.service
    sudo systemctl enable macspoof@wlan0.service
    
    sudo wget https://raw.githubusercontent.com/FlareXes/Micro-Utils/main/systemd-unit/change-machine-id.service -O /etc/systemd/system/change-machine-id.service
    sudo systemctl enable change-machine-id.service
    
    git clone https://github.com/FlareXes/dotfiles.git $HOME/dotfiles
    
    sudo chmod +x /usr/sbin/dumpcap /usr/bin/dumpcap
}


# # # # # # # # #  # # # # # #  # # # # # #  # # # # # #  # # # # # #
#                                                                   #
# ██╗   ██╗ ██████╗ ██╗██████╗     ███╗   ███╗ █████╗ ██╗███╗   ██╗ #
# ██║   ██║██╔═══██╗██║██╔══██╗    ████╗ ████║██╔══██╗██║████╗  ██║ #
# ██║   ██║██║   ██║██║██║  ██║    ██╔████╔██║███████║██║██╔██╗ ██║ #
# ╚██╗ ██╔╝██║   ██║██║██║  ██║    ██║╚██╔╝██║██╔══██║██║██║╚██╗██║ #
#  ╚████╔╝ ╚██████╔╝██║██████╔╝    ██║ ╚═╝ ██║██║  ██║██║██║ ╚████║ #
#   ╚═══╝   ╚═════╝ ╚═╝╚═════╝     ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ #
#                                                                   #
# # # # # # # # #  # # # # # #  # # # # # #  # # # # # #  # # # # # #


sudo pacman -Syyu --noconfirm --disable-download-timeout

install_basic_packages
install_flatpak_packages
install_github_tools
install_from_aur

setup_oh_my_zsh
setup_blackarch_repo
install_hacking_tools
install_yay_packages
install_snap_packages

enable_systemd_services
update_configs
miscellaneous

echo -e "\nSCRIPT IS COMPLETED, REBOOT YOUR SYSTEM"
