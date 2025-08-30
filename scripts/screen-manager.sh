# Comprehensive screen and session management script
# Combines screen control, session locking, and brightness management
# Includes caching system for fast brightness operations

# Configuration
BRIGHTNESS_CACHE_FILE="/tmp/brightness-cache"
BRIGHTNESS_METHOD_CACHE_FILE="/tmp/brightness-method-cache"
BRIGHTNESS_STEP=10

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

# ============================================================================
# BRIGHTNESS MANAGEMENT FUNCTIONS
# ============================================================================

# Detect available brightness control method (with caching)
detect_brightness_method() {
    # Check cache first
    if [[ -f "$BRIGHTNESS_METHOD_CACHE_FILE" ]]; then
        local cached_method=$(cat "$BRIGHTNESS_METHOD_CACHE_FILE" 2>/dev/null)
        if [[ "$cached_method" =~ ^(brightnessctl|light|ddcutil|none)$ ]]; then
            echo "$cached_method"
            return
        fi
    fi
    
    # If not in cache, detect and cache the result
    local method="none"
    
    # Check for laptop brightness controls first
    if command -v brightnessctl >/dev/null 2>&1 && [[ -d /sys/class/backlight ]]; then
        method="brightnessctl"
    elif command -v light >/dev/null 2>&1 && [[ -d /sys/class/backlight ]]; then
        method="light"  
    elif command -v ddcutil >/dev/null 2>&1; then
        # Check if ddcutil can detect any monitors (only once during detection)
        if ddcutil detect >/dev/null 2>&1; then
            method="ddcutil"
        else
            method="none"
        fi
    fi
    
    # Cache the result
    echo "$method" > "$BRIGHTNESS_METHOD_CACHE_FILE"
    echo "$method"
}

# Initialize brightness cache if it doesn't exist
init_brightness_cache() {
    if [[ ! -f "$BRIGHTNESS_CACHE_FILE" ]]; then
        local method=$(detect_brightness_method)
        local initial_brightness=50  # default fallback
        
        case "$method" in
            "brightnessctl")
                local current=$(brightnessctl get 2>/dev/null)
                local max=$(brightnessctl max 2>/dev/null)
                if [[ -n "$current" && -n "$max" && $max -gt 0 ]]; then
                    initial_brightness=$((current * 100 / max))
                fi
                ;;
            "light")
                local current=$(light -G 2>/dev/null | cut -d. -f1)
                if [[ -n "$current" && "$current" =~ ^[0-9]+$ ]]; then
                    initial_brightness=$current
                fi
                ;;
            "ddcutil")
                # Only query once on initialization to avoid lag
                # Use cached buses from method detection to avoid another detect call
                local buses=$(ddcutil detect 2>/dev/null | grep 'I2C bus' | awk '{print $3}' | sed 's/.*-//g')
                if [[ -n "$buses" ]]; then
                    local bus=$(echo "$buses" | head -1)  # Use first bus
                    local ddcutil_output=$(ddcutil --bus "$bus" getvcp 10 2>/dev/null)
                    local current=$(echo "$ddcutil_output" | grep -oP 'current value =\s*\K\d+' | head -1)
                    if [[ -n "$current" && "$current" =~ ^[0-9]+$ ]]; then
                        initial_brightness=$current
                    fi
                fi
                ;;
        esac
        
        echo "$initial_brightness" > "$BRIGHTNESS_CACHE_FILE"
    fi
}

# Get current brightness from cache
get_brightness() {
    init_brightness_cache
    
    if [[ -f "$BRIGHTNESS_CACHE_FILE" ]]; then
        local cached_value=$(cat "$BRIGHTNESS_CACHE_FILE" 2>/dev/null)
        if [[ "$cached_value" =~ ^[0-9]+$ ]] && (( cached_value >= 0 && cached_value <= 100 )); then
            echo "$cached_value"
            return
        fi
    fi
    
    # Fallback if cache is corrupted or missing
    echo "50"
}

