#!/bin/bash

# 🌍 Universal Tunnel - Expose Any Local Backend to Internet
# Works with any local URL: localhost:8000, omar.localhost:3000, 127.0.0.1:5000, etc.

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"
LOGS_DIR="$SCRIPT_DIR/logs"
CONFIG_FILE="$SCRIPT_DIR/tunnel.config"

# Default settings
DEFAULT_URL="http://localhost:8000"
CLOUDFLARED_BIN="$BIN_DIR/cloudflared"
LOG_FILE="$LOGS_DIR/tunnel.log"
PID_FILE="$LOGS_DIR/tunnel.pid"
URL_FILE="$LOGS_DIR/public_url.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Create required directories
mkdir -p "$BIN_DIR" "$LOGS_DIR"

# Logging functions
log() { echo -e "${GREEN}✅${NC} $1"; }
error() { echo -e "${RED}❌ ERROR:${NC} $1"; }
warn() { echo -e "${YELLOW}⚠️  WARNING:${NC} $1"; }
info() { echo -e "${BLUE}ℹ️  INFO:${NC} $1"; }
success() { echo -e "${PURPLE}🎉 SUCCESS:${NC} $1"; }

# Show banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    🌍 UNIVERSAL TUNNEL                         ║"
    echo "║              Expose Any Local Backend to Internet              ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Parse URL and validate
validate_url() {
    local url="$1"
    
    # Add protocol if missing
    if [[ ! "$url" =~ ^https?:// ]]; then
        url="http://$url"
    fi
    
    # Extract host and port
    local host=$(echo "$url" | sed -E 's/^https?:\/\/([^:\/]+).*/\1/')
    local port=$(echo "$url" | sed -E 's/^https?:\/\/[^:]+:?([0-9]+)?.*/\1/')
    
    # Default port based on protocol
    if [[ -z "$port" ]]; then
        if [[ "$url" =~ ^https:// ]]; then
            port=443
        else
            port=80
        fi
    fi
    
    echo "$url"
}

# Test if URL is accessible
test_backend() {
    local url="$1"
    local timeout="${2:-5}"
    
    info "Testing backend: $url"
    
    if curl -s --connect-timeout "$timeout" --max-time "$timeout" "$url" > /dev/null 2>&1; then
        log "Backend is accessible"
        return 0
    else
        error "Backend is not accessible at $url"
        return 1
    fi
}

# Auto-detect common local backends
auto_detect_backend() {
    local common_urls=(
        "http://localhost:8000"
        "http://localhost:3000" 
        "http://localhost:5000"
        "http://localhost:8080"
        "http://omar.localhost:8000"
        "http://127.0.0.1:8000"
        "http://127.0.0.1:3000"
        "http://127.0.0.1:5000"
    )
    
    info "Auto-detecting running backends..."
    
    for url in "${common_urls[@]}"; do
        if curl -s --connect-timeout 2 "$url" > /dev/null 2>&1; then
            log "Found running backend: $url"
            echo "$url"
            return 0
        fi
    done
    
    warn "No running backends detected on common ports"
    return 1
}

# Install cloudflared if not present
install_cloudflared() {
    if [[ -f "$CLOUDFLARED_BIN" ]]; then
        log "Cloudflared already installed"
        return 0
    fi
    
    info "Installing Cloudflared..."
    
    local download_url
    case "$(uname -m)" in
        x86_64) download_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64" ;;
        aarch64|arm64) download_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64" ;;
        armv7l) download_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm" ;;
        *) error "Unsupported architecture: $(uname -m)"; return 1 ;;
    esac
    
    if curl -L "$download_url" -o "$CLOUDFLARED_BIN" && chmod +x "$CLOUDFLARED_BIN"; then
        log "Cloudflared installed successfully"
        return 0
    else
        error "Failed to install Cloudflared"
        return 1
    fi
}

