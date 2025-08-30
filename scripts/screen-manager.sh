# Comprehensive screen and session management script
# Combines screen control, session locking, and brightness management

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to get Hyprland instance signature
get_hyprland_signature() {
    local hyprland_runtime_dir="$XDG_RUNTIME_DIR/hypr"
    if [ -d "$hyprland_runtime_dir" ]; then
        local instance_signature=$(basename "$(find "$hyprland_runtime_dir" -maxdepth 1 -type d | head -1)")
        
        if [ -n "$instance_signature" ] && [ "$instance_signature" != "hypr" ]; then
            echo "$instance_signature"
            return 0
        fi
    fi
    return 1
}

# Function to get active session ID
get_active_session() {
    loginctl list-sessions --no-legend | grep "seat0" | awk '{print $1}'
}

# Function to check if session is locked
is_session_locked() {
    local session_id="$1"
    local locked_status=$(loginctl show-session "$session_id" | grep "LockedHint" | cut -d'=' -f2)
    [ "$locked_status" = "yes" ]
}

# Function to turn screen off using hyprctl
screen_off_hyprctl() {
    local hyprland_runtime_dir="$XDG_RUNTIME_DIR/hypr"
    
    if [ -d $hyprland_runtime_dir ]; then
        # Iterate through all Hyprland instance signatures
        for instance_signature in "$hyprland_runtime_dir"/*; do
            if [ -d "$instance_signature" ]; then
                instance_signature=$(basename "$instance_signature")
                print_status "Trying Hyprland instance: $instance_signature"
                export HYPRLAND_INSTANCE_SIGNATURE="$instance_signature"
                
                if hyprctl dispatch dpms off 2>/dev/null; then
                    print_success "Screen turned off via hyprctl (instance: $instance_signature)"
                    return 0
                fi
            fi
        done
    fi
    
    print_warning "No valid Hyprland instances found or failed to turn off screen via hyprctl"
    return 1
}

# Function to turn screen on using hyprctl
screen_on_hyprctl() {
    local hyprland_runtime_dir="$XDG_RUNTIME_DIR/hypr"
    
    if [ -d "$hyprland_runtime_dir" ]; then
        # Iterate through all Hyprland instance signatures
        for instance_signature in "$hyprland_runtime_dir"/*; do
            if [ -d "$instance_signature" ]; then
                instance_signature=$(basename "$instance_signature")
                
                # Skip if it's not a valid instance signature (should be alphanumeric)
                if [[ "$instance_signature" =~ ^[a-zA-Z0-9]+$ ]]; then
                    print_status "Trying Hyprland instance: $instance_signature"
                    export HYPRLAND_INSTANCE_SIGNATURE="$instance_signature"
                    
                    if hyprctl dispatch dpms on 2>/dev/null; then
                        print_success "Screen turned on via hyprctl (instance: $instance_signature)"
                        return 0
                    fi
                fi
            fi
        done
    fi
    
    print_warning "No valid Hyprland instances found or failed to turn on screen via hyprctl"
    return 1
}

# Function to turn screen off using alternative methods
screen_off_alternative() {
    print_status "Trying alternative methods to turn off screen..."
    
    # Method 1: ddcutil
    if command -v ddcutil >/dev/null 2>&1; then
        if ddcutil setvcp 10 0; then
            print_success "Screen turned off via ddcutil"
            return 0
        fi
    fi
    
    # Method 2: brightnessctl
    if command -v brightnessctl >/dev/null 2>&1; then
        if brightnessctl set 0; then
            print_success "Screen turned off via brightnessctl"
            return 0
        fi
    fi
    
    # Method 3: light
    if command -v light >/dev/null 2>&1; then
        if light -S 0; then
            print_success "Screen turned off via light"
            return 0
        fi
    fi
    
    # Method 4: xset (for X11 compatibility)
    if command -v xset >/dev/null 2>&1; then
        if xset dpms force off; then
            print_success "Screen turned off via xset"
            return 0
        fi
    fi
    
    print_error "All alternative methods failed to turn off screen"
    return 1
}

# Function to turn screen on using alternative methods
screen_on_alternative() {
    print_status "Trying alternative methods to turn on screen..."
    
    # Method 1: ddcutil
    if command -v ddcutil >/dev/null 2>&1; then
        if ddcutil setvcp 10 100; then
            print_success "Screen turned on via ddcutil"
            return 0
        fi
    fi
    
    # Method 2: brightnessctl
    if command -v brightnessctl >/dev/null 2>&1; then
        if brightnessctl set 100%; then
            print_success "Screen turned on via brightnessctl"
            return 0
        fi
    fi
    
    # Method 3: light
    if command -v light >/dev/null 2>&1; then
        if light -S 100; then
            print_success "Screen turned on via light"
            return 0
        fi
    fi
    
    # Method 4: xset (for X11 compatibility)
    if command -v xset >/dev/null 2>&1; then
        if xset dpms force on; then
            print_success "Screen turned on via xset"
            return 0
        fi
    fi
    
    print_error "All alternative methods failed to turn on screen"
    return 1
}

# Function to lock session
lock_session() {
    local session_id=$(get_active_session)
    
    if [ -n "$session_id" ]; then
        print_status "Locking session: $session_id"
        if loginctl lock-session "$session_id"; then
            print_success "Session locked successfully"
            return 0
        else
            print_error "Failed to lock session"
            return 1
        fi
    else
        print_error "No active graphical session found"
        return 1
    fi
}

# Function to unlock session
unlock_session() {
    local session_id=$(get_active_session)
    
    if [ -n "$session_id" ]; then
        print_status "Unlocking session: $session_id"
        if loginctl unlock-session "$session_id"; then
            print_success "Session unlocked successfully"
            return 0
        else
            print_error "Failed to unlock session"
            return 1
        fi
    else
        print_error "No active graphical session found"
        return 1
    fi
}

# Function to set brightness
set_brightness() {
    local brightness="$1"
    
    if [ -z "$brightness" ]; then
        print_error "Brightness value required"
        return 1
    fi
    
    print_status "Setting brightness to $brightness%"
    
    # Method 1: Custom brightness script
    if [ -f ~/nixos/scripts/brightness-control.sh ]; then
        if ~/nixos/scripts/brightness-control.sh "$brightness"; then
            print_success "Brightness set via brightness-control script"
            return 0
        fi
    fi
    
    # Method 2: ddcutil
    if command -v ddcutil >/dev/null 2>&1; then
        if ddcutil setvcp 10 "$brightness"; then
            print_success "Brightness set via ddcutil"
            return 0
        fi
    fi
    
    # Method 3: brightnessctl
    if command -v brightnessctl >/dev/null 2>&1; then
        if brightnessctl set "$brightness%"; then
            print_success "Brightness set via brightnessctl"
            return 0
        fi
    fi
    
    # Method 4: light
    if command -v light >/dev/null 2>&1; then
        if light -S "$brightness"; then
            print_success "Brightness set via light"
            return 0
        fi
    fi
    
    print_error "Failed to set brightness"
    return 1
}

# Function to show status
show_status() {
    print_status "=== Screen and Session Status ==="
    
    # Session info
    local session_id=$(get_active_session)
    if [ -n "$session_id" ]; then
        echo "Active Session ID: $session_id"
        echo "Session Locked: $(is_session_locked "$session_id" && echo "Yes" || echo "No")"
        echo "Session State: $(loginctl show-session "$session_id" | grep "State" | cut -d'=' -f2)"
    else
        echo "No active graphical session found"
    fi
    
    # Hyprland info
    local instance_signature=$(get_hyprland_signature)
    if [ -n "$instance_signature" ]; then
        echo "Hyprland Instance: $instance_signature"
        
        # Try to get monitor info
        export HYPRLAND_INSTANCE_SIGNATURE="$instance_signature"
        if hyprctl -j monitors >/dev/null 2>&1; then
            local dpms_status=$(hyprctl -j monitors | jq -r '.[0].dpmsStatus')
            echo "DPMS Status: $( [ "$dpms_status" = "true" ] && echo "ON" || echo "OFF" )"
        fi
    else
        echo "Hyprland not running or instance signature not found"
    fi
    
    # Brightness info
    if command -v brightnessctl >/dev/null 2>&1; then
        local brightness=$(brightnessctl get)
        local max_brightness=$(brightnessctl max)
        local percentage=$((brightness * 100 / max_brightness))
        echo "Brightness: ${percentage}%"
    fi
}

# Function to show help
show_help() {
    echo "Screen and Session Manager"
    echo ""
    echo "Usage: $0 [OPTION] [VALUE]"
    echo ""
    echo "Options:"
    echo "  off, off-screen     Turn screen off"
    echo "  on, on-screen       Turn screen on"
    echo "  toggle              Toggle screen on/off"
    echo "  lock                Lock current session"
    echo "  unlock              Unlock current session"
    echo "  lock-toggle         Toggle session lock state"
    echo "  brightness <0-100>  Set brightness to percentage"
    echo "  status              Show current status"
    echo "  help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 off              # Turn screen off"
    echo "  $0 on               # Turn screen on"
    echo "  $0 lock             # Lock session"
    echo "  $0 brightness 50    # Set brightness to 50%"
    echo "  $0 status           # Show status"
}

# Main script logic
main() {
    local action="${1:-help}"
    local value="$2"
    
    case "$action" in
        "off"|"off-screen")
            print_status "Turning screen off..."
            if ! screen_off_hyprctl; then
                screen_off_alternative
            fi
            ;;
        "on"|"on-screen")
            print_status "Turning screen on..."
            if ! screen_on_hyprctl; then
                screen_on_alternative
            fi
            ;;
        "toggle")
            print_status "Toggling screen..."
            local session_id=$(get_active_session)
            if [ -n "$session_id" ] && is_session_locked "$session_id"; then
                # Session is locked, turn on
                if ! screen_on_hyprctl; then
                    screen_on_alternative
                fi
            else
                # Session is unlocked, turn off
                if ! screen_off_hyprctl; then
                    screen_off_alternative
                fi
            fi
            ;;
        "lock")
            lock_session
            ;;
        "unlock")
            unlock_session
            ;;
        "lock-toggle")
            local session_id=$(get_active_session)
            if [ -n "$session_id" ] && is_session_locked "$session_id"; then
                unlock_session
            else
                lock_session
            fi
            ;;
        "brightness")
            set_brightness "$value"
            ;;
        "status")
            show_status
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            print_error "Unknown action: $action"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 
