#!/usr/bin/env bash
# ==============================================================================
# ZCode Mobile GUI - Installer
# ==============================================================================
# Supports: Android Termux (Host) & PRoot Debian Subsystem
# ==============================================================================

set -e

# ------------------------------------------------------------------------------
# Silent PRoot Transition Check (Before UI or Banner)
# ------------------------------------------------------------------------------
if [ -z "$PREFIX" ] || [ ! -d "/data/data/com.termux/files/usr" ]; then
    # Running inside PRoot container: silently sync repo and hand over to Termux host
    mkdir -p /data/data/com.termux/files/home/ZCode-Mobile 2>/dev/null || true
    touch /data/data/com.termux/files/home/.from_proot_sync 2>/dev/null || true

    # 1. Copy local repo if present on disk
    SCRIPT_PATH="${BASH_SOURCE[0]}"
    if [ -n "$SCRIPT_PATH" ] && [ -f "$SCRIPT_PATH" ]; then
        SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" 2>/dev/null && pwd)"
        if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR" ]; then
            cp -r "$SCRIPT_DIR"/* /data/data/com.termux/files/home/ZCode-Mobile/ 2>/dev/null || true
        fi
    fi

    # 2. If install.sh is still missing (e.g. piped via curl | bash), download directly
    if [ ! -f "/data/data/com.termux/files/home/ZCode-Mobile/install.sh" ]; then
        if command -v curl >/dev/null 2>&1; then
            curl -sL https://raw.githubusercontent.com/zenyxx-xd/ZCode-Mobile/main/install.sh -o /data/data/com.termux/files/home/ZCode-Mobile/install.sh 2>/dev/null || true
        elif command -v wget >/dev/null 2>&1; then
            wget -q https://raw.githubusercontent.com/zenyxx-xd/ZCode-Mobile/main/install.sh -O /data/data/com.termux/files/home/ZCode-Mobile/install.sh 2>/dev/null || true
        fi
    fi
    chmod +x /data/data/com.termux/files/home/ZCode-Mobile/install.sh 2>/dev/null || true

    # Inject command into TTY input queue so Termux host shell executes it immediately
    python3 -c '
import fcntl, termios
cmd = "bash ~/ZCode-Mobile/install.sh\n"
try:
    with open("/dev/tty", "w") as fd:
        for ch in cmd:
            fcntl.ioctl(fd.fileno(), termios.TIOCSTI, ch.encode("utf-8"))
except Exception:
    pass
' 2>/dev/null || true

    # Targeted termination of only the current TTY proot session
    my_tty_nr=$(awk '{print $7}' /proc/self/stat 2>/dev/null || true)
    if [ -n "$my_tty_nr" ]; then
        for p in /proc/[0-9]*/cmdline; do
            pid=$(basename $(dirname "$p") 2>/dev/null)
            if grep -qa "/data/data/com.termux/files/usr/bin/proot" "$p" 2>/dev/null; then
                t_nr=$(awk '{print $7}' "/proc/$pid/stat" 2>/dev/null || true)
                if [ "$t_nr" == "$my_tty_nr" ]; then
                    kill -9 "$pid" 2>/dev/null || true
                    break
                fi
            fi
        done
    fi
    exit 0
fi

INSTALLER_VERSION="1.0.0"

# ANSI Colors
CYAN='\033[38;5;39m'
CYAN_BOLD='\033[1;38;5;39m'
PURPLE_BOLD='\033[1;38;5;141m'
GREEN_BOLD='\033[1;38;5;48m'
RED_BOLD='\033[1;38;5;196m'
YELLOW_BOLD='\033[1;38;5;220m'
GRAY='\033[38;5;242m'
WHITE='\033[1;37m'
RESET='\033[0m'
DIM='\033[2m'

get_cols() {
    local c=""
    if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
        c=$(tput cols 2>/dev/null || true)
    fi
    if [ -z "$c" ] && command -v stty >/dev/null 2>&1; then
        c=$(stty size 2>/dev/null | awk '{print $2}' || true)
    fi
    if [ -z "$c" ] || ! [[ "$c" =~ ^[0-9]+$ ]] || [ "$c" -lt 25 ]; then
        c="${COLUMNS:-${TERM_WIDTH:-50}}"
    fi
    if ! [[ "$c" =~ ^[0-9]+$ ]] || [ "$c" -lt 25 ]; then
        c=50
    fi
    echo "$c"
}

