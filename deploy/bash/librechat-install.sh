#!/bin/bash

# Colors for echo statements
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check for errors and exit if necessary
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error occurred at: $1${NC}"
        exit 1
    fi
}

# Install Docker
echo -e "${GREEN}Installing Docker${NC}"
sudo apt-get update || check_error "apt-get update"
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common || check_error "apt-get install"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg || check_error "curl"
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || check_error "tee"
sudo apt-get update || check_error "apt-get update"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || check_error "apt-get install"

# Add user to the docker group
echo -e "${GREEN}Updating group membership${NC}"
sudo groupadd docker || check_error "groupadd docker"
sudo usermod -aG docker $USER || check_error "usermod"
sudo su $USER || check_error "su $USER"

# Prompt user for update confirmation
echo -e "${GREEN}Update Confirmation${NC}"
read -p "Do you want to manually update the .env file? (y/n): " update_env

if [[ $update_env =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Please update the .env.example file in the main LibreChat directory with your desired options."
    echo "Then run the script again to continue with the installation."
    exit 0
elif [[ ! $update_env =~ ^[Nn]$ ]]; then
    echo -e "${GREEN}Leaving the .env.example file as defaults and continuing script.${NC}"
fi

# Backup existing .env file if it exists
if [[ -f ../../.env ]]; then
    backup_filename="../../.env.backup.$(date +'%Y%m%d-%H%M%S')"
    cp ../../.env "$backup_filename" || check_error "cp"
    echo -e "${GREEN}Existing .env file backed up to $backup_filename${NC}"
fi

# Update .env file if requested
if [[ $update_env =~ ^[Nn]$ ]]; then
    echo -e "${GREEN}Update .env File${NC}"
    read -p "Please provide your OpenAI API key: " openai_key
    sed -i "s/OPENAI_API_KEY=\"user_provided\"/OPENAI_API_KEY=\"$openai_key\"/" .env.example || check_error "sed"
    cp .env.example ../../.env || check_error "cp"
    echo -e "${GREEN}Updated .env file with OpenAI API key${NC}"
    echo -e "${GREEN}This only adds your OpenAI key to the .env file. If you need to make other changes, please modify the .env file manually.${NC}"
else
    echo -e "${GREEN}Skipping .env file update${NC}"
fi

# Start Docker services
echo -e "${GREEN}Starting Docker services${NC}"
docker compose build || check_error "docker compose build"
docker compose up -d || check_error "docker compose up"

# Query primary IP of the machine
IP=$(hostname -I | awk '{print $1}')

echo -e "${GREEN}Installation completed successfully.${NC}"
echo -e "${GREEN}You can now access your application at http://$IP:3080${NC}"
