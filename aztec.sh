#!/usr/bin/env bash
# ====================================================
# Aztec alpha-testnet full node automated installation & startup script
# Version: v0.85.0-alpha-testnet.5
# For Ubuntu/Debian based systems
# ====================================================

# Fail on errors, undefined variables, and propagate errors in pipelines
set -euo pipefail

# ANSI color codes for formatting output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

# Default values
AZTEC_VERSION="0.85.0-alpha-testnet.5"
DATA_DIR="$(pwd)/data"
LOG_LEVEL="info"
NETWORK="alpha-testnet"

# Print banner
print_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "    ___                                            "
    echo "   /   |____  __  __________  ____  ________  ____ "
    echo "  / /| /_  / / / / / ___/ _ \/_  / / ___/ _ \/ __ \\"
    echo " / ___ |/ /_/ /_/ / /  /  __/ / /_/ /  /  __/ / / /"
    echo "/_/  |_/___/\__,_/_/   \___/ /___/_/   \___/_/ /_/ "
    echo "                                                    "
    echo "-----------------------------------------------------"
    echo -e "${CYAN}${BOLD}"
    echo "-----------------------------------------------------"
    echo "   EZ Setup Aztec Sequencer"
    echo "-----------------------------------------------------"
    echo "Version: $AZTEC_VERSION"
    echo "Made with <3 by: Azurezren"
    echo "JOIN DISCORD: https://discord.gg/k2WTCyQtj4"
    echo "-----------------------------------------------------"
    echo -e "${RESET}"
}

# Log helper functions
log_info() {
    echo -e "${GREEN}[INFO]${RESET} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${RESET} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $1"
}

# Check for required permissions (keeping original root check)
check_permissions() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "⚠️ This script must be run with root (or sudo) privileges."
        exit 1
    fi
}

# Install Docker and Docker Compose (keeping original method)
install_docker() {
    log_info "Checking Docker installation..."
    
    if ! command -v docker &> /dev/null || ! command -v docker-compose &> /dev/null; then
        log_info "🐋 Docker or Docker Compose not found. Installing..."
        apt-get update
        apt-get install -y \
            apt-transport-https \
            ca-certificates \
            curl \
            gnupg-agent \
            software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
        add-apt-repository \
            "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) stable"
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io
        curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" \
            -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    else
        log_info "🐋 Docker and Docker Compose are already installed."
    fi
}

# Install Node.js
install_nodejs() {
    log_info "Checking Node.js installation..."
    
    if ! command -v node &> /dev/null; then
        log_info "🟢 Node.js not found. Installing the latest version..."
        curl -fsSL https://deb.nodesource.com/setup_current.x | bash -
        apt-get install -y nodejs
    else
        NODE_VERSION=$(node -v)
        log_info "🟢 Node.js $NODE_VERSION is already installed."
    fi
}

# Install Aztec CLI
install_aztec_cli() {
    log_info "Installing Aztec CLI..."
    
    # Install the CLI safely
    curl -sL https://install.aztec.network | bash
    
    # Add to current PATH
    export PATH="$HOME/.aztec/bin:$PATH"
    
    # Verify installation
    if ! command -v aztec-up &> /dev/null; then
        log_error "❌ Aztec CLI installation failed."
        exit 1
    fi
    
    log_info "Aztec CLI installed successfully."
    
    # Prepare alpha-testnet
    log_info "Preparing alpha-testnet..."
    aztec-up alpha-testnet
}

