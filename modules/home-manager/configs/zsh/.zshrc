if [ -z "${WAYLAND_DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
    exec Hyprland
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

setopt autocd extendedglob notify
bindkey -e
# End of lines configured by zsh-newuser-install

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh || echo "Error: Failed to load p10k config"

# Load custom secrets
[[ -f ~/.secrets.zsh ]] && source ~/.secrets.zsh

PATH=/home/fractal-tess/nixos/scripts:$PATH

# pnpm
export PNPM_HOME="/home/fractal-tess/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Function to set up and copy Nix development shell files
function _ncs_setup() {
  local lang="$1"
  if [ -d "$HOME/nixos/shells/$lang" ]; then
    cp -r "$HOME/nixos/shells/$lang/"* "$PWD"
    echo "use flake" > ".envrc"
    if [ -d .git ]; then
      git add flake.lock flake.nix .envrc
      direnv allow
    fi
    echo "Direnv for $lang has been set up. Happy coding!"
  else
    echo "No development shell found for $lang"
  fi
}


if [[ -n $CURSOR_TRACE_ID ]]; then
  PROMPT_EOL_MARK=""
  test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
  precmd() { print -Pn "\e]133;D;%?\a" }
  preexec() { print -Pn "\e]133;C;\a" }
fi

#Aliases
alias p10k-down='prompt_powerlevel9k_teardown'
alias p10k-up='prompt_powerlevel9k_setup'
alias ca='cursor-agent'
alias zai='~/nixos/scripts/claude-code/z-ai.sh'

# ppwn function that changes directory after running the script
ppwn() {
    local executable="$1"
    if [ $# -lt 1 ]; then
        echo "Usage: ppwn <executable>"
        return 1
    fi

    # Check if the executable exists
    if [ ! -f "$executable" ]; then
        echo "Error: File '$executable' does not exist"
        return 1
    fi

    # Get the executable name
    local executable_name=$(basename "$executable")

    # Prompt user for folder name, default to executable name
    read -p "Enter folder name (default: $executable_name): " folder_name

    # Use default if user didn't enter anything
    if [ -z "$folder_name" ]; then
        folder_name="$executable_name"
    fi

    # Create the target directory
    local target_dir="$HOME/dev/ctfs/ppwn/$folder_name"
    mkdir -p "$target_dir"

    # Move the executable to the target directory
    mv "$executable" "$target_dir/"

    # Make it executable
    chmod +x "$target_dir/$executable_name"

    # Fix binary for NixOS compatibility
    echo "Fixing binary for NixOS compatibility..."

    # Check file type
    file_type=$(file "$target_dir/$executable_name")

    if echo "$file_type" | grep -q "ELF"; then
        # Handle ELF binaries
        if command -v patchelf >/dev/null 2>&1; then
            # Get current interpreter
            current_interpreter=$(patchelf --print-interpreter "$target_dir/$executable_name" 2>/dev/null)

            if [ $? -eq 0 ] && [ -n "$current_interpreter" ]; then
                # Get NixOS glibc path
                nixos_glibc=$(find /nix/store -name "ld-linux-x86-64.so.2" 2>/dev/null | head -1)
                if [ -n "$nixos_glibc" ]; then
                    nixos_interpreter=$(dirname "$nixos_glibc")/ld-linux-x86-64.so.2
                    patchelf --set-interpreter "$nixos_interpreter" "$target_dir/$executable_name"
                    echo "✅ ELF binary interpreter fixed for NixOS"
                else
                    echo "⚠️  Could not find NixOS glibc, skipping ELF interpreter fix"
                fi
            else
                echo "ℹ️  ELF binary does not need interpreter fixing"
            fi
        else
            echo "⚠️  patchelf not found, skipping ELF binary compatibility fix"
        fi
    elif echo "$file_type" | grep -q "shell script"; then
        # Handle shell scripts
        if grep -q "^#!/bin/bash" "$target_dir/$executable_name"; then
            sed -i "s|#!/bin/bash|#!/run/current-system/sw/bin/bash|" "$target_dir/$executable_name"
            echo "✅ Shell script shebang fixed for NixOS"
        elif grep -q "^#!/usr/bin/env bash" "$target_dir/$executable_name"; then
            echo "✅ Shell script shebang already compatible with NixOS"
        fi
    else
        echo "ℹ️  Unknown file type, skipping compatibility fixes"
    fi

    echo "Successfully moved '$executable' to '$target_dir/$executable_name'"
    echo "You can now run it with: $target_dir/$executable_name"

    # Create flag.txt file
    echo "Creating flag.txt..."
    echo "FT{EXAMPLE_FLAG}" > "$target_dir/flag.txt"
    echo "flag.txt created: $target_dir/flag.txt"

    
    # Create analysis directory
    analysis_dir="$target_dir/analysis"
    mkdir -p "$analysis_dir"

    # Run security analysis on the binary
    echo "Running security analysis..."

    # Run file command and save output
    echo "Running file analysis..."
    file "$target_dir/$executable_name" > "$analysis_dir/file_info.txt" 2>&1
    echo "file output saved to: $analysis_dir/file_info.txt"

    # Run checksec and save output
    echo "Running checksec..."
    checksec --file="$target_dir/$executable_name" > "$analysis_dir/checksec.txt" 2>&1
    echo "checksec output saved to: $analysis_dir/checksec.txt"

    # Run strings and save output
    echo "Running strings analysis..."
    strings "$target_dir/$executable_name" > "$analysis_dir/strings.txt" 2>&1
    echo "strings output saved to: $analysis_dir/strings.txt"

    # Run objdump disassembly analysis
    echo "Running objdump disassembly analysis..."
    # Disassemble all sections
    objdump -D "$target_dir/$executable_name" > "$analysis_dir/objdump_full.txt" 2>&1
    echo "objdump full disassembly saved to: $analysis_dir/objdump_full.txt"

    # Disassemble specific common sections
    for section in .text .data .bss .rodata .got .plt; do
        echo "Disassembling section: $section"
        objdump -j "$section" -d "$target_dir/$executable_name" > "$analysis_dir/objdump_${section#.}.txt" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "objdump $section section saved to: $analysis_dir/objdump_${section#.}.txt"
        fi
    done

    # Get section headers information
    objdump -h "$target_dir/$executable_name" > "$analysis_dir/objdump_sections.txt" 2>&1
    echo "objdump section headers saved to: $analysis_dir/objdump_sections.txt"

    echo "objdump analysis completed."

    # Run pwntools analysis
    echo "Running pwntools analysis..."
    python3 /home/fractal-tess/nixos/scripts/pwn_analyze.py "$target_dir/$executable_name" "$analysis_dir"
    echo "pwntools analysis completed."

    # Run vulnerability quick scan
    echo "Running vulnerability quick scan..."
    python3 /home/fractal-tess/nixos/scripts/vuln_scan.py "$target_dir/$executable_name" "$analysis_dir"
    echo "vulnerability scan completed."

    # Create exploit.py template
    echo "Creating exploit.py template..."
    cat > "$target_dir/exploit.py" << EOF
#!/usr/bin/env python3
from pwn import *

# ===== SETUP =====
binary = './$executable_name'        # Your binary here
host = '127.0.0.1'        # Remote host
port = 1337               # Remote port

context.binary = binary
context.log_level = 'info'

# ===== CONNECTION =====
if args.REMOTE:
    io = remote(host, port)
elif args.GDB:
    io = gdb.debug(binary, '''
        break main
        continue
    ''')
else:
    io = process(binary)

# ===== EXPLOIT =====

# Receive data
io.recvuntil(b'prompt: ')

# Send payload
payload = b'A' * 100
io.sendline(payload)

# Get shell
io.interactive()

# ===== RUN IT =====
# python exploit.py          → local
# python exploit.py REMOTE   → remote
# python exploit.py GDB      → debug
EOF
    chmod +x "$target_dir/exploit.py"
    echo "exploit.py template created: $target_dir/exploit.py"

    echo "Security analysis completed."

    # Change to the target directory
    cd "$target_dir"

    echo "Changed directory to: $target_dir"
}

#End
if [[ -n $CURSOR_TRACE_ID ]]; then
  p10k-down
fi