# Start tunnel
start_tunnel() {
    local target_url="$1"
    
    # Validate target URL
    target_url=$(validate_url "$target_url")
    
    # Test backend accessibility
    if ! test_backend "$target_url"; then
        error "Cannot start tunnel - backend not accessible"
        return 1
    fi
    
    # Check if tunnel is already running
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
        warn "Tunnel is already running"
        get_public_url
        return 0
    fi
    
    # Install cloudflared if needed
    if ! install_cloudflared; then
        error "Cannot install required tools"
        return 1
    fi
    
    # Clean up old files
    rm -f "$PID_FILE" "$URL_FILE"
    
    info "Starting tunnel for: $target_url"
    
    # Start tunnel in background
    nohup "$CLOUDFLARED_BIN" tunnel --url "$target_url" > "$LOG_FILE" 2>&1 &
    local tunnel_pid=$!
    echo "$tunnel_pid" > "$PID_FILE"
    
    # Wait for tunnel to initialize
    info "Initializing tunnel (this may take 10-15 seconds)..."
    
    local attempts=0
    local max_attempts=20
    
    while [[ $attempts -lt $max_attempts ]]; do
        if [[ ! -f "$PID_FILE" ]] || ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            error "Tunnel process died during startup"
            return 1
        fi
        
        # Check for public URL in logs
        if grep -q "trycloudflare.com" "$LOG_FILE" 2>/dev/null; then
            local public_url=$(grep -o "https://[^[:space:]]*\.trycloudflare\.com" "$LOG_FILE" | tail -1)
            if [[ -n "$public_url" ]]; then
                echo "$public_url" > "$URL_FILE"
                echo "$target_url" > "$CONFIG_FILE"
                
                success "Tunnel created successfully!"
                echo
                echo "═══════════════════════════════════════════════════════════════"
                echo -e "${GREEN}🌐 LOCAL URL:${NC}  $target_url"
                echo -e "${PURPLE}🚀 PUBLIC URL:${NC} $public_url"
                echo "═══════════════════════════════════════════════════════════════"
                echo
                echo -e "${CYAN}📋 Next Steps:${NC}"
                echo "1. 🔗 Use public URL in Retool, webhooks, or share with team"
                echo "2. 🧪 Test your endpoints by adding paths to the public URL"  
                echo "3. 📊 Monitor: $0 status"
                echo "4. 🛑 Stop: $0 stop"
                echo
                
                # Test the public URL
                info "Testing public URL accessibility..."
                if curl -s --connect-timeout 10 "$public_url" > /dev/null 2>&1; then
                    log "Public URL is accessible and working!"
                else
                    warn "Public URL created but may take a moment to become accessible"
                fi
                
                return 0
            fi
        fi
        
        echo -n "."
        sleep 1
        attempts=$((attempts + 1))
    done
    
    error "Tunnel failed to start within ${max_attempts} seconds"
    stop_tunnel
    return 1
}

# Stop tunnel
stop_tunnel() {
    info "Stopping tunnel..."
    
    local stopped=0
    
    # Kill by PID if available
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill "$pid" 2>/dev/null; then
            log "Stopped tunnel process (PID: $pid)"
            stopped=1
        fi
        rm -f "$PID_FILE"
    fi
    
    # Kill any remaining cloudflared processes
    if pkill -f "cloudflared.*tunnel" 2>/dev/null; then
        log "Stopped additional tunnel processes"
        stopped=1
    fi
    
    # Clean up files
    rm -f "$URL_FILE" "$CONFIG_FILE"
    
    if [[ $stopped -eq 1 ]]; then
        log "Tunnel stopped successfully"
    else
        warn "No tunnel processes found"
    fi
}

# Get public URL
get_public_url() {
    if [[ -f "$URL_FILE" ]]; then
        local public_url=$(cat "$URL_FILE")
        local local_url=$(cat "$CONFIG_FILE" 2>/dev/null || echo "Unknown")
        
        echo "═══════════════════════════════════════════════════════════════"
        echo -e "${GREEN}🌐 LOCAL URL:${NC}  $local_url"
        echo -e "${PURPLE}🚀 PUBLIC URL:${NC} $public_url"
        echo "═══════════════════════════════════════════════════════════════"
        
        # Test accessibility
        if curl -s --connect-timeout 5 "$public_url" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Status: Accessible${NC}"
        else
            echo -e "${RED}❌ Status: Not accessible${NC}"
        fi
    else
        error "No active tunnel found"
        return 1
    fi
}

