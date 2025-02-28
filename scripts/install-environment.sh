#!/bin/bash

USERNAME="$1"

CWD=$(pwd)
echo -e "${GREEN}[+] Installing Hack Nerd Fonts${NC}"
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip\
	&& unzip Hack.zip -d /usr/share/fonts/ \
	&& fc-cache -fv \
	&& rm -rf Hack*

echo -e "${GREEN}[+] Installing Colloid theme${NC}"
mkdir theme
cd theme
wget -O colloid-icons.zip https://github.com/vinceliuice/Colloid-icon-theme/archive/refs/tags/2024-10-18.zip
wget -O colloid-theme.zip https://github.com/vinceliuice/Colloid-gtk-theme/archive/refs/tags/2024-06-18.zip
unzip colloid-icons.zip -d colloid-icons
unzip colloid-theme.zip -d colloid-theme
cd colloid-icons/Colloid* 
./install.sh -s nord
cd ../../colloid-theme/Colloid*
./install.sh
cd ../../..
rm -rf theme

echo -e "${GREEN}[+] Installing Btop Config${NC}"
btop &
sed -i 's#color_theme = .*#color_theme = \"/usr/share/btop/themes/nord.theme\"#g' /home/$USERNAME/.config/btop/btop.config 
sed -i 's#theme_background =.*#theme_background = False#g' /home/$USERNAME/.config/btop/btop.config
cd "$CWD"
