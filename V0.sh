#!/bin/bash

# Define color codes for better visual feedback
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Base configuration
INSTALL_DIR="/opt/ob-web"
CONFIG_DIR="/etc/ob-web"
LOG_DIR="/var/log/ob-web"
DATA_DIR="/var/lib/ob-web"
REPO_URL="https://github.com/Lucky7897/Ob-web"

# Log file setup
LOG_FILE="/var/log/ob-web-install.log"
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Logging function
log() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling
handle_error() {
    log "${RED}ERROR: $1${NC}"
    if [ "$2" = "fatal" ]; then
        log "${RED}Fatal error occurred. Installation aborted.${NC}"
        exit 1
    fi
}

# Show custom banner
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
      ║        Created by Lucky7897          ║
      ║  The Ultimate Web Automation Tool     ║
      ╚══════════════════════════════════════╝
EOF
    echo -e "${PURPLE}Repository: ${REPO_URL}${NC}"
    echo
}

# Check system requirements
check_system_requirements() {
    log "Checking system requirements..."
    
    # Check CPU cores
    CPU_CORES=$(nproc)
    if [ "$CPU_CORES" -lt 2 ]; then
        handle_error "Minimum 2 CPU cores required. Found: $CPU_CORES" "fatal"
    fi
    
    # Check RAM
    TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$TOTAL_RAM" -lt 2048 ]; then
        handle_error "Minimum 2GB RAM required. Found: $TOTAL_RAM MB" "fatal"
    fi
    
    # Check disk space
    FREE_SPACE=$(df -m / | awk 'NR==2 {print $4}')
    if [ "$FREE_SPACE" -lt 10240 ]; then
        handle_error "Minimum 10GB free space required. Found: $FREE_SPACE MB" "fatal"
    fi
    
    log "${GREEN}System requirements check passed.${NC}"
}

# Install dependencies
install_dependencies() {
    log "Installing system dependencies..."
    
    # Install necessary packages
    if command -v apt-get &> /dev/null; then
        apt-get install -y \
            curl \
            wget \
            git \
            nginx \
            jq \
            dotnet-sdk-8.0
    elif command -v yum &> /dev/null; then
        yum install -y \
            curl \
            wget \
            git \
            nginx \
            jq \
            dotnet-sdk-8.0
    else
        handle_error "Unsupported package manager" "fatal"
    fi
    
    log "${GREEN}Dependencies installed successfully.${NC}"
}

# Setup .NET application
setup_dotnet_app() {
    log "Setting up .NET application..."
    
    # Navigate to the directory containing the .NET project
    cd "$INSTALL_DIR/src" || handle_error "Failed to enter source directory" "fatal"
    
    # Restore and build the .NET project
    dotnet restore || handle_error "Failed to restore .NET dependencies" "fatal"
    dotnet build || handle_error "Failed to build .NET application" "fatal"
    
    log "${GREEN}.NET application setup completed.${NC}"
}

# Setup web application
setup_web_app() {
    log "Setting up web application..."
    
    # Clone repository
    git clone "$REPO_URL" "$INSTALL_DIR/src"
    cd "$INSTALL_DIR/src" || handle_error "Failed to enter source directory" "fatal"
    
    # Create directories
    mkdir -p "$INSTALL_DIR/templates"
    mkdir -p "$DATA_DIR/uploads"
    
    # Copy templates and app files
    cp src/templates/* "$INSTALL_DIR/templates/"
    cp src/app.py "$INSTALL_DIR/"
    
    # Set permissions
    chown -R www-data:www-data "$INSTALL_DIR"
    chown -R www-data:www-data "$DATA_DIR"
    chmod 755 "$INSTALL_DIR"
    chmod 750 "$DATA_DIR/uploads"
    
    log "${GREEN}Web application setup completed.${NC}"
}

# Configure NGINX
setup_nginx() {
    log "Setting up NGINX..."
    
    cat > /etc/nginx/sites-available/ob-web << EOF
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        client_max_body_size 16M;
    }
}
EOF
    
    ln -sf /etc/nginx/sites-available/ob-web /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    nginx -t && systemctl reload nginx
    
    log "${GREEN}NGINX setup completed.${NC}"
}

# Show success message
show_success() {
    echo -e "\n${GREEN}┌────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│      Installation Complete! 🎉          │${NC}"
    echo -e "${GREEN}└────────────────────────────────────────┘${NC}"
    echo -e "\n${CYAN}OB-Web has been successfully installed!${NC}"
    echo -e "\n${YELLOW}Access Information:${NC}"
    echo -e "  ${BLUE}➤ Web Interface:${NC} https://your-domain"
    echo -e "  ${BLUE}➤ Default Username:${NC} admin"
    echo -e "  ${BLUE}➤ Default Password:${NC} admin"
    echo -e "\n${RED}IMPORTANT: Change the default password after first login!${NC}"
    echo -e "\n${PURPLE}Repository: ${REPO_URL}${NC}"
    echo -e "\n${CYAN}Remote Access URL:${NC} http://$(curl -s ifconfig.me):5000"
}

# Main installation process
main() {
    if [ "$EUID" -ne 0 ]; then 
        handle_error "This script must be run as root" "fatal"
    fi
    
    show_banner
    
    echo -e "${YELLOW}This will install OB-Web and all its dependencies.${NC}"
    echo -e "${YELLOW}Do you want to continue? (y/n)${NC} "
    read -r confirm
    if [ "$confirm" != "y" ]; then
        echo -e "${RED}Installation cancelled.${NC}"
        exit 1
    fi
    
    echo -e "\n${CYAN}Starting installation...${NC}\n"
    
    check_system_requirements
    install_dependencies
    setup_dotnet_app
    setup_web_app
    setup_nginx
    
    show_success
}

# Start the installation
main
