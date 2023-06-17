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

# Prompt for confirmation to proceed with removal
echo -e "${RED}WARNING! This will remove LibreChat completely from this system.${NC}"
read -p "$(echo -e ${RED}Type "librechat" to confirm the removal of LibreChat: ${NC})" confirmation
if [[ $confirmation != "librechat" ]]; then
    echo -e "${RED}Removal of LibreChat cancelled by the user.${NC}"
    exit 1
fi

# Stop Docker services
echo -e "${GREEN}Stopping Docker services${NC}"
docker compose down || check_error "docker-compose down"

# Uninstall Docker
echo -e "${GREEN}Uninstalling Docker${NC}"
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || check_error "apt-get purge"
sudo apt-get autoremove -y --purge || check_error "apt-get autoremove"

# Remove MongoDB data directory
read -p "Do you want to remove the MongoDB data directory './data-node'? (y/n): " remove_data
if [[ $remove_data =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Removing MongoDB data directory './data-node'${NC}"
    rm -rf ../../data-node || check_error "rm -rf data-node"
else
    echo -e "${GREEN}Skipping removal of MongoDB data directory.${NC}"
fi

echo -e "${GREEN}LibreChat uninstallation completed successfully.${NC}"
