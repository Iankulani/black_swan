#!/bin/bash
# BLACK_SWAN_V4 - Linux Installation Script
# Author: Ian Carter Kulani
# Version: 4.0.0

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${RED}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${CYAN}        🦢 BLACK SWAN V4 - Linux Installation                          ${RED}║${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${YELLOW}⚠️ This script should be run as root for full functionality${NC}"
   echo -e "${YELLOW}   Try: sudo ./install.sh${NC}"
   exit 1
fi

# Detect OS
OS=$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
echo -e "${BLUE}🔍 Detected OS: ${CYAN}$OS${NC}"

# Function to install dependencies
install_dependencies() {
    echo -e "\n${BLUE}📦 Installing system dependencies...${NC}"
    
    case $OS in
        ubuntu|debian|linuxmint)
            apt-get update
            apt-get install -y \
                python3 python3-pip python3-dev \
                nmap curl wget netcat-openbsd traceroute \
                whois dnsutils openssh-client \
                docker docker-compose \
                tcpdump hping3 iptables iputils-ping \
                git build-essential libssl-dev libffi-dev \
                libpcap-dev libxml2-dev libxslt-dev \
                libjpeg-dev zlib1g-dev \
                tmux screen htop iftop nethogs iotop strace \
                tshark wireshark-common \
                nmap-common python3-venv python3-wheel \
                default-libmysqlclient-dev \
                postgresql postgresql-contrib redis-server \
                nginx apache2-utils
            ;;
        centos|rhel|fedora|rocky|almalinux)
            if command -v dnf &> /dev/null; then
                dnf install -y epel-release
                dnf install -y \
                    python3 python3-pip python3-devel \
                    nmap curl wget nc traceroute \
                    whois bind-utils openssh-clients \
                    docker docker-compose \
                    tcpdump hping3 iptables iputils \
                    git gcc openssl-devel libffi-devel \
                    libpcap-devel libxml2-devel libxslt-devel \
                    libjpeg-turbo-devel zlib-devel \
                    tmux screen htop iftop nethogs iotop strace \
                    wireshark-cli \
                    nmap-ncat python3-venv python3-wheel \
                    mariadb-devel \
                    postgresql postgresql-server redis \
                    nginx httpd-tools
            else
                yum install -y epel-release
                yum install -y \
                    python3 python3-pip python3-devel \
                    nmap curl wget nc traceroute \
                    whois bind-utils openssh-clients \
                    docker docker-compose \
                    tcpdump hping3 iptables iputils \
                    git gcc openssl-devel libffi-devel \
                    libpcap-devel libxml2-devel libxslt-devel \
                    libjpeg-turbo-devel zlib-devel \
                    tmux screen htop iftop nethogs iotop strace \
                    wireshark-cli \
                    nmap-ncat python3-venv python3-wheel \
                    mariadb-devel \
                    postgresql postgresql-server redis \
                    nginx httpd-tools
            fi
            ;;
        alpine)
            apk add --no-cache \
                python3 py3-pip py3-dev \
                nmap curl wget netcat-openbsd traceroute \
                whois bind-tools openssh-client \
                docker docker-compose \
                tcpdump hping3 iptables iputils \
                git build-base openssl-dev libffi-dev \
                libpcap-dev libxml2-dev libxslt-dev \
                libjpeg-turbo-dev zlib-dev \
                tmux screen htop iftop nethogs iotop strace \
                tshark wireshark \
                nmap-scripts python3-venv python3-wheel \
                postgresql postgresql-contrib redis \
                nginx apache2-utils
            ;;
        *)
            echo -e "${YELLOW}⚠️ Unsupported OS: $OS${NC}"
            echo -e "${YELLOW}   Please install dependencies manually${NC}"
            ;;
    esac
}

# Function to install Python packages
install_python_packages() {
    echo -e "\n${BLUE}🐍 Installing Python packages...${NC}"
    
    # Upgrade pip
    pip3 install --upgrade pip
    
    # Install requirements
    if [ -f "requirements.txt" ]; then
        pip3 install -r requirements.txt || {
            echo -e "${YELLOW}⚠️ Full requirements installation failed, installing minimal...${NC}"
            pip3 install -r requirements-minimal.txt
        }
    else
        pip3 install \
            requests psutil paramiko flask flask-socketio flask-cors \
            discord.py telethon slack-sdk pynput pyautogui \
            reportlab beautifulsoup4 dnspython whois scapy \
            python-dotenv cryptography pyyaml
    fi
    
    # Install additional tools
    if command -v npm &> /dev/null; then
        npm install -g wscat
    fi
}

# Function to setup Docker
setup_docker() {
    echo -e "\n${BLUE}🐳 Setting up Docker...${NC}"
    
    # Start Docker service
    if command -v systemctl &> /dev/null; then
        systemctl enable docker
        systemctl start docker
    fi
    
    # Add current user to docker group
    if [ -n "$SUDO_USER" ]; then
        usermod -aG docker $SUDO_USER
        echo -e "${GREEN}✅ User $SUDO_USER added to docker group${NC}"
    fi
    
    # Build Docker image if Dockerfile exists
    if [ -f "Dockerfile" ]; then
        echo -e "${BLUE}🐳 Building Docker image...${NC}"
        docker build -t black_swan_v4:latest .
    fi
}