# Set brightness with cache update (for responsive UI)
set_brightness_cached() {
    local value=$1
    local method=$(detect_brightness_method)

    # Ensure value is within bounds
    if (( value < 0 )); then value=0; fi
    if (( value > 100 )); then value=100; fi

    # Update cache first for immediate feedback
    echo "$value" > "$BRIGHTNESS_CACHE_FILE"

    # Set actual brightness in background to avoid lag
    case "$method" in
        "brightnessctl")
            brightnessctl set "${value}%" >/dev/null 2>&1 &
            ;;
        "light")
            light -S "$value" >/dev/null 2>&1 &
            ;;
        "ddcutil")
            # Set brightness on all detected monitors in background
            # Use cached buses to avoid detect call
            {
                # Get buses from cache or detect once
                local buses_cache="/tmp/ddcutil-buses-cache"
                local buses=""
                
                if [[ -f "$buses_cache" ]]; then
                    buses=$(cat "$buses_cache" 2>/dev/null)
                else
                    buses=$(ddcutil detect 2>/dev/null | grep 'I2C bus' | awk '{print $3}' | sed 's/.*-//g')
                    echo "$buses" > "$buses_cache"
                fi
                
                for bus in $buses; do
                    ddcutil --bus "$bus" --sleep-multiplier .1 setvcp 10 "$value" 2>/dev/null
                done
            } &
            ;;
        *)
            print_warning "No brightness control method available"
            return 1
            ;;
    esac
    
    return 0
}

# Set brightness directly without cache (for compatibility)
set_brightness_direct() {
    local value=$1
    
    # Ensure value is within bounds
    if (( value < 0 )); then value=0; fi
    if (( value > 100 )); then value=100; fi
    
    # Direct brightness setting (original brightness.sh behavior)
    for bus in $(ddcutil detect 2>/dev/null | grep 'I2C bus' | awk '{print $3}' | sed 's/.*-//g'); do
        ddcutil --bus "$bus" setvcp 10 "$value" 2>/dev/null
    done
}

# Output JSON for waybar (optimized for frequent calls)
output_brightness_json() {
    # Only read from cache, never call ddcutil
    local brightness=$(get_brightness)
    
    # Get method from cache to avoid detection calls
    local method="none"
    if [[ -f "$BRIGHTNESS_METHOD_CACHE_FILE" ]]; then
        method=$(cat "$BRIGHTNESS_METHOD_CACHE_FILE" 2>/dev/null)
    fi
    
    local method_text=""
    case "$method" in
        "brightnessctl") method_text=" (brightnessctl)" ;;
        "light") method_text=" (light)" ;;
        "ddcutil") method_text=" (ddcutil)" ;;
        "none") method_text=" (no control)" ;;
    esac

    local tooltip="Brightness: ${brightness}%${method_text}\\rScroll: adjust brightness\\rLeft click: turn screens off\\rRight click: set to 100%"

    # Output single-line JSON for waybar
    printf '{"percentage": %d, "text": "☀ %d%%", "tooltip": "%s", "class": "brightness"}\n' "$brightness" "$brightness" "$tooltip"
}

# ============================================================================
# SCREEN MANAGEMENT FUNCTIONS
# ============================================================================

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

# Legacy brightness function (now uses cached version)
set_brightness() {
    local brightness="$1"
    
    if [ -z "$brightness" ]; then
        print_error "Brightness value required"
        return 1
    fi
    
    print_status "Setting brightness to $brightness%"
    
    if set_brightness_cached "$brightness"; then
        print_success "Brightness set successfully"
        return 0
    else
        print_error "Failed to set brightness"
        return 1
    fi
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
    local brightness=$(get_brightness)
    local method=$(detect_brightness_method)
    echo "Brightness: ${brightness}% (${method})"
}