wrap_log() {
    local prefix_vis_len="$1"; local prefix_str="$2"; local indent_str="$3"; local indent_vis_len="$4"; local text="$5"
    local cols=$(get_cols)
    local max_first=$(( cols - prefix_vis_len - 1 )); local max_cont=$(( cols - indent_vis_len - 1 ))
    if [ $max_first -lt 15 ]; then max_first=15; fi; if [ $max_cont -lt 15 ]; then max_cont=15; fi
    local words=($text); local line=""; local is_first=1
    for word in "${words[@]}"; do
        if [ ${#line} -eq 0 ]; then line="$word"; else
            local cur_limit=$max_first; if [ $is_first -eq 0 ]; then cur_limit=$max_cont; fi
            if [ $(( ${#line} + 1 + ${#word} )) -le $cur_limit ]; then line="$line $word"; else
                if [ $is_first -eq 1 ]; then echo -e "${prefix_str}${line}${RESET}"; is_first=0; else echo -e "${indent_str}${line}${RESET}"; fi
                line="$word"
            fi
        fi
    done
    if [ ${#line} -gt 0 ]; then
        if [ $is_first -eq 1 ]; then echo -e "${prefix_str}${line}${RESET}"; else echo -e "${indent_str}${line}${RESET}"; fi
    fi
}

step()    { echo -e ""; wrap_log 3 "◆  ${PURPLE_BOLD}" "   ${PURPLE_BOLD}└─ ${RESET}${PURPLE_BOLD}" 6 "$1"; }
info()    { wrap_log 6 "   ${CYAN}ℹ${RESET}  ${DIM}" "      ${DIM}└─ ${RESET}${DIM}" 9 "$1"; }
success() { wrap_log 6 "   ${GREEN_BOLD}✓${RESET}  ${WHITE}" "      ${DIM}└─ ${RESET}${WHITE}" 9 "$1"; }
warn()    { wrap_log 6 "   ${YELLOW_BOLD}▲${RESET}  ${YELLOW_BOLD}" "      ${DIM}└─ ${RESET}${YELLOW_BOLD}" 9 "$1"; }
error()   { wrap_log 6 "   ${RED_BOLD}✗  Error: ${RESET}${RED_BOLD}" "      ${DIM}└─ ${RESET}${RED_BOLD}" 9 "$1"; }

draw_banner() {
    local ver="$1"
    local term_w=$(get_cols)
    local max_w=$((term_w - 4))
    if [ "$max_w" -lt 38 ]; then max_w=38; fi

    local hline=""
    for ((i=0; i<max_w; i++)); do hline="${hline}─"; done

    pad_line() {
        local text="$1"
        local raw
        raw=$(echo -en "$text" | sed -r "s/\x1B\[[0-9;]*[a-zA-Z]//g")
        local vis_len=${#raw}
        local pad_len=$(( max_w - vis_len - 2 ))
        if [ "$pad_len" -lt 0 ]; then pad_len=0; fi
        local pad_str=""
        for ((j=0; j<pad_len; j++)); do pad_str="${pad_str} "; done
        echo -e "${CYAN_BOLD}  │ ${RESET}${text}${pad_str}${CYAN_BOLD} │${RESET}"
    }

    echo -e "\n${CYAN_BOLD}  ┌${hline}┐${RESET}"
    pad_line "${GRAY}ZCODE MOBILE INSTALLER"
    echo -e "${CYAN_BOLD}  ├${hline}┤${RESET}"
    pad_line "${GRAY}Version        : ${RESET}${GREEN_BOLD}v${ver}"
    echo -e "${CYAN_BOLD}  └${hline}┘${RESET}"
}

on_interrupt() {
    trap - SIGINT SIGTERM
    echo -e "\n${RED_BOLD}✗  Installation aborted by user.${RESET}"
    rm -f /tmp/setup_zcode_rootfs.sh /tmp/zcode.deb /tmp/resolve_zcode.py 2>/dev/null || true
    exit 130
}
trap on_interrupt SIGINT SIGTERM

clear || true

FROM_PROOT=0
if [ -f "$HOME/.from_proot_sync" ]; then
    FROM_PROOT=1
    rm -f "$HOME/.from_proot_sync"
fi

draw_banner "$INSTALLER_VERSION"

if [ "$FROM_PROOT" -eq 1 ]; then
    info "Automatic transition from PRoot session detected."
    info "PRoot container was auto-closed to install host X11 packages."
fi

step "Initializing Host Environment (Termux System)"
info "Updating Termux repositories..."
apt update -y >/dev/null 2>&1 || pkg update -y >/dev/null 2>&1 || true

info "Installing host packages (x11-repo, termux-x11-nightly, proot-distro, xdotool)..."
pkg install -y x11-repo >/dev/null 2>&1 || true
pkg install -y proot-distro curl tar python xdotool termux-x11-nightly >/dev/null 2>&1 || true

MISSING_PKGS=()
for cmd in proot-distro curl tar python3 termux-x11; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        MISSING_PKGS+=("$cmd")
    fi
done

if [ ${#MISSING_PKGS[@]} -ne 0 ]; then
    error "Failed to install required host packages: ${MISSING_PKGS[*]}"
    echo -e "   ${CYAN}ℹ${RESET}  ${DIM}└─ ${RESET}Run manually: pkg update && pkg install -y x11-repo termux-x11-nightly proot-distro"
    exit 1
fi
success "Host utilities and X11 packages installed."

step "Verifying Debian Subsystem (PRoot Container)"
if ! proot-distro login debian -- true </dev/null >/dev/null 2>&1; then
    if ! proot-distro install debian </dev/null >/dev/null 2>&1; then
        error "Failed to provision Debian container. Check your internet connection."
        exit 1
    fi
    success "Debian container provisioned successfully."
else
    success "Debian container is ready."
fi

# Script executed inside Debian
SETUP_TMP_DIR="$PREFIX/tmp"
mkdir -p "$SETUP_TMP_DIR"
DEBIAN_SETUP_SCRIPT="$SETUP_TMP_DIR/setup_zcode.sh"

cat << 'EOF_ROOTFS_SETUP' > "$DEBIAN_SETUP_SCRIPT"
#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

info() { echo -e "   \033[1;36mℹ\033[0m  \033[2m$1\033[0m"; }
success() { echo -e "   \033[1;38;5;48m✓\033[0m  \033[1;37m$1\033[0m"; }

info "Updating package lists..."
apt-get update -y >/dev/null 2>&1

info "Installing X11, GTK3, graphics, and system dependencies..."
apt-get install -y --no-install-recommends matchbox-window-manager curl wget ca-certificates tar \
    libnss3 libnspr4 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 libxrandr2 \
    libgbm1 libpango-1.0-0 libcairo2 libasound2 libatk1.0-0 libcups2 libatk-bridge2.0-0 \
    libgtk-3-0 libgl1 libglx-mesa0 libegl1 libgl1-mesa-dri mesa-vulkan-drivers \
    dbus dbus-x11 gnome-keyring libsecret-1-0 x11-xserver-utils desktop-file-utils procps >/dev/null 2>&1 || \
apt-get install -y --no-install-recommends matchbox-window-manager curl wget ca-certificates tar \
    libnss3 libnspr4 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 libxrandr2 \
    libgbm1 libpango-1.0-0 libcairo2 libasound2t64 libatk1.0-0t64 libcups2t64 libatk-bridge2.0-0t64 \
    libgtk-3-0t64 libgl1 libglx-mesa0 libegl1 libgl1-mesa-dri mesa-vulkan-drivers \
    dbus dbus-x11 gnome-keyring libsecret-1-0t64 x11-xserver-utils desktop-file-utils procps >/dev/null 2>&1 || true

info "Installing font packages..."
apt-get install -y --no-install-recommends \
    fonts-noto-core \
    fonts-noto-color-emoji \
    fontconfig >/dev/null 2>&1 || true
fc-cache -f >/dev/null 2>&1 || true

info "Resolving latest package versions (ZCode & Mesa)..."
RESOLVER_SCRIPT="/tmp/resolve_zcode.py"
cat << 'EOF_RESOLVER' > "$RESOLVER_SCRIPT"
#!/usr/bin/env python3
import urllib.request
import json
import re
import platform

arch = platform.machine().lower()
is_arm = ("aarch64" in arch or "arm64" in arch or "armv8" in arch)

target_arch = "linux-arm64" if is_arm else "linux-x64"
default_url = f"https://cdn-zcode.z.ai/zcode/electron/releases/3.8.1/{target_arch}/ZCode-3.8.1-{target_arch.replace('linux-', '')}.deb"
version = "3.8.1"

try:
    req = urllib.request.Request("https://zcode.z.ai/cn", headers={"User-Agent": "Mozilla/5.0"})
    res = urllib.request.urlopen(req, timeout=5)
    html = res.read().decode("utf-8", errors="ignore")
    matches = re.findall(r'(https://cdn-zcode\.z\.ai/zcode/electron/releases/([\d\.]+)/' + re.escape(target_arch) + r'/[^\s"\']+\.deb)', html)
    if matches:
        default_url, version = matches[0][0], matches[0][1]
except Exception:
    pass

def resolve_mesa():
    url = "https://api.github.com/repos/lfdevs/mesa-for-android-container/releases/latest"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        res = urllib.request.urlopen(req, timeout=5)
        data = json.loads(res.read().decode("utf-8"))
        tag = data.get("tag_name", "")
        assets = data.get("assets", [])
        debian_assets = [a.get("browser_download_url", "") for a in assets if "debian" in a.get("browser_download_url", "") and a.get("browser_download_url", "").endswith(".tar.gz")]
        if debian_assets:
            return debian_assets[0], tag
        arm64_assets = [a.get("browser_download_url", "") for a in assets if "arm64" in a.get("browser_download_url", "") and a.get("browser_download_url", "").endswith(".tar.gz")]
        if arm64_assets:
            return arm64_assets[0], tag
    except Exception:
        pass
    return "", ""

mesa_url, mesa_ver = resolve_mesa()
print(f"ZCODE_URL='{default_url}'")
print(f"ZCODE_VER='{version}'")
print(f"MESA_URL='{mesa_url}'")
print(f"MESA_VER='{mesa_ver}'")
EOF_RESOLVER

eval $(python3 "$RESOLVER_SCRIPT" 2>/dev/null || true)
rm -f "$RESOLVER_SCRIPT"

mkdir -p /opt/ZCode

# --- Mesa Turnip + Zink Driver Installation ---
INSTALLED_MESA_VER=$(cat /opt/ZCode/.installed_mesa_version 2>/dev/null || true)
if [ -n "$MESA_URL" ] && [ "$INSTALLED_MESA_VER" != "$MESA_VER" ]; then
    info "Downloading latest Turnip/Zink graphics drivers ($MESA_VER)..."
    wget -q --show-progress "$MESA_URL" -O /tmp/mesa-zink.tar.gz || curl -sL "$MESA_URL" -o /tmp/mesa-zink.tar.gz
    info "Installing Turnip and Zink graphics drivers..."
    tar -xzf /tmp/mesa-zink.tar.gz -C /
    rm -f /tmp/mesa-zink.tar.gz
    echo "$MESA_VER" > /opt/ZCode/.installed_mesa_version
    success "Mesa graphics drivers updated ($MESA_VER)."
fi

INSTALLED_ZCODE_VER=$(cat /opt/ZCode/.installed_version 2>/dev/null || true)

if [ ! -f "/opt/ZCode/zcode" ] && [ ! -f "/usr/bin/zcode" ] || [ "$INSTALLED_ZCODE_VER" != "$ZCODE_VER" ]; then
    info "Downloading ZCode ${ZCODE_VER:-latest} package..."
    wget -q --show-progress "$ZCODE_URL" -O /tmp/zcode.deb || curl -sL "$ZCODE_URL" -o /tmp/zcode.deb

    info "Installing ZCode deb package..."
    dpkg -i /tmp/zcode.deb >/dev/null 2>&1 || apt-get install -f -y >/dev/null 2>&1 || true

    # Canonical directory and symlinks
    ln -sfn /opt/ZCode /opt/ZCode 2>/dev/null || true
    if [ -f "/opt/ZCode/zcode" ]; then
        chmod +x /opt/ZCode/zcode
    fi

    # Native pkexec bridge for Electron autoUpdater
    cat << 'EOF_PKEXEC' > /usr/local/bin/pkexec
#!/bin/sh
exec "$@"
EOF_PKEXEC
    chmod +x /usr/local/bin/pkexec
    ln -sf /usr/local/bin/pkexec /usr/bin/pkexec 2>/dev/null || true

    rm -f /tmp/zcode.deb
    echo "${ZCODE_VER:-3.9.1}" > /opt/ZCode/.installed_version
    success "ZCode ${ZCODE_VER:-latest} installed successfully."
else
    ln -sfn /opt/ZCode /opt/ZCode 2>/dev/null || true
    success "ZCode is already up to date (${INSTALLED_ZCODE_VER:-$ZCODE_VER})."
fi

# Create xdg-open bridge if inside PRoot container
cat << 'EOF_XDG' > /usr/local/bin/xdg-open
#!/usr/bin/env bash
TARGET="$1"

if [ -z "$TARGET" ]; then
    exit 0
fi

# 1. Try FIFO bridge if host launcher is active
if [ -p "/tmp/termux_open_fifo" ]; then
    echo "$TARGET" > /tmp/termux_open_fifo 2>/dev/null && exit 0
fi
if [ -p "/data/data/com.termux/files/usr/tmp/termux_open_fifo" ]; then
    echo "$TARGET" > /data/data/com.termux/files/usr/tmp/termux_open_fifo 2>/dev/null && exit 0
fi

# 2. Try Termux am (Android user 0)
if [ -x "/data/data/com.termux/files/usr/bin/am" ]; then
    /data/data/com.termux/files/usr/bin/am start --user 0 -a android.intent.action.VIEW -d "$TARGET" >/dev/null 2>&1 && exit 0
fi

# 3. Try termux-open
if [ -x "/data/data/com.termux/files/usr/bin/termux-open" ]; then
    /data/data/com.termux/files/usr/bin/termux-open "$TARGET" >/dev/null 2>&1 && exit 0
fi

# 4. Fallback system am
if [ -x "/system/bin/am" ]; then
    /system/bin/am start --user 0 -a android.intent.action.VIEW -d "$TARGET" >/dev/null 2>&1 && exit 0
fi

echo "$TARGET" >&2
exit 0
EOF_XDG
chmod +x /usr/local/bin/xdg-open
cp /usr/local/bin/xdg-open /usr/bin/xdg-open
chmod +x /usr/bin/xdg-open
ln -sf /usr/local/bin/xdg-open /usr/local/bin/x-www-browser
ln -sf /usr/local/bin/xdg-open /usr/local/bin/gnome-open
ln -sf /usr/local/bin/xdg-open /usr/local/bin/sensible-browser
ln -sf /usr/bin/xdg-open /usr/bin/x-www-browser 2>/dev/null || true
ln -sf /usr/bin/xdg-open /usr/bin/gnome-open 2>/dev/null || true
ln -sf /usr/bin/xdg-open /usr/bin/sensible-browser 2>/dev/null || true

# OAuth Auth callback helper
cat << 'EOF_AUTH' > /usr/local/bin/zcode-auth
#!/usr/bin/env bash
URL="$1"
if [ -z "$URL" ]; then
    if [ -x "/data/data/com.termux/files/usr/bin/termux-clipboard-get" ]; then
        CLIP=$(/data/data/com.termux/files/usr/bin/termux-clipboard-get 2>/dev/null || true)
        if [[ "$CLIP" =~ ^zcode:// ]]; then
            URL="$CLIP"
            echo -e "\033[1;38;5;48m✓ Found zcode:// callback in clipboard!\033[0m"
        fi
    fi
fi
if [ -z "$URL" ]; then
    echo -e "\033[1;38;5;39m◆ ZCode OAuth Helper\033[0m"
    echo -e "  Copy the \033[1;32mzcode://...\033[0m URL from your browser address bar and paste it below:\n"
    read -r -p "Callback URL: " URL
fi
if [ -z "$URL" ]; then
    echo "No URL provided."
    exit 1
fi
echo -e "\n\033[1;38;5;48m✓ Sending authorization callback to ZCode...\033[0m"
/opt/ZCode/run.sh "$URL" >/dev/null 2>&1 &
echo -e "\033[1;38;5;39mℹ Authorization sent! Switch back to ZCode in Termux:X11.\033[0m\n"
EOF_AUTH
chmod +x /usr/local/bin/zcode-auth

# Register desktop deep link scheme handler
mkdir -p /usr/share/applications /root/.local/share/applications 2>/dev/null || true
cat << 'EOF_DESKTOP' > /usr/share/applications/zcode.desktop
[Desktop Entry]
Name=ZCode
Comment=ZCode Desktop App
Exec=/opt/ZCode/run.sh %U
Terminal=false
Type=Application
Icon=zcode
Categories=Development;
MimeType=x-scheme-handler/zcode;
StartupWMClass=ZCode
EOF_DESKTOP
cp /usr/share/applications/zcode.desktop /root/.local/share/applications/zcode.desktop
update-desktop-database /usr/share/applications 2>/dev/null || true
update-desktop-database /root/.local/share/applications 2>/dev/null || true
xdg-mime default zcode.desktop x-scheme-handler/zcode 2>/dev/null || true

# Launcher helper inside container/rootfs
cat << 'EOF_RUN' > /opt/ZCode/run.sh
#!/bin/bash
export HOME=/root
export USER=root
export LOGNAME=root
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DISPLAY=:0
export ELECTRON_OZONE_PLATFORM_HINT=x11
export GDK_BACKEND=x11
export NO_AT_BRIDGE=1
export TMPDIR=/tmp
export XDG_RUNTIME_DIR=/tmp/runtime-root
export MALLOC_TRIM_THRESHOLD_=131072
export MESA_DISK_CACHE_SINGLE_FILE=1

# Ensure runtime & D-Bus directories exist
mkdir -p /var/run/dbus /run/dbus "$XDG_RUNTIME_DIR" /dev/shm "$HOME/.config/ZCode/session/Code Cache" "$HOME/.config/ZCode/session/databases" 2>/dev/null || true
touch /etc/drirc "$HOME/.drirc" 2>/dev/null || true

# Initialize System & Session D-Bus
if [ -x /usr/bin/dbus-daemon ] && ! pgrep -x dbus-daemon >/dev/null 2>&1; then
    dbus-daemon --system --fork 2>/dev/null || true
fi
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ] || [[ "$DBUS_SESSION_BUS_ADDRESS" != unix:* ]]; then
    eval $(dbus-launch --sh-syntax 2>/dev/null || true)
    if [[ "$DBUS_SESSION_BUS_ADDRESS" != unix:* ]]; then
        unset DBUS_SESSION_BUS_ADDRESS
    fi
fi

# Initialize gnome-keyring-daemon (Passwordless login keyring)
mkdir -p "$HOME/.local/share/keyrings" 2>/dev/null || true
if [ ! -f "$HOME/.local/share/keyrings/default" ]; then
    echo -n "login" > "$HOME/.local/share/keyrings/default" 2>/dev/null || true
fi
if [ ! -f "$HOME/.local/share/keyrings/login.keyring" ]; then
    cat << 'EOF_KEYRING' > "$HOME/.local/share/keyrings/login.keyring"
[keyring]
display-name=login
ctime=0
mtime=0
lock-on-idle=false
lock-after=false
EOF_KEYRING
    chmod 600 "$HOME/.local/share/keyrings/login.keyring" "$HOME/.local/share/keyrings/default" 2>/dev/null || true
fi

# Unlock/Start the keyring daemon
echo -n "" | gnome-keyring-daemon --unlock --components=secrets >/dev/null 2>&1 || true
eval $(gnome-keyring-daemon --start --components=secrets 2>/dev/null || true)
export GNOME_KEYRING_CONTROL
export GNOME_KEYRING_PID

# Global UI Scaling for mobile screens (2.5x System/UI Scale, 1.5x Cursor)
export GDK_SCALE=2
export GDK_DPI_SCALE=1.25
export QT_SCALE_FACTOR=2.5
export ELM_SCALE=2.5
export XCURSOR_SIZE=36
if command -v xrdb >/dev/null 2>&1; then
    cat << 'EOF_XRDB' | xrdb -merge 2>/dev/null || true
Xft.dpi: 240
Xcursor.size: 36
EOF_XRDB
fi

# Ensure GTK-3.0 system dialogs scaling config
mkdir -p "$HOME/.config/gtk-3.0" 2>/dev/null || true
cat << 'EOF_GTK' > "$HOME/.config/gtk-3.0/settings.ini"
[Settings]
gtk-font-name=Sans 14
gtk-cursor-theme-size=36
gtk-xft-dpi=245760
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
EOF_GTK

# Argument Handling
DEBUG_MODE=0
SOFTWARE_MODE=0
PASS_ARGS=()

for arg in "$@"; do
    if [ "$arg" == "--debug" ]; then
        DEBUG_MODE=1
    elif [ "$arg" == "--software" ]; then
        SOFTWARE_MODE=1
    else
        PASS_ARGS+=("$arg")
    fi
done

# Auto-open Termux:X11 app if not in debug mode
if [ "$DEBUG_MODE" -eq 0 ]; then
    if [ -x "/data/data/com.termux/files/usr/bin/am" ]; then
        /data/data/com.termux/files/usr/bin/am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true
    elif command -v am >/dev/null 2>&1; then
        am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true
    elif [ -x "/system/bin/am" ]; then
        /system/bin/am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true
    fi
fi

# Check and prepare X11 connection
if [ ! -e "/tmp/.X11-unix/X0" ]; then
    for sock in /data/data/com.termux/files/usr/tmp/.X11-unix/X0 /data/data/com.termux/files/usr/tmp/X0; do
        if [ -e "$sock" ]; then
            mkdir -p /tmp/.X11-unix 2>/dev/null || true
            ln -sf "$sock" /tmp/.X11-unix/X0 2>/dev/null || true
            break
        fi
    done
fi

if ! xset q >/dev/null 2>&1; then
    if ! pgrep -f "termux-x11" >/dev/null 2>&1 && [ -x "/data/data/com.termux/files/usr/bin/termux-x11" ]; then
        /data/data/com.termux/files/usr/bin/termux-x11 :0 >/dev/null 2>&1 &
        sleep 1.5
    fi
    if [ ! -e "/tmp/.X11-unix/X0" ] && [ -e "/data/data/com.termux/files/usr/tmp/.X11-unix/X0" ]; then
        mkdir -p /tmp/.X11-unix 2>/dev/null || true
        ln -sf /data/data/com.termux/files/usr/tmp/.X11-unix/X0 /tmp/.X11-unix/X0 2>/dev/null || true
    fi
fi

if ! xset q >/dev/null 2>&1; then
    echo -e "\n\033[1;38;5;196m✗ Error: Cannot connect to X11 display (DISPLAY=${DISPLAY:-:0})!\033[0m"
    echo -e "\033[1;38;5;39mℹ Please make sure:\033[0m"
    echo -e "  1. The \033[1mTermux:X11\033[0m app is opened on your device."
    echo -e "  2. Start X11 server: \033[1;32mtermux-x11 :0 &\033[0m\n"
    exit 1
fi

# Hardware Acceleration vs Software Mode
if [ "$SOFTWARE_MODE" -eq 1 ]; then
    export LIBGL_ALWAYS_SOFTWARE=1
    export GALLIUM_DRIVER=llvmpipe
    GPU_ARGS="--disable-gpu --disable-software-rasterizer --force-device-scale-factor=2.5"
else
    # Hardware Acceleration Flags (Native Zink + Turnip KGSL)
    export GALLIUM_DRIVER=zink
    export MESA_LOADER_DRIVER_OVERRIDE=zink
    export TU_DEBUG=sysmem,noconform
    export ZINK_DESCRIPTORS=lazy
    export MESA_VK_WSI_PRESENT_MODE=mailbox
    export MESA_VK_IGNORE_EXTENSIONS="VK_EXT_calibrated_timestamps VK_KHR_calibrated_timestamps"
    export MESA_GL_VERSION_OVERRIDE=4.6COMPAT
    export MESA_GLES_VERSION_OVERRIDE=3.2
    export MESA_GLTHREAD=true
    export vblank_mode=0

    GPU_ARGS="--ignore-gpu-blocklist --disable-vulkan --enable-gpu-rasterization --enable-oop-rasterization --canvas-oop-rasterization --gpu-rasterization-msaa-sample-count=0 --enable-zero-copy --use-gl=angle --enable-webgl --enable-accelerated-2d-canvas --num-raster-threads=8 --start-maximized --disable-gpu-sandbox --force-device-scale-factor=2.5 --enable-smooth-scrolling --password-store=gnome-libsecret"
fi

# Minimal Window Manager
if ! pgrep -f "matchbox-window-manager" > /dev/null 2>&1; then
    matchbox-window-manager -use_titlebar no >/dev/null 2>&1 &
    sleep 0.2
fi

# Main application executable
Z_BIN="/opt/ZCode/zcode"
if [ ! -x "$Z_BIN" ]; then
    Z_BIN=$(command -v zcode)
fi

if [ "$DEBUG_MODE" -eq 1 ]; then
    export ELECTRON_ENABLE_LOGGING=1
    export ELECTRON_ENABLE_STACK_DUMPING=1
    exec "$Z_BIN" --no-sandbox $GPU_ARGS --enable-logging --v=1 "${PASS_ARGS[@]}"
else
    exec "$Z_BIN" --no-sandbox $GPU_ARGS "${PASS_ARGS[@]}" >/dev/null 2>&1
fi
EOF_RUN
chmod +x /opt/ZCode/run.sh

# Deploy full CLI launcher with banner inside Debian
cat << 'EOF_INTERNAL_LAUNCH' > /usr/local/bin/zcode
#!/usr/bin/env bash
export DISPLAY=:0

cleanup_and_exit() {
    trap - SIGINT SIGTERM
    pkill -f "zcode-watchdog" >/dev/null 2>&1 || true
    pkill -f "zcode|matchbox-window-manager" >/dev/null 2>&1 || true
    echo -e "\n\033[1;38;5;220m  ┌──────────────────────────────────────────────────┐\033[0m"
    echo -e "\033[1;38;5;220m  │ \033[38;5;242mSTATUS         : \033[0m\033[1;38;5;220mSHUTTING DOWN ZCODE             \033[1;38;5;220m│\033[0m"
    echo -e "\033[1;38;5;220m  └──────────────────────────────────────────────────┘\033[0m\n"
    exit 0
}
trap cleanup_and_exit SIGINT SIGTERM

get_cols() {
    local c=""
    if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
        c=$(tput cols 2>/dev/null || true)
    fi
    if [ -z "$c" ] && command -v stty >/dev/null 2>&1; then
        c=$(stty size 2>/dev/null | awk '{print $2}' || true)
    fi
    if [ -z "$c" ] || ! [[ "$c" =~ ^[0-9]+$ ]] || [ "$c" -lt 25 ]; then
        c="${COLUMNS:-${TERM_WIDTH:-50}}"
    fi
    if ! [[ "$c" =~ ^[0-9]+$ ]] || [ "$c" -lt 25 ]; then
        c=50
    fi
    echo "$c"
}

draw_banner() {
    local ver="$1"
    local term_w=$(get_cols)
    local max_w=$((term_w - 4))
    if [ "$max_w" -lt 38 ]; then max_w=38; fi

    local hline=""
    for ((i=0; i<max_w; i++)); do hline="${hline}─"; done

    pad_line() {
        local text="$1"
        local raw
        raw=$(echo -en "$text" | sed -r "s/\x1B\[[0-9;]*[a-zA-Z]//g")
        local vis_len=${#raw}
        local pad_len=$(( max_w - vis_len - 2 ))
        if [ "$pad_len" -lt 0 ]; then pad_len=0; fi
        local pad_str=""
        for ((j=0; j<pad_len; j++)); do pad_str="${pad_str} "; done
        echo -e "\033[1;38;5;39m  │ \033[0m${text}${pad_str}\033[1;38;5;39m │\033[0m"
    }

    echo -e "\n\033[1;38;5;39m  ┌${hline}┐\033[0m"
    pad_line "\033[38;5;242mZCODE MOBILE"
    echo -e "\033[1;38;5;39m  ├${hline}┤\033[0m"
    pad_line "\033[38;5;242mVersion        : \033[0m\033[1;38;5;48mv${ver}"
    echo -e "\033[1;38;5;39m  └${hline}┘\033[0m"
}

is_authenticated() {
    local creds="$HOME/.zcode/v2/credentials.json"
    if [ -f "$creds" ]; then
        if grep -q "oauth:.*access_token\|zcodejwttoken" "$creds" 2>/dev/null; then
            return 0
        fi
    fi
    local cfg="$HOME/.zcode/v2/config.json"
    if [ -f "$cfg" ]; then
        if grep -q "apiKey.*eyJ" "$cfg" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

for arg in "$@"; do
    if [ "$arg" == "--full-delete" ]; then
        echo -e "\n\033[1;31m⚠️  WARNING: This will delete ZCode and its configuration.\033[0m"
        read -p "Are you sure you want to proceed? [y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            rm -rf /opt/ZCode /usr/local/bin/zcode /usr/local/bin/zcode-watchdog "$HOME/.config/ZCode" "$HOME/.zcode"
            echo -e "\033[1;32mZCode removed successfully.\033[0m"
            exit 0
        else
            echo "Cancelled."
            exit 0
        fi
    fi
done

draw_banner "1.0.0"
echo -e "  \033[1;30m💡 Tip: Press \033[1;31mCtrl+C\033[1;30m in this terminal to exit gracefully.\033[0m"

NEED_AUTH=0
if ! is_authenticated; then
    NEED_AUTH=1
    echo -e "  \033[1;38;5;39m🔑 Auth:\033[0m Press \033[1;38;5;48m[A]\033[0m to paste your Login callback URL."
fi
echo -e ""

/opt/ZCode/run.sh "$@" &
Z_PID=$!

switch_to_x11() {
    if [ -x "/data/data/com.termux/files/usr/bin/am" ]; then
        /data/data/com.termux/files/usr/bin/am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true
    elif command -v am >/dev/null 2>&1; then
        am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true
    elif [ -x "/system/bin/am" ]; then
        /system/bin/am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true
    fi
}

while kill -0 "$Z_PID" 2>/dev/null; do
    if [ "$NEED_AUTH" -eq 1 ]; then
        if read -s -t 0.5 -n 1 -r key; then
            if [[ "$key" == "a" || "$key" == "A" ]]; then
                echo -e "\033[1;38;5;39m◆ ZCode OAuth Login\033[0m"
                URL=""
                if [ -x "/data/data/com.termux/files/usr/bin/termux-clipboard-get" ]; then
                    CLIP=$(/data/data/com.termux/files/usr/bin/termux-clipboard-get 2>/dev/null || true)
                    if [[ "$CLIP" =~ ^zcode:// ]]; then
                        URL="$CLIP"
                        echo -e "  \033[1;38;5;48m✓\033[0m Found callback in clipboard!"
                    fi
                fi
                if [ -z "$URL" ]; then
                    echo -e "  Paste the \033[1;32mzcode://...\033[0m URL from your browser:"
                    read -r -p "  URL > " URL
                fi
                if [ -n "$URL" ]; then
                    /opt/ZCode/run.sh "$URL" >/dev/null 2>&1 &
                    echo -e "  \033[1;38;5;48m✓\033[0m Authorization sent to ZCode! Switching to Termux:X11...\n"
                    sleep 0.5
                    switch_to_x11
                    NEED_AUTH=0
                fi
            fi
        fi
    else
        sleep 1
    fi
done

wait "$Z_PID" 2>/dev/null || true
cleanup_and_exit
EOF_INTERNAL_LAUNCH
chmod +x /usr/local/bin/zcode
ln -sf /usr/local/bin/zcode /usr/bin/zcode
EOF_ROOTFS_SETUP
chmod +x "$DEBIAN_SETUP_SCRIPT"

step "Configuring Debian Container Subsystem"
proot-distro login debian --bind "$SETUP_TMP_DIR:/installer_tmp" --shared-tmp -- bash /installer_tmp/setup_zcode.sh </dev/null
rm -f "$DEBIAN_SETUP_SCRIPT"

step "Deploying Command-Line Launcher ('zcode')"
ZCODE_LAUNCHER="$PREFIX/bin/zcode"
cat << 'EOF_TERMUX_LAUNCHER' > "$ZCODE_LAUNCHER"
#!/usr/bin/env bash
unset LD_PRELOAD
unset LD_LIBRARY_PATH
export DISPLAY=:0

ROOTFS_DIR="${PREFIX:-/data/data/com.termux/files/usr}/var/lib/proot-distro/containers/debian/rootfs"
SYSDATA_DIR="${PREFIX:-/data/data/com.termux/files/usr}/var/lib/proot-distro/containers/debian/sysdata"

cleanup_and_exit() {
    trap - SIGINT SIGTERM
    exec 2>/dev/null
    if [ -n "$PROOT_PID" ]; then kill -9 "$PROOT_PID" 2>/dev/null || true; fi
    if [ -n "$FIFO_PID" ]; then kill -9 "$FIFO_PID" 2>/dev/null || true; fi
    pkill -9 -f "zcode|matchbox-window-manager" 2>/dev/null || true
    rm -f "/data/data/com.termux/files/usr/tmp/termux_open_fifo"

    echo -e "\n\033[1;38;5;220m  ┌──────────────────────────────────────────────────┐\033[0m"
    echo -e "\033[1;38;5;220m  │ \033[38;5;242mSTATUS         : \033[0m\033[1;38;5;220mSHUTTING DOWN ZCODE             \033[1;38;5;220m│\033[0m"
    echo -e "\033[1;38;5;220m  └──────────────────────────────────────────────────┘\033[0m\n"
    exit 0
}
trap cleanup_and_exit SIGINT SIGTERM

# Start FIFO bridge for host url opening
FIFO="/data/data/com.termux/files/usr/tmp/termux_open_fifo"
rm -f "$FIFO"; mkfifo "$FIFO"
(
    exec 3< "$FIFO"
    while read -r url <&3; do
        if [ -n "$url" ]; then
            /data/data/com.termux/files/usr/bin/am start --user 0 -a android.intent.action.VIEW -d "$url" >/dev/null 2>&1 || \
            termux-open "$url" >/dev/null 2>&1 || true
        fi
    done
) &
FIFO_PID=$!

get_cols() {
    local c=""
    if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
        c=$(tput cols 2>/dev/null || true)
    fi
    if [ -z "$c" ] && command -v stty >/dev/null 2>&1; then
        c=$(stty size 2>/dev/null | awk '{print $2}' || true)
    fi
    if [ -z "$c" ] || ! [[ "$c" =~ ^[0-9]+$ ]] || [ "$c" -lt 25 ]; then
        c="${COLUMNS:-${TERM_WIDTH:-50}}"
    fi
    if ! [[ "$c" =~ ^[0-9]+$ ]] || [ "$c" -lt 25 ]; then
        c=50
    fi
    echo "$c"
}

draw_banner() {
    local ver="$1"
    local term_w=$(get_cols)
    local max_w=$((term_w - 4))
    if [ "$max_w" -lt 38 ]; then max_w=38; fi

    local hline=""
    for ((i=0; i<max_w; i++)); do hline="${hline}─"; done

    pad_line() {
        local text="$1"
        local raw
        raw=$(echo -en "$text" | sed -r "s/\x1B\[[0-9;]*[a-zA-Z]//g")
        local vis_len=${#raw}
        local pad_len=$(( max_w - vis_len - 2 ))
        if [ "$pad_len" -lt 0 ]; then pad_len=0; fi
        local pad_str=""
        for ((j=0; j<pad_len; j++)); do pad_str="${pad_str} "; done
        echo -e "\033[1;38;5;39m  │ \033[0m${text}${pad_str}\033[1;38;5;39m │\033[0m"
    }

    echo -e "\n\033[1;38;5;39m  ┌${hline}┐\033[0m"
    pad_line "\033[38;5;242mZCODE MOBILE"
    echo -e "\033[1;38;5;39m  ├${hline}┤\033[0m"
    pad_line "\033[38;5;242mVersion        : \033[0m\033[1;38;5;48mv${ver}"
    echo -e "\033[1;38;5;39m  └${hline}┘\033[0m"
}

is_authenticated() {
    local creds="$ROOTFS_DIR/root/.zcode/v2/credentials.json"
    if [ -f "$creds" ]; then
        if grep -q "oauth:.*access_token\|zcodejwttoken" "$creds" 2>/dev/null; then
            return 0
        fi
    fi
    local cfg="$ROOTFS_DIR/root/.zcode/v2/config.json"
    if [ -f "$cfg" ]; then
        if grep -q "apiKey.*eyJ" "$cfg" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

draw_banner "1.0.0"
echo -e "  \033[1;30m💡 Tip: Press \033[1;31mCtrl+C\033[1;30m in this terminal to exit gracefully.\033[0m"

NEED_AUTH=0
if ! is_authenticated; then
    NEED_AUTH=1
    echo -e "  \033[1;38;5;39m🔑 Auth:\033[0m Press \033[1;38;5;48m[A]\033[0m to paste your Login callback URL."
fi
echo -e ""

DEBUG_MODE=0
for arg in "$@"; do
    if [ "$arg" == "--debug" ]; then
        DEBUG_MODE=1
    elif [ "$arg" == "--proot-reset" ]; then
        echo -e "\n\033[1;33m⚠️ WARNING: This will reset the debian container.\033[0m"
        read -p "Are you sure you want to proceed? [y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            echo -e "\033[1;32mResetting proot-distro debian container...\033[0m"
            proot-distro reset debian
            exit 0
        else
            echo "Cancelled."
            exit 0
        fi
    elif [ "$arg" == "--full-delete" ]; then
        echo -e "\n\033[1;31m⚠️ WARNING: This will delete ZCode and related configurations.\033[0m"
        read -p "Are you sure you want to proceed? [y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            proot-distro remove debian >/dev/null 2>&1 || true
            rm -f "$PREFIX/bin/zcode" "$PREFIX/bin/zcode-watchdog" "$HOME/zcode_debug.log"
            echo -e "\033[1;32mDeleted successfully.\033[0m"
            exit 0
        else
            echo "Cancelled."
            exit 0
        fi
    fi
done

ROOTFS_DIR="${PREFIX}/var/lib/proot-distro/containers/debian/rootfs"
SYSDATA_DIR="${PREFIX}/var/lib/proot-distro/containers/debian/sysdata"

PROOT_ARGS=(
    --kill-on-exit --link2symlink --sysvipc
    --kernel-release="Linux localhost 6.17.0-PRoot-Distro #1 SMP PREEMPT_DYNAMIC aarch64 localdomain -1"
    -L --change-id=0:0
    --rootfs="$ROOTFS_DIR"
    --cwd=/root --bind=/dev --bind=/proc --bind=/sys --bind=/dev/urandom:/dev/random
)

if [ ! -L /dev/fd ]; then PROOT_ARGS+=(--bind=/proc/self/fd:/dev/fd); fi
for i in 0 1 2; do
    name=""; case $i in 0) name="stdin" ;; 1) name="stdout" ;; 2) name="stderr" ;; esac
    if [ ! -L "/dev/$name" ] && [ -e "/proc/self/fd/$i" ]; then PROOT_ARGS+=(--bind=/proc/self/fd/$i:/dev/$name); fi
done

PROOT_ARGS+=(
    --bind="$SYSDATA_DIR/sys_empty:/sys/fs/selinux"
    --bind="$SYSDATA_DIR/loadavg:/proc/loadavg"
    --bind="$SYSDATA_DIR/stat:/proc/stat"
    --bind="$SYSDATA_DIR/uptime:/proc/uptime"
    --bind="$SYSDATA_DIR/version:/proc/version"
    --bind="$SYSDATA_DIR/vmstat:/proc/vmstat"
    --bind="$SYSDATA_DIR/sysctl_entry_cap_last_cap:/proc/sys/kernel/cap_last_cap"
    --bind="$SYSDATA_DIR/sysctl_inotify_max_user_watches:/proc/sys/fs/inotify/max_user_watches"
    --bind="$SYSDATA_DIR/sysctl_kernel_overflowuid:/proc/sys/kernel/overflowuid"
    --bind="$SYSDATA_DIR/sysctl_kernel_overflowgid:/proc/sys/kernel/overflowgid"
)

PROOT_ARGS+=(
    --bind="$ROOTFS_DIR/tmp:/dev/shm"
    --bind="$PREFIX/tmp:/tmp"
    --bind="$PREFIX/tmp/.X11-unix:/tmp/.X11-unix"
)

for p in /data/app /data/dalvik-cache /apex /odm /product /system /system_ext /vendor; do
    if [ -d "$p" ] || [ -f "$p" ]; then PROOT_ARGS+=(--bind="$p"); fi
done

if [ -d "/storage/self/primary" ]; then PROOT_ARGS+=(--bind=/storage/self/primary:/sdcard); fi
PROOT_ARGS+=( --bind="/data/data/com.termux/cache" --bind="$HOME" --bind="$PREFIX" )

while true; do
    if ! pgrep -f "termux-x11" > /dev/null 2>&1; then
        termux-x11 :0 >/dev/null 2>&1 &
        sleep 1
    fi

    if [ "$DEBUG_MODE" -eq 0 ]; then
        /data/data/com.termux/files/usr/bin/am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true
    fi

    if [ "$DEBUG_MODE" -eq 1 ]; then
        echo -e "\033[1;33m[DEBUG] Running ZCode in foreground mode...\033[0m"
        /data/data/com.termux/files/usr/bin/proot "${PROOT_ARGS[@]}" /opt/ZCode/run.sh "$@" 2>&1 | tee /data/data/com.termux/files/home/zcode_debug.log
    else
        /data/data/com.termux/files/usr/bin/proot "${PROOT_ARGS[@]}" /opt/ZCode/run.sh "$@" >/dev/null 2>&1 &
        PROOT_PID=$!

        while kill -0 "$PROOT_PID" 2>/dev/null; do
            if [ "$NEED_AUTH" -eq 1 ]; then
                if read -s -t 0.5 -n 1 -r key; then
                    if [[ "$key" == "a" || "$key" == "A" ]]; then
                        echo -e "\033[1;38;5;39m◆ ZCode OAuth Login\033[0m"
                        URL=""
                        if command -v termux-clipboard-get >/dev/null 2>&1; then
                            CLIP=$(termux-clipboard-get 2>/dev/null || true)
                            if [[ "$CLIP" =~ ^zcode:// ]]; then
                                URL="$CLIP"
                                echo -e "  \033[1;38;5;48m✓\033[0m Found callback in clipboard!"
                            fi
                        fi
                        if [ -z "$URL" ]; then
                            echo -e "  Paste the \033[1;32mzcode://...\033[0m URL from your browser:"
                            read -r -p "  URL > " URL
                        fi
                        if [ -n "$URL" ]; then
                            /data/data/com.termux/files/usr/bin/proot "${PROOT_ARGS[@]}" /opt/ZCode/run.sh "$URL" >/dev/null 2>&1 &
                            echo -e "  \033[1;38;5;48m✓\033[0m Authorization sent to ZCode! Switching to Termux:X11...\n"
                            sleep 0.5
                            /data/data/com.termux/files/usr/bin/am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true
                            NEED_AUTH=0
                        fi
                    fi
                fi
            else
                sleep 1
            fi
        done
        wait "$PROOT_PID" 2>/dev/null || true
    fi

    sleep 1
done
cleanup_and_exit
EOF_TERMUX_LAUNCHER

chmod +x "$ZCODE_LAUNCHER"
if command -v termux-fix-shebang >/dev/null 2>&1; then termux-fix-shebang "$ZCODE_LAUNCHER"; fi

success "Installation complete! Run 'zcode' to launch ZCode IDE."

if [ "$FROM_PROOT" -eq 1 ]; then
    info "Cleaning up temporary synced installer folder..."
    rm -rf "$HOME/ZCode-Mobile"
    echo -e ""
    info "Starting Termux:X11 server..."
    if ! pgrep -f "termux-x11" >/dev/null 2>&1; then
        termux-x11 :0 >/dev/null 2>&1 &
        sleep 1
    fi
    info "Returning to PRoot Debian container..."
    sleep 1
    exec proot-distro login --shared-tmp debian
fi
