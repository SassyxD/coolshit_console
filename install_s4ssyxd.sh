#!/bin/bash

# Update package lists
sudo apt update

# Install required packages
sudo apt install -y lolcat figlet fastfetch docker.io git 

# Clone all figlet fonts
git clone https://github.com/xero/figlet-fonts.git /tmp/figlet-fonts

# Copy fonts to figlet directory
sudo cp /tmp/figlet-fonts/* /usr/share/figlet/

# Clean up
rm -rf /tmp/figlet-fonts

# Add random figlet font startup banner to ~/.bashrc
echo '' >> ~/.bashrc
echo '# >>> S4ssyxd Random Banner >>>' >> ~/.bashrc
echo 'clear' >> ~/.bashrc
echo 'fonts=($(ls /usr/share/figlet/*.flf))' >> ~/.bashrc
echo 'randfont=${fonts[$RANDOM % ${#fonts[@]}]}' >> ~/.bashrc
echo 'figlet -f "$randfont" "s4ssyxd" | lolcat' >> ~/.bashrc
echo 'echo ""' >> ~/.bashrc
echo 'fastfetch' >> ~/.bashrc
echo '# <<< S4ssyxd Random Banner <<<' >> ~/.bashrc

echo "Installation complete! Open a new terminal to see your random s4ssyxd banner."
