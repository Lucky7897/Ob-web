​#!/bin/bash

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
BACKUP_DIR="/var/backup/ob-web"
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
    
    # Update package lists
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get upgrade -y
        apt-get install -y \
            curl \
            wget \
            git \
            nginx \
            postgresql \
            redis-server \
            certbot \
            python3-certbot-nginx \
            python3-pip \
            python3-venv \
            supervisor \
            ufw \
            jq
    elif command -v yum &> /dev/null; then
        yum update -y
        yum install -y \
            curl \
            wget \
            git \
            nginx \
            postgresql-server \
            postgresql-contrib \
            redis \
            certbot \
            python3-certbot-nginx \
            python3-pip \
            python3-venv \
            supervisor \
            firewalld \
            jq
    else
        handle_error "Unsupported package manager" "fatal"
    fi
    
    # Install Python packages
    python3 -m venv /opt/ob-web/venv
    source /opt/ob-web/venv/bin/activate
    pip install flask werkzeug pyjwt gunicorn
    
    log "${GREEN}Dependencies installed successfully.${NC}"
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

# Setup SSL
setup_ssl() {
    log "Setting up SSL..."
    
    echo -e "${YELLOW}Enter your domain name (leave empty for self-signed certificate):${NC} "
    read -r DOMAIN
    
    if [ -n "$DOMAIN" ]; then
        certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "admin@$DOMAIN"
    else
        mkdir -p /etc/ssl/ob-web
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /etc/ssl/ob-web/private.key \
            -out /etc/ssl/ob-web/certificate.crt \
            -subj "/CN=ob-web"
            
        sed -i "s/listen 80;/listen 443 ssl;\n    ssl_certificate \/etc\/ssl\/ob-web\/certificate.crt;\n    ssl_certificate_key \/etc\/ssl\/ob-web\/private.key;/" \
            /etc/nginx/sites-available/ob-web
    fi
    
    log "${GREEN}SSL setup completed.${NC}"
}

# Setup firewall
setup_firewall() {
    log "Setting up firewall..."
    
    if command -v ufw &> /dev/null; then
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw allow 5000/tcp
        ufw --force enable
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --permanent --add-port=5000/tcp
        firewall-cmd --reload
    fi
    
    log "${GREEN}Firewall setup completed.${NC}"
}

# Setup database
setup_database() {
    log "Setting up PostgreSQL database..."
    
    if command -v systemctl &> /dev/null; then
        systemctl enable postgresql
        systemctl start postgresql
    else
        service postgresql start
    fi
    
    # Create database and user
    sudo -u postgres psql -c "CREATE DATABASE obweb;"
    sudo -u postgres psql -c "CREATE USER obweb WITH ENCRYPTED PASSWORD 'obweb';"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE obweb TO obweb;"
    
    log "${GREEN}Database setup completed.${NC}"
}

# Setup Redis
setup_redis() {
    log "Setting up Redis..."
    
    if command -v systemctl &> /dev/null; then
        systemctl enable redis-server
        systemctl start redis-server
    else
        service redis-server start
    fi
    
    sed -i 's/# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/' /etc/redis/redis.conf
    sed -i 's/# maxmemory <bytes>/maxmemory 2gb/' /etc/redis/redis.conf
    
    log "${GREEN}Redis setup completed.${NC}"
}

# Setup backup system
setup_backup() {
    log "Setting up backup system..."
    
    mkdir -p "$BACKUP_DIR"
    
    cat > /usr/local/bin/ob-web-backup << EOF
#!/bin/bash
BACKUP_DATE=\$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/ob-web_\$BACKUP_DATE.tar.gz"

# Backup database
pg_dump obweb > "$BACKUP_DIR/db_backup_\$BACKUP_DATE.sql"

# Backup configuration and data
tar -czf \$BACKUP_FILE \\
    "$CONFIG_DIR" \\
    "$DATA_DIR" \\
    "$BACKUP_DIR/db_backup_\$BACKUP_DATE.sql"

# Remove old backups (keep last 7 days)
find "$BACKUP_DIR" -name "ob-web_*.tar.gz" -mtime +7 -delete
find "$BACKUP_DIR" -name "db_backup_*.sql" -mtime +7 -delete
EOF
    
    chmod +x /usr/local/bin/ob-web-backup
    
    echo "0 0 * * * root /usr/local/bin/ob-web-backup" > /etc/cron.d/ob-web-backup
    
    log "${GREEN}Backup system setup completed.${NC}"
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
    setup_database
    setup_redis
    setup_web_app
    setup_nginx
    setup_ssl
    setup_firewall
    setup_backup
    
    show_success
}

# Start the installation
main