# Function to show help
show_help() {
    echo "Unified Screen and Brightness Manager"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "SCREEN COMMANDS:"
    echo "  off, off-screen     Turn screen off"
    echo "  on, on-screen       Turn screen on"
    echo "  toggle              Toggle screen on/off"
    echo ""
    echo "SESSION COMMANDS:"
    echo "  lock                Lock current session"
    echo "  unlock              Unlock current session"
    echo "  lock-toggle         Toggle session lock state"
    echo ""
    echo "BRIGHTNESS COMMANDS:"
    echo "  brightness <0-100>  Set brightness to percentage (legacy)"
    echo "  bright-get          Get current brightness percentage (from cache)"
    echo "  bright-set <0-100>  Set brightness to specific percentage"
    echo "  bright-up [step]    Increase brightness (default: ${BRIGHTNESS_STEP}%)"
    echo "  bright-down [step]  Decrease brightness (default: ${BRIGHTNESS_STEP}%)"
    echo "  bright-json         Output JSON format for waybar"
    echo "  <0-100>             Set brightness directly (brightness.sh compatibility)"
    echo ""
    echo "UTILITY COMMANDS:"
    echo "  status              Show current status"
    echo "  help                Show this help message"
    echo ""
    echo "EXAMPLES:"
    echo "  $0 off              # Turn screen off"
    echo "  $0 bright-set 75    # Set brightness to 75%"
    echo "  $0 bright-up        # Increase brightness by ${BRIGHTNESS_STEP}%"
    echo "  $0 bright-up 20     # Increase brightness by 20%"
    echo "  $0 75               # Set brightness to 75% (direct)"
    echo "  $0 bright-json      # Output JSON for waybar"
    echo "  $0 status           # Show system status"
}

# Main script logic
main() {
    local action="${1:-help}"
    local value="$2"
    
    case "$action" in
        # Screen management commands
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
        # Session management commands
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
        # Brightness management commands
        "bright-get")
            get_brightness
            ;;
        "bright-set")
            if [[ -z "$value" ]]; then
                print_error "bright-set command requires a percentage argument (0-100)"
                exit 1
            fi
            if ! [[ "$value" =~ ^[0-9]+$ ]] || (( value < 0 || value > 100 )); then
                print_error "Brightness percentage must be a number between 0-100"
                exit 1
            fi
            set_brightness_cached "$value"
            print_success "Brightness set to ${value}%"
            ;;
        "bright-up")
            local current=$(get_brightness)
            local step="${value:-$BRIGHTNESS_STEP}"
            if ! [[ "$step" =~ ^[0-9]+$ ]] || (( step < 1 || step > 100 )); then
                print_error "Step must be a number between 1-100"
                exit 1
            fi
            local new_brightness=$((current + step))
            # Clamp the value before setting
            if (( new_brightness > 100 )); then new_brightness=100; fi
            set_brightness_cached $new_brightness
            print_success "Brightness increased by ${step}% (${current}% → ${new_brightness}%)"
            ;;
        "bright-down")
            local current=$(get_brightness)
            local step="${value:-$BRIGHTNESS_STEP}"
            if ! [[ "$step" =~ ^[0-9]+$ ]] || (( step < 1 || step > 100 )); then
                print_error "Step must be a number between 1-100"
                exit 1
            fi
            local new_brightness=$((current - step))
            # Clamp the value before setting
            if (( new_brightness < 0 )); then new_brightness=0; fi
            set_brightness_cached $new_brightness
            print_success "Brightness decreased by ${step}% (${current}% → ${new_brightness}%)"
            ;;
        "bright-json")
            output_brightness_json
            ;;
        "brightness")
            # Legacy brightness command
            set_brightness "$value"
            ;;
        # Utility commands
        "status")
            show_status
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            # Check if first argument is a number (brightness.sh compatibility)
            if [[ "$action" =~ ^[0-9]+$ ]] && (( action >= 0 && action <= 100 )); then
                # Legacy brightness.sh mode - set brightness directly without cache
                set_brightness_direct "$action"
            else
                print_error "Unknown command: $action"
                show_help
                exit 1
            fi
            ;;
    esac
}

# Run main function with all arguments
main "$@" 
