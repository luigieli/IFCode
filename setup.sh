#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Starting IF Codes Environment Setup ===${NC}"

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}This script needs to run with sudo privileges for installation steps.${NC}"
        sudo -v
    fi
}

# Function to run command with sudo if needed
run_sudo() {
    if [ "$EUID" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

# 1. Update System and Install Dependencies
echo -e "${GREEN}>> Updating system and installing dependencies...${NC}"
check_root

run_sudo apt-get update
run_sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    wget \
    unzip \
    openssl \
    sed

# 2. Install Docker (if not installed)
if ! command -v docker &> /dev/null; then
    echo -e "${GREEN}>> Installing Docker...${NC}"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | run_sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | run_sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    run_sudo apt-get update
    run_sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
else
    echo -e "${YELLOW}>> Docker is already installed. Skipping...${NC}"
fi

# Add current user to docker group (if not already)
CURRENT_USER=${SUDO_USER:-$USER}
if ! groups "$CURRENT_USER" | grep -q docker; then
    echo -e "${GREEN}>> Adding user $CURRENT_USER to docker group...${NC}"
    run_sudo usermod -aG docker "$CURRENT_USER"
    echo -e "${YELLOW}!! You may need to log out and log back in for group changes to take effect. !!${NC}"
fi

# 3. Configure GRUB for Judge0 (if not configured)
# Judge0 requires systemd.unified_cgroup_hierarchy=0
echo -e "${GREEN}>> Checking GRUB configuration for Judge0...${NC}"
if ! grep -q "systemd.unified_cgroup_hierarchy=0" /etc/default/grub; then
    echo -e "${GREEN}>> Configuring GRUB...${NC}"
    run_sudo cp /etc/default/grub /etc/default/grub.backup
    run_sudo sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=0"/' /etc/default/grub
    # Also handle cases where GRUB_CMDLINE_LINUX is not empty but doesn't have the setting
    # For simplicity in this specific setup, the replacement above covers the default clean Ubuntu cloud img.
    # A more robust approach might be needed if the user has other kernel params.

    run_sudo update-grub
    echo -e "${YELLOW}!! GRUB updated. A system reboot is REQUIRED for Judge0 to work correctly. !!${NC}"
else
    echo -e "${YELLOW}>> GRUB is already configured. Skipping...${NC}"
fi

# 4. Setup Configuration Files and Secrets
echo -e "${GREEN}>> Setting up configuration files and secrets...${NC}"

# Define paths (relative to the script location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JUDGE0_CONF="$SCRIPT_DIR/judge0.conf"
BACKEND_ENV_EXAMPLE="$SCRIPT_DIR/back/src/.env.example"
BACKEND_ENV="$SCRIPT_DIR/back/src/.env"
PASSWORDS_FILE="$SCRIPT_DIR/passwords.txt"

# Generate Passwords if they don't exist in judge0.conf or passwords.txt
# We check if judge0.conf has default values or if we should regenerate
# Ideally, we only generate if we haven't done so before.

if [ ! -f "$PASSWORDS_FILE" ]; then
    echo -e "${GREEN}>> Generating new secure passwords...${NC}"
    REDIS_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
    POSTGRES_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)

    # Save to passwords.txt for reference
    echo "Redis Password: $REDIS_PASS" > "$PASSWORDS_FILE"
    echo "PostgreSQL Password: $POSTGRES_PASS" >> "$PASSWORDS_FILE"

    # Update judge0.conf
    if [ -f "$JUDGE0_CONF" ]; then
        # We use a temp file to avoid permission issues if editing in place with sed as non-root on a root-owned file (though here we run as user usually)
        sed -i "s#REDIS_PASSWORD=.*#REDIS_PASSWORD=$REDIS_PASS#" "$JUDGE0_CONF"
        sed -i "s#POSTGRES_PASSWORD=.*#POSTGRES_PASSWORD=$POSTGRES_PASS#" "$JUDGE0_CONF"
        echo -e "${GREEN}>> Updated judge0.conf${NC}"
    else
         echo -e "${RED}!! judge0.conf not found at $JUDGE0_CONF !!${NC}"
    fi

    # Setup Backend .env
    if [ -f "$BACKEND_ENV_EXAMPLE" ]; then
        echo -e "${GREEN}>> Creating backend .env file...${NC}"
        cp "$BACKEND_ENV_EXAMPLE" "$BACKEND_ENV"
        sed -i "s#DB_PASSWORD=.*#DB_PASSWORD=$POSTGRES_PASS#" "$BACKEND_ENV"
        # Ensure DB_HOST is set to 'postgres' for docker-compose networking,
        # but the .env.example might default to 127.0.0.1 or similar.
        # Let's leave other settings as per .env.example defaults unless specified.
        echo -e "${GREEN}>> Created back/src/.env and injected password.${NC}"
    else
        echo -e "${RED}!! back/src/.env.example not found !!${NC}"
    fi
else
    echo -e "${YELLOW}>> passwords.txt already exists. Skipping password generation to preserve existing secrets.${NC}"
    echo -e "${YELLOW}>> If you want to regenerate, delete passwords.txt and run this script again.${NC}"
fi

echo -e "${GREEN}=== Setup Complete ===${NC}"
echo -e "${GREEN}1. If this is your first run, please REBOOT your system now to apply kernel changes.${NC}"
echo -e "${GREEN}2. After reboot, run 'docker compose up -d' to start the services.${NC}"
echo -e "${GREEN}3. Passwords have been saved to 'passwords.txt' and automatically configured in '.env' files.${NC}"
