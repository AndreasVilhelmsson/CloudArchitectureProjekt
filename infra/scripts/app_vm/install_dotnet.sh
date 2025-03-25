#!/bin/bash

# ==================================
# 📦 install_dotnet.sh
# Installerar .NET SDK + Runtime på Ubuntu VM
# ==================================

set -e  # Stoppa scriptet om något går fel

# Färger för snygg output
GREEN="\033[1;32m"
NC="\033[0m"

# 1. Uppdatera paketindex
echo -e "${GREEN}🧰 Uppdaterar systemet...${NC}"
sudo apt update -y && sudo apt upgrade -y

# 2. Installera beroenden
echo -e "${GREEN}📦 Installerar beroenden...${NC}"
sudo apt install -y wget apt-transport-https software-properties-common

# 3. Ladda ner Microsofts paketfeed
echo -e "${GREEN}🔗 Laddar ner Microsofts paketregister...${NC}"
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb

# 4. Installera feed och ta bort filen
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# 5. Uppdatera och installera .NET
echo -e "${GREEN}🚀 Installerar .NET SDK och ASP.NET Runtime...${NC}"
sudo apt update -y
sudo apt install -y dotnet-sdk-8.0 aspnetcore-runtime-8.0

# 6. Bekräfta installation
echo -e "${GREEN}✅ .NET är installerat! Version:${NC}"
dotnet --version