# Validate RPC URL format
validate_rpc_url() {
    local url="$1"
    local name="$2"
    
    # Basic URL validation
    if [[ ! "$url" =~ ^https?:// ]]; then
        log_warn "$name should start with http:// or https://"
        read -p "Do you want to continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    return 0
}

# Validate private key format
validate_private_key() {
    local key="$1"
    
    # Check if it's a valid hex string of the right length
    if [[ ! "$key" =~ ^0x[0-9a-fA-F]{64}$ ]]; then
        if [[ ! "$key" =~ ^[0-9a-fA-F]{64}$ ]]; then
            log_warn "Private key format may be invalid. Expected 0x prefix followed by 64 hex characters or 64 hex characters."
            read -p "Do you want to continue anyway? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                return 1
            fi
            # Add 0x prefix if missing
            echo "0x$key"
            return 0
        else
            # Add 0x prefix if missing
            log_warn "Adding 0x prefix to private key."
            echo "0x$key"
            return 0
        fi
    fi
    
    echo "$key"
    return 0
}

# Get public IP safely with fallbacks
get_public_ip() {
    local ip
    
    # Try multiple services in case one fails
    for service in "ifconfig.me" "ipinfo.io/ip" "icanhazip.com"; do
        ip=$(curl -s "$service" || echo "")
        if [[ -n "$ip" && "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "$ip"
            return 0
        fi
    done
    
    log_warn "Could not determine public IP, defaulting to 127.0.0.1"
    echo "127.0.0.1"
    return 0
}

# Collect configuration information
collect_config() {
    log_info "Collecting configuration information..."
    
    echo -e "\n📋 Instructions for obtaining RPC URLs:"
    echo "  - L1 Execution Client (EL) RPC URL:"
    echo "    1. Sign up or log in at https://dashboard.alchemy.com/"
    echo "    2. Create a new app for the Sepolia testnet"
    echo "    3. Copy the HTTPS URL (e.g., https://eth-sepolia.g.alchemy.com/v2/<your-key>)"
    echo ""
    echo "  - L1 Consensus (CL) RPC URL:"
    echo "    1. Sign up or log in at https://drpc.org/"
    echo "    2. Create an API key for the Sepolia testnet"
    echo "    3. Copy the HTTPS URL (e.g., https://lb.drpc.org/ogrpc?network=sepolia&dkey=<your-key>)"
    echo ""
    
    # Keep asking until valid input is provided
    while true; do
        read -p "▶️ L1 Execution Client (EL) RPC URL: " ETH_RPC
        if validate_rpc_url "$ETH_RPC" "Execution Client RPC"; then
            break
        fi
    done
    
    while true; do
        read -p "▶️ L1 Consensus (CL) RPC URL: " CONS_RPC
        if validate_rpc_url "$CONS_RPC" "Consensus RPC"; then
            break
        fi
    done
    
    read -p "▶️ Blob Sink URL (press Enter if none): " BLOB_URL
    if [[ -n "$BLOB_URL" ]]; then
        validate_rpc_url "$BLOB_URL" "Blob Sink" || BLOB_URL=""
    fi
    
    while true; do
        read -p "▶️ Validator Private Key: " VALIDATOR_PRIVATE_KEY
        VALIDATOR_PRIVATE_KEY=$(validate_private_key "$VALIDATOR_PRIVATE_KEY")
        if [[ $? -eq 0 ]]; then
            break
        fi
    done
    
    read -p "▶️ Custom data directory [$(pwd)/data]: " CUSTOM_DATA_DIR
    if [[ -n "$CUSTOM_DATA_DIR" ]]; then
        DATA_DIR="$CUSTOM_DATA_DIR"
    fi
    
    read -p "▶️ Log level [info]: " CUSTOM_LOG_LEVEL
    if [[ -n "$CUSTOM_LOG_LEVEL" ]]; then
        LOG_LEVEL="$CUSTOM_LOG_LEVEL"
    fi
    
    log_info "Fetching public IP..."
    PUBLIC_IP=$(get_public_ip)
    log_info "Public IP: $PUBLIC_IP"
}

# Create configuration files
create_config_files() {
    log_info "Creating configuration files..."
    
    # Create data directory
    mkdir -p "$DATA_DIR"
    
    # Create .env file (keeping original permission approach)
    cat > .env <<EOF
ETHEREUM_HOSTS="$ETH_RPC"
L1_CONSENSUS_HOST_URLS="$CONS_RPC"
P2P_IP="$PUBLIC_IP"
VALIDATOR_PRIVATE_KEY="$VALIDATOR_PRIVATE_KEY"
DATA_DIRECTORY="$DATA_DIR"
LOG_LEVEL="$LOG_LEVEL"
EOF
    
    if [[ -n "$BLOB_URL" ]]; then
        echo "BLOB_SINK_URL=\"$BLOB_URL\"" >> .env
    fi
    
    # Create docker-compose.yml
    BLOB_FLAG=""
    if [[ -n "$BLOB_URL" ]]; then
        BLOB_FLAG="--sequencer.blobSinkUrl \${BLOB_SINK_URL}"
    fi
    
    cat > docker-compose.yml <<EOF
version: "3.8"
services:
  node:
    image: aztecprotocol/aztec:${AZTEC_VERSION}
    restart: unless-stopped
    network_mode: host
    environment:
      - ETHEREUM_HOSTS=\${ETHEREUM_HOSTS}
      - L1_CONSENSUS_HOST_URLS=\${L1_CONSENSUS_HOST_URLS}
      - P2P_IP=\${P2P_IP}
      - VALIDATOR_PRIVATE_KEY=\${VALIDATOR_PRIVATE_KEY}
      - DATA_DIRECTORY=/data
      - LOG_LEVEL=\${LOG_LEVEL}
      - BLOB_SINK_URL=\${BLOB_SINK_URL:-}
    entrypoint: >
      sh -c 'node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --network ${NETWORK} --node --archiver --sequencer ${BLOB_FLAG}'
    volumes:
      - ${DATA_DIR}:/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/metrics"]
      interval: 30s
      timeout: 5s
      retries: 5
      start_period: 60s
EOF
}

# Start the Aztec node
start_node() {
    log_info "Starting Aztec full node..."
    docker-compose up -d
    
    # Wait for the service to be available
    log_info "Waiting for node to start (this may take a few minutes)..."
    attempt=1
    max_attempts=5
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:8080/metrics &> /dev/null; then
            log_info "✅ Node is running and responding to requests."
            break
        fi
        
        log_info "Waiting for node to become available (attempt $attempt/$max_attempts)..."
        sleep 30
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        log_warn "Node may still be starting. Check logs for more information."
    fi
}

# Display usage information
display_usage() {
    cat <<EOF
Aztec Sequencer Setup Script

Usage:
  $0 [options]

Options:
  --help        Display this help message
  --logs        Show logs after installation
  --data-dir DIR  Specify custom data directory (default: ./data)
  --log-level LVL Set log level (default: info)

EOF
}

# Parse command line arguments
parse_arguments() {
    SHOW_LOGS=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help)
                display_usage
                exit 0
                ;;
            --logs)
                SHOW_LOGS=true
                shift
                ;;
            --data-dir)
                DATA_DIR="$2"
                shift 2
                ;;
            --log-level)
                LOG_LEVEL="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                display_usage
                exit 1
                ;;
        esac
    done
}

# Show node status and information
show_status() {
    log_info "Aztec node status:"
    
    # Show container status
    docker-compose ps
    
    # Show helpful commands
    echo -e "\n✅ Installation and startup completed!"
    echo "   - Check logs:        docker-compose logs -f"
    echo "   - Stop the node:     docker-compose down"
    echo "   - Node metrics:      http://localhost:8080/metrics"
    echo "   - Data directory:    $DATA_DIR"
    
    # Show logs if requested
    if [[ "$SHOW_LOGS" == true ]]; then
        log_info "Showing logs (press Ctrl+C to exit)..."
        docker-compose logs -f
    fi
}

# Main function
main() {
    # Parse command line arguments
    parse_arguments "$@"
    
    print_banner
    check_permissions
    install_docker
    install_nodejs
    install_aztec_cli
    collect_config
    create_config_files
    start_node
    show_status
}

# Execute main function
main "$@"