# Show status
show_status() {
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${CYAN}📊 TUNNEL STATUS${NC}"
    echo "═══════════════════════════════════════════════════════════════"
    
    # Check tunnel process
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
        local pid=$(cat "$PID_FILE")
        local uptime=$(ps -o etime= -p "$pid" 2>/dev/null | xargs || echo "Unknown")
        echo -e "${GREEN}🔧 Tunnel Process:${NC} Running (PID: $pid, Uptime: $uptime)"
        
        if [[ -f "$CONFIG_FILE" ]]; then
            local local_url=$(cat "$CONFIG_FILE")
            if curl -s --connect-timeout 3 "$local_url" > /dev/null 2>&1; then
                echo -e "${GREEN}🏠 Local Backend:${NC} Accessible ($local_url)"
            else
                echo -e "${RED}🏠 Local Backend:${NC} Not accessible ($local_url)"
            fi
        fi
        
        get_public_url
    else
        echo -e "${RED}🔧 Tunnel Process:${NC} Not running"
        echo -e "${RED}🚀 Public URL:${NC} No active tunnel"
    fi
    
    echo "═══════════════════════════════════════════════════════════════"
}

# Show help
show_help() {
    echo -e "${CYAN}🌍 Universal Tunnel - Usage Guide${NC}"
    echo
    echo -e "${YELLOW}USAGE:${NC}"
    echo "  $0 [COMMAND] [URL]"
    echo
    echo -e "${YELLOW}COMMANDS:${NC}"
    echo "  start [URL]    Start tunnel (auto-detects if no URL provided)"
    echo "  stop           Stop tunnel"
    echo "  status         Show tunnel status"
    echo "  url            Show public URL"
    echo "  restart [URL]  Restart tunnel"
    echo "  logs           Show tunnel logs"
    echo "  help           Show this help"
    echo
    echo -e "${YELLOW}EXAMPLES:${NC}"
    echo "  $0 start                          # Auto-detect running backend"
    echo "  $0 start localhost:8000           # Tunnel localhost:8000"
    echo "  $0 start omar.localhost:3000      # Tunnel custom domain"
    echo "  $0 start 127.0.0.1:5000          # Tunnel specific IP"
    echo "  $0 start http://localhost:8080    # Tunnel with protocol"
    echo
    echo -e "${YELLOW}SUPPORTED FORMATS:${NC}"
    echo "  • localhost:PORT"
    echo "  • 127.0.0.1:PORT" 
    echo "  • custom.localhost:PORT"
    echo "  • http://domain:PORT"
    echo "  • https://domain:PORT"
}

# Show logs
show_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        echo -e "${CYAN}📄 Tunnel Logs:${NC}"
        echo "═══════════════════════════════════════════════════════════════"
        tail -20 "$LOG_FILE"
        echo "═══════════════════════════════════════════════════════════════"
        echo -e "${BLUE}ℹ️  Full logs: $LOG_FILE${NC}"
    else
        warn "No log file found"
    fi
}

# Main script
main() {
    show_banner
    
    local command="${1:-start}"
    local url="$2"
    
    case "$command" in
        "start")
            if [[ -z "$url" ]]; then
                # Auto-detect backend
                if url=$(auto_detect_backend); then
                    info "Using auto-detected backend: $url"
                else
                    warn "No backend auto-detected, using default: $DEFAULT_URL"
                    url="$DEFAULT_URL"
                fi
            fi
            start_tunnel "$url"
            ;;
        "stop")
            stop_tunnel
            ;;
        "restart")
            stop_tunnel
            sleep 2
            if [[ -z "$url" ]]; then
                if [[ -f "$CONFIG_FILE" ]]; then
                    url=$(cat "$CONFIG_FILE")
                    info "Restarting with previous URL: $url"
                else
                    url="$DEFAULT_URL"
                fi
            fi
            start_tunnel "$url"
            ;;
        "status")
            show_status
            ;;
        "url")
            get_public_url
            ;;
        "logs")
            show_logs
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            error "Unknown command: $command"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"