# Function to setup database
setup_database() {
    echo -e "\n${BLUE}🗄️ Setting up database...${NC}"
    
    # Start PostgreSQL
    if command -v systemctl &> /dev/null; then
        systemctl enable postgresql
        systemctl start postgresql
    fi
    
    # Create database
    if command -v psql &> /dev/null; then
        sudo -u postgres psql -c "CREATE USER blackswan WITH PASSWORD 'swan_secure_2024';" 2>/dev/null || true
        sudo -u postgres psql -c "CREATE DATABASE black_swan_v4 OWNER blackswan;" 2>/dev/null || true
    fi
    
    # Start Redis
    if command -v systemctl &> /dev/null; then
        systemctl enable redis
        systemctl start redis
    fi
}

# Function to create directories
create_directories() {
    echo -e "\n${BLUE}📁 Creating directories...${NC}"
    
    mkdir -p \
        .black_swan_v4 \
        black_swan_v4_reports \
        logs \
        temp \
        data \
        web-static \
        redis-data \
        postgres-data
    
    chmod 755 .black_swan_v4 black_swan_v4_reports logs temp data
}

# Function to create configuration
create_config() {
    echo -e "\n${BLUE}⚙️ Creating configuration...${NC}"
    
    if [ ! -f ".black_swan_v4/config.json" ]; then
        cat > .black_swan_v4/config.json << 'EOF'
{
    "version": "4.0.0",
    "auto_start": false,
    "auto_block_enabled": false,
    "auto_block_threshold": 5,
    "scan_timeout": 30,
    "report_format": "html",
    "generate_graphics": true,
    "web": {
        "enabled": true,
        "port": 5000,
        "host": "0.0.0.0"
    },
    "database": {
        "type": "postgresql",
        "host": "localhost",
        "port": 5432,
        "database": "black_swan_v4",
        "user": "blackswan",
        "password": "swan_secure_2024"
    },
    "redis": {
        "host": "localhost",
        "port": 6379
    }
}
EOF
        echo -e "${GREEN}✅ Configuration created at .black_swan_v4/config.json${NC}"
    fi
}

# Function to setup firewall
setup_firewall() {
    echo -e "\n${BLUE}🔥 Setting up firewall...${NC}"
    
    if command -v ufw &> /dev/null; then
        ufw allow 22/tcp
        ufw allow 5000/tcp
        ufw allow 8080/tcp
        ufw allow 8443/tcp
        ufw allow 9000/tcp
        ufw allow 6000:6100/tcp
        ufw --force enable
        echo -e "${GREEN}✅ Firewall configured${NC}"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=22/tcp
        firewall-cmd --permanent --add-port=5000/tcp
        firewall-cmd --permanent --add-port=8080/tcp
        firewall-cmd --permanent --add-port=8443/tcp
        firewall-cmd --permanent --add-port=9000/tcp
        firewall-cmd --permanent --add-port=6000-6100/tcp
        firewall-cmd --reload
        echo -e "${GREEN}✅ Firewall configured${NC}"
    else
        echo -e "${YELLOW}⚠️ Firewall not configured (ufw/firewall-cmd not found)${NC}"
    fi
}

# Function to create systemd service
create_service() {
    echo -e "\n${BLUE}🔧 Creating systemd service...${NC}"
    
    if command -v systemctl &> /dev/null; then
        cat > /etc/systemd/system/black-swan-v4.service << 'EOF'
[Unit]
Description=BLACK_SWAN_V4 Cybersecurity Platform
After=network.target docker.service postgresql.service redis.service
Wants=docker.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/black-swan-v4
ExecStart=/usr/bin/python3 /opt/black-swan-v4/black_swan.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=black-swan-v4
Environment=PYTHONUNBUFFERED=1
Environment=BLACK_SWAN_HOME=/opt/black-swan-v4

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl daemon-reload
        systemctl enable black-swan-v4
        echo -e "${GREEN}✅ Systemd service created${NC}"
    fi
}

# Function to create startup script
create_startup_script() {
    echo -e "\n${BLUE}📄 Creating startup script...${NC}"
    
    cat > start.sh << 'EOF'
#!/bin/bash
# BLACK_SWAN_V4 Startup Script

cd "$(dirname "$0")"

echo "🦢 Starting BLACK_SWAN_V4..."
python3 black_swan.py "$@"
EOF
    
    chmod +x start.sh
    echo -e "${GREEN}✅ Startup script created: ./start.sh${NC}"
}

# Main installation
echo -e "${GREEN}🚀 Starting installation...${NC}"

install_dependencies
install_python_packages
create_directories
create_config
setup_database
setup_docker
setup_firewall
create_service
create_startup_script

echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${CYAN}        ✅ BLACK_SWAN_V4 Installation Complete!                         ${GREEN}║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
echo -e "\n${CYAN}📋 Installation Summary:${NC}"
echo -e "  📁 Installation Directory: $(pwd)"
echo -e "  🐍 Python: $(python3 --version)"
echo -e "  🐳 Docker: $(docker --version 2>/dev/null || echo 'Not installed')"
echo -e "  🗄️ PostgreSQL: $(psql --version 2>/dev/null || echo 'Not installed')"
echo -e "  🗄️ Redis: $(redis-cli --version 2>/dev/null || echo 'Not installed')"
echo -e "  🔧 Service: black-swan-v4"
echo -e "\n${GREEN}🎯 Next Steps:${NC}"
echo -e "  1. Start the service: sudo systemctl start black-swan-v4"
echo -e "  2. Run manually: ./start.sh"
echo -e "  3. Access web dashboard: http://localhost:5000"
echo -e "  4. Type 'help' for available commands"
echo -e "\n${YELLOW}⚠️  Remember: For authorized security testing only${NC}"