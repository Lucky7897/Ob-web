#!/bin/bash

# Define color codes for better visual feedback
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Base configuration
INSTALL_DIR="$HOME/ob-web"
DATA_DIR="$HOME/ob-web/data"
DOTNET_VERSION="6.0"
REPO_URL="https://github.com/Lucky7897/Ob-web"

# Logging function
log() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Error handling
handle_error() {
    log "${RED}ERROR: $1${NC}"
    exit 1
}

# Show banner
show_banner() {
    clear
    cat << "EOF"
 ██████╗ ██████╗       ██╗    ██╗███████╗██████╗ 
██╔═══██╗██╔══██╗      ██║    ██║██╔════╝██╔══██╗
██║   ██║██████╔╝█████╗██║ █╗ ██║█████╗  ██████╔╝
██║   ██║██╔══██╗╚════╝██║███╗██║██╔══╝  ██╔══██╗
╚██████╔╝██████╔╝      ╚███╔███╔╝███████╗██████╔╝
 ╚═════╝ ╚═════╝        ╚══╝╚══╝ ╚══════╝╚═════╝ 

    ╔══════════════════════════════════════╗
    ║     GitHub Codespace Installation    ║
    ╚══════════════════════════════════════╝
EOF
    echo -e "${BLUE}Repository: ${REPO_URL}${NC}"
    echo
}

# Install .NET SDK
install_dotnet() {
    log "${YELLOW}Installing .NET SDK ${DOTNET_VERSION}...${NC}"
    
    # Download Microsoft signing key and repository
    wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb

    # Install .NET SDK
    sudo apt-get update
    sudo apt-get install -y apt-transport-https
    sudo apt-get update
    sudo apt-get install -y dotnet-sdk-${DOTNET_VERSION}
    sudo apt-get install -y aspnetcore-runtime-${DOTNET_VERSION}
    
    # Verify installation
    if ! command -v dotnet &> /dev/null; then
        handle_error ".NET SDK installation failed"
    fi
    
    log "${GREEN}.NET SDK ${DOTNET_VERSION} installed successfully${NC}"
}

# Setup OpenBullet Web
setup_openbullet() {
    log "${YELLOW}Setting up OpenBullet Web...${NC}"
    
    # Create directories
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$DATA_DIR"
    
    # Clone repository
    git clone "$REPO_URL" "$INSTALL_DIR/src"
    
    # Build and publish
    cd "$INSTALL_DIR/src"
    dotnet restore
    dotnet build --configuration Release
    dotnet publish --configuration Release --output "$INSTALL_DIR/publish"
    
    # Create configuration file
    cat > "$INSTALL_DIR/publish/appsettings.json" << EOF
{
    "AllowedHosts": "*",
    "ConnectionStrings": {
        "DefaultConnection": "Data Source=$DATA_DIR/ob.db"
    },
    "ApplicationSettings": {
        "EnableRegistration": true,
        "DataFolder": "$DATA_DIR"
    }
}
EOF
    
    log "${GREEN}OpenBullet Web setup completed${NC}"
}

# Start application
start_application() {
    log "${YELLOW}Starting OpenBullet Web...${NC}"
    
    cd "$INSTALL_DIR/publish"
    ASPNETCORE_URLS="http://0.0.0.0:5000" dotnet OpenBullet.Web.dll &
    
    # Get the codespace URL
    CODESPACE_URL="https://$CODESPACE_NAME-5000.$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN"
    
    log "${GREEN}Application started successfully${NC}"
    echo -e "\n${CYAN}Access Information:${NC}"
    echo -e "${YELLOW}➤ Web Interface:${NC} $CODESPACE_URL"
    echo -e "${YELLOW}➤ Default Username:${NC} admin"
    echo -e "${YELLOW}➤ Default Password:${NC} admin"
    echo -e "\n${RED}IMPORTANT: Change the default password after first login!${NC}"
}

# Main installation process
main() {
    show_banner
    
    echo -e "${YELLOW}Starting installation...${NC}\n"
    
    # Install .NET SDK
    install_dotnet
    
    # Setup OpenBullet Web
    setup_openbullet
    
    # Start the application
    start_application
}

# Start the installation
main
