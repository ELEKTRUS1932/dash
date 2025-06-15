#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status,
# treat unset variables as an error, and fail if any part of a pipeline fails.
set -euo pipefail

# Function for error handling
handle_error() {
    echo "Error on line $1: Command failed with exit code $2"
    echo "Continuing with script execution..."
}

# Set trap for error handling
trap 'handle_error $LINENO $?' ERR

# Ensure the script is run as root
if [[ "$EUID" -ne 0 ]]; then
    echo "Please run this script as root or with sudo."
    exit 1
fi

# Update the package list to ensure the latest information
echo "Updating package list..."
if ! apt update; then
    echo "Warning: Package list update failed, continuing anyway..."
fi

# Install the 'hostapd' package if it's not already installed
echo "Checking hostapd installation..."
if ! dpkg -l | grep -qw hostapd; then
    echo "Installing hostapd..."
    if apt install -y hostapd; then
        echo "hostapd installed successfully."
    else
        echo "Error: Failed to install hostapd"
        exit 1
    fi
else
    echo "hostapd is already installed (this is normal)."
fi

echo "Checking dnsmasq installation..."
if ! dpkg -l | grep -qw dnsmasq; then
    echo "Installing dnsmasq..."
    if apt install -y dnsmasq; then
        echo "dnsmasq installed successfully."
    else
        echo "Error: Failed to install dnsmasq"
        exit 1
    fi
else
    echo "dnsmasq is already installed (this is normal)."
fi

echo "Checking dhcpcd installation..."
if ! dpkg -l | grep -qw dhcpcd; then
    echo "Installing dhcpcd..."
    if apt install -y dhcpcd; then
        echo "dhcpcd installed successfully."
    else
        echo "Error: Failed to install dhcpcd"
        exit 1
    fi
else
    echo "dhcpcd is already installed (this is normal)."
fi

echo "Checking feh installation..."
if ! dpkg -l | grep -qw feh; then
    echo "Installing feh..."
    if apt install -y feh; then
        echo "feh installed successfully."
    else
        echo "Error: Failed to install feh"
        exit 1
    fi
else
    echo "feh is already installed (this is normal)."
fi

echo "Checking wmctrl installation..."
if ! dpkg -l | grep -qw wmctrl; then
    echo "Installing wmctrl..."
    if apt install -y wmctrl; then
        echo "wmctrl installed successfully."
    else
        echo "Error: Failed to install wmctrl"
        exit 1
    fi
else
    echo "wmctrl is already installed (this is normal)."
fi





###################################################################################

# Define the target directory
TARGET_DIR="/data/pku"

# Create the directory if it doesn't already exist
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Creating directory: $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
    echo "Directory created successfully."
else
    echo "Directory already exists: $TARGET_DIR"
fi

# Set ownership to user 'pi' and group 'pi'
chown pi:pi "$TARGET_DIR"

# Set secure permissions (read/write/execute for owner, read/execute for group and others)
chmod 755 "$TARGET_DIR"

# Install git if not already installed
echo "Checking git installation..."
if ! dpkg -l | grep -qw git; then
    echo "Installing git..."
    if apt install -y git; then
        echo "git installed successfully."
    else
        echo "Error: Failed to install git"
        exit 1
    fi
else
    echo "git is already installed (this is normal)."
fi

# Clone dash repository from GitHub
echo "Cloning dash repository..."
cd "$TARGET_DIR"
if [ ! -d "dash" ]; then
    if git clone https://github.com/ELEKTRUS1932/dash.git; then
    echo "Dash repository cloned successfully."
    else
        echo "Error: Failed to clone dash repository"
        exit 1
    fi

    # Run the dash installation script
    echo "Running dash installation script..."
    cd dash
    if [ -f "install.sh" ]; then
        chmod +x install.sh
        if ./install.sh; then
            echo "Dash installation completed successfully."
        else
            echo "Error: Dash installation script failed"
            exit 1
        fi
    else
        echo "Error: install.sh not found in dash directory"
        exit 1
    fi
fi



# Return to original directory
cd "$TARGET_DIR"

# Set ownership of dash directory to pi user
chown -R pi:pi dash
###################################################################################

if [ -f /lib/systemd/system/hostapd.service  ]; then
  sudo mv /lib/systemd/system/hostapd.service /lib/systemd/system/hostapd.service.orig
#   sudo rm /lib/systemd/system/hostapd.service
fi

sudo touch /lib/systemd/system/hostapd.service
#sudo cat > /lib/systemd/system/hostapd.service << EOF
sudo tee /lib/systemd/system/hostapd.service << 'EOF'
[Unit]
Description=Access point and authentication server for Wi-Fi and Ethernet
Documentation=man:hostapd(8)
After=network.target
ConditionFileNotEmpty=/etc/hostapd/hostapd.conf

[Service]
Type=forking
#PIDFile=/run/hostapd.pid
Restart=on-failure
RestartSec=2
Environment=DAEMON_CONF=/etc/hostapd/hostapd.conf
EnvironmentFile=-/etc/default/hostapd
ExecStart=/usr/sbin/hostapd -B  $DAEMON_OPTS ${DAEMON_CONF}

[Install]
WantedBy=multi-user.target
EOF



# Create or recreate /etc/dnsmasq.conf
echo "Creating /etc/dnsmasq.conf..."
if [ -f /etc/dnsmasq.conf ]; then
  rm /etc/dnsmasq.conf
fi
cat > /etc/dnsmasq.conf <<EOF
interface=wlan0      # WLAN-Interface
dhcp-range=10.0.0.2,10.0.0.250,255.255.255.0,24h
address=10.0.0.1
EOF


# Configure /etc/dhcpcd.conf for static IP on wlan0
echo "Configuring /etc/dhcpcd.conf for static IP on wlan0..."
DHCPCD_CONF="/etc/dhcpcd.conf"

# Remove any existing wlan0 configuration
sed -i '/^interface wlan0/,/^$/d' "$DHCPCD_CONF"

# Add the new wlan0 configuration at the end of the file
cat >> "$DHCPCD_CONF" <<EOF

interface wlan0
    static ip_address=10.0.0.1/24
    nohook wpa_supplicant
EOF

echo "/etc/dhcpcd.conf configured successfully."

# Create autostart script for dash
echo "Creating autostart script for dash..."
AUTOSTART_SCRIPT="/data/pku/autostart.sh"

# Remove existing autostart script if it exists
if [ -f "$AUTOSTART_SCRIPT" ]; then
  echo "Removing existing autostart script..."
rm "$AUTOSTART_SCRIPT"
fi
  
  # Create new autostart script
  cat > "$AUTOSTART_SCRIPT" <<EOF
#!/bin/bash

# Wait a bit for system to fully start
sleep 5

# Set DISPLAY environment variable
export DISPLAY=:0

# Change to dash directory
cd /data/pku/dash/bin

# Start dash application in terminal
lxterminal -e "./dash"
EOF

  # Make the autostart script executable
  chmod +x "$AUTOSTART_SCRIPT"

  # Set ownership to pi user
  chown pi:pi "$AUTOSTART_SCRIPT"
  
  # Create desktop entry for autostart
echo "Creating desktop entry for autostart..."
DESKTOP_ENTRY="/etc/xdg/autostart/dash-autostart.desktop"

# Remove existing desktop entry if it exists
if [ -f "$DESKTOP_ENTRY" ]; then
  echo "Removing existing desktop entry..."
  rm "$DESKTOP_ENTRY"
fi

# Create new desktop entry
cat > "$DESKTOP_ENTRY" <<EOF
[Desktop Entry]
Type=Application
Name=Dash Autostart
Comment=Auto-start Dash application in terminal
Exec=/data/pku/autostart.sh
Terminal=false
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
StartupNotify=false
EOF

# Set correct permissions for desktop entry
chmod 644 "$DESKTOP_ENTRY"

echo "Dash autostart configuration completed successfully."



###################################################################################


# Ensure the script is run as root
if [[ "$EUID" -ne 0 ]]; then
    echo "Please run this script as root or with sudo."
    exit 1
fi



## Define variables for the hotspot
SSID="Trabant601"
PASSPHRASE="MeinTollesPasswort123"
COUNTRY_CODE="US"
CHANNEL="149"  # 5GHz high-throughput, less interference
INTERFACE="wlan0"
HW_MODE="a"
DRIVER="nl80211"

## Update package list and install necessary packages
echo "Updating packages and installing hostapd..."
apt update
apt install -y hostapd

# Enable hostapd but don't start it yet
# systemctl unmask hostapd
# systemctl enable hostapd
systemctl stop NetworkManager
systemctl stop wpa_supplicant
systemctl disable NetworkManager
#systemctl disable wpa_supplicant

# Deaktivieren von NetworkManager und wpa_supplicant nur für wlan0
echo "Deaktivieren von NetworkManager und wpa_supplicant für wlan0..."

# Check if NetworkManager is running before trying to stop it
if systemctl is-active --quiet NetworkManager; then
    echo "Stopping NetworkManager..."
    systemctl stop NetworkManager
else
    echo "NetworkManager is not running (this is normal)."
fi

# Check if NetworkManager is enabled before trying to disable it
if systemctl is-enabled --quiet NetworkManager; then
    echo "Disabling NetworkManager..."
    systemctl disable NetworkManager
else
    echo "NetworkManager is already disabled (this is normal)."
fi

# Check if wpa_supplicant is running before trying to stop it
if systemctl is-active --quiet wpa_supplicant; then
    echo "Stopping wpa_supplicant..."
    systemctl stop wpa_supplicant
else
    echo "wpa_supplicant is not running (this is normal)."
fi

# Ensure LAN (eth0) remains functional and unaffected
if command -v nmcli >/dev/null 2>&1; then
    echo "Setting wlan0 as unmanaged by NetworkManager..."
    if nmcli dev set wlan0 managed no 2>/dev/null; then
        echo "Successfully set wlan0 as unmanaged."
    else
        echo "Warning: Could not set wlan0 as unmanaged (NetworkManager may not be running)."
    fi
else
    echo "nmcli not available, skipping NetworkManager configuration."
fi

# Stop NetworkManager and wpa_supplicant only for wlan0
if systemctl is-active --quiet wpa_supplicant@wlan0; then
    echo "Stopping wpa_supplicant@wlan0..."
    systemctl stop wpa_supplicant@wlan0
else
    echo "wpa_supplicant@wlan0 is not running (this is normal)."
fi

if systemctl is-enabled --quiet wpa_supplicant@wlan0; then
    echo "Disabling wpa_supplicant@wlan0..."
    systemctl disable wpa_supplicant@wlan0
else
    echo "wpa_supplicant@wlan0 is already disabled (this is normal)."
fi

# Configure wlan0 interface
echo "Configuring wlan0 interface..."
if ip link set wlan0 down 2>/dev/null; then
    echo "Successfully brought wlan0 down."
else
    echo "Warning: Could not bring wlan0 down (interface may not exist)."
fi

if iw wlan0 set type __ap 2>/dev/null; then
    echo "Successfully set wlan0 to AP mode."
else
    echo "Warning: Could not set wlan0 to AP mode (may already be set or interface not available)."
fi

if ip link set wlan0 up 2>/dev/null; then
    echo "Successfully brought wlan0 up."
else
    echo "Warning: Could not bring wlan0 up."
fi




echo "Creating /etc/hostapd/hostapd.conf..."
if [ -f /etc/hostapd/hostapd.conf ]; then
  rm /etc/hostapd/hostapd.conf
fi
cat > /etc/hostapd/hostapd.conf <<EOF
# === Allgemein ===
interface=wlan0
driver=nl80211
ssid=Trabant601
country_code=US
ieee80211d=1

# === 5 GHz-Mode (802.11a + 802.11n) ===
hw_mode=a
channel=149

# reines 802.11n (HT40) – kein AC/AX, kein VHT
ieee80211n=1
require_ht=1
ht_capab=[HT40+][SHORT-GI-20][SHORT-GI-40]
wmm_enabled=1

# === WPA2-Sicherheit ===
auth_algs=1
wpa=2
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
wpa_passphrase=MeinTollesPasswort123
EOF



# Bring interface up with max transmit power
echo "Setting interface ${INTERFACE} up with maximum transmit power..."

# Unmask and enable hostapd service
systemctl daemon-reload
echo "Unmasking and enabling hostapd service..."
if systemctl unmask hostapd; then
    echo "hostapd successfully unmasked."
else
    echo "Warning: Could not unmask hostapd (may already be unmasked)."
fi

if systemctl enable hostapd; then
    echo "hostapd successfully enabled."
else
    echo "Warning: Could not enable hostapd."
fi

# Start hostapd service
echo "Starting hostapd service..."
# Restart hostapd to apply changes
echo "Starting services..."

if systemctl restart dnsmasq; then
    echo "dnsmasq restarted successfully."
else
    echo "Warning: Could not restart dnsmasq."
fi

if systemctl restart dhcpcd; then
    echo "dhcpcd restarted successfully."
else
    echo "Warning: Could not restart dhcpcd."
fi

# Only restart NetworkManager if it was originally running
if systemctl is-enabled --quiet NetworkManager 2>/dev/null; then
    if systemctl restart NetworkManager; then
        echo "NetworkManager restarted successfully."
    else
        echo "Warning: Could not restart NetworkManager."
    fi
else
    echo "NetworkManager is disabled, skipping restart."
fi

# Only restart wpa_supplicant if it was originally running
if systemctl is-enabled --quiet wpa_supplicant 2>/dev/null; then
    if systemctl restart wpa_supplicant; then
        echo "wpa_supplicant restarted successfully."
    else
        echo "Warning: Could not restart wpa_supplicant."
    fi
else
    echo "wpa_supplicant is disabled, skipping restart."
fi

if systemctl restart hostapd; then
    echo "hostapd restarted successfully."
else
    echo "Error: Could not restart hostapd. Check configuration files."
    systemctl status hostapd
fi

# Update /etc/xdg/lxsession/LXDE-pi/autostart to disable screen blanking and power management
echo "Updating /etc/xdg/lxsession/LXDE-pi/autostart..."
AUTOSTART_FILE="/etc/xdg/lxsession/LXDE-pi/autostart"

# Create directory if it doesn't exist
if [ ! -d "$(dirname "$AUTOSTART_FILE")" ]; then
    echo "Creating directory for autostart file..."
    mkdir -p "$(dirname "$AUTOSTART_FILE")"
fi

# Create autostart file if it doesn't exist
if [ ! -f "$AUTOSTART_FILE" ]; then
    echo "Creating new autostart file..."
    touch "$AUTOSTART_FILE"
fi

# Add screen settings if not already present
if ! grep -q "@xset s off" "$AUTOSTART_FILE"; then
    echo "@xset s off" >> "$AUTOSTART_FILE"
    echo "Added screen saver disable setting."
else
    echo "Screen saver disable setting already present."
fi

if ! grep -q "@xset -dpms" "$AUTOSTART_FILE"; then
    echo "@xset -dpms" >> "$AUTOSTART_FILE"
    echo "Added power management disable setting."
else
    echo "Power management disable setting already present."
fi

if ! grep -q "@xset s noblank" "$AUTOSTART_FILE"; then
    echo "@xset s noblank" >> "$AUTOSTART_FILE"
    echo "Added screen blank disable setting."
else
    echo "Screen blank disable setting already present."
fi

if ! grep -q "@/data/pku/splash.sh" "$AUTOSTART_FILE"; then
    echo "@/data/pku/splash.sh" >> "$AUTOSTART_FILE"
    echo "Added screen splash."
else
    echo "Screen splash setting already present."
fi

# Add xrandr commands for display configuration
# if ! grep -q "@xrandr --output HDMI-1 --rotate right" "$AUTOSTART_FILE"; then
#     echo "@xrandr --output HDMI-1 --rotate right" >> "$AUTOSTART_FILE"
#     echo "Added display rotation setting."
# else
#     echo "Display rotation setting already present."
# fi

if ! grep -q "@xrandr --output HDMI-1 --mode 2560x1440 --rotate right" "$AUTOSTART_FILE"; then
    echo "@xrandr --output HDMI-1 --mode 2560x1440 --rotate right" >> "$AUTOSTART_FILE"
    echo "Added display resolution setting."
else
    echo "Display resolution setting already present."
fi

# Set display rotation to 1 in /boot/config.txt
echo "Setting display rotation to 1 in /boot/config.txt..."
CONFIG_FILE="/boot/config.txt"
if [ -f "$CONFIG_FILE" ]; then
    if ! grep -q "^display_rotate=1" "$CONFIG_FILE"; then
        echo "display_rotate=1" >> "$CONFIG_FILE"
        echo "Display rotation setting added to config.txt."
    else
        echo "Display rotation setting already present in config.txt."
    fi
else
    echo "Warning: /boot/config.txt not found. Creating new file..."
    echo "display_rotate=1" > "$CONFIG_FILE"
fi


sudo raspi-config nonint do_boot_order B1
sudo raspi-config nonint do_wayland W1
sudo raspi-config nonint do_boot_splash 0
sudo raspi-config nonint do_boot_behaviour B4
sudo raspi-config nonint do_vnc 0

sudo plymouth-set-default-theme -R pix


##################################################################################


# Create or replace /home/pi/.config/openDsh configuration file
echo "Creating openDsh configuration file..."
OPENDSH_CONFIG="/home/pi/.config/openDsh/dash.conf"

# Create .config directory if it doesn't exist
mkdir -p "$(dirname "$OPENDSH_CONFIG")"

# Remove existing file if it exists and create new one
if [ -f "$OPENDSH_CONFIG" ]; then
  echo "Removing existing openDsh configuration..."
  rm "$OPENDSH_CONFIG"
fi

# Create new openDsh configuration file
cat > "$OPENDSH_CONFIG" <<EOF
[Layout]
ControlBar\quick_view=1
Fullscreen\toggler=0
Page\1=false
Page\2=false
Page\3=false
Page\4=false
scale=3.5

[System]
volume=100

[Theme]
mode=1
EOF

# Set ownership to pi user
chown pi:pi "$OPENDSH_CONFIG"

# Set appropriate permissions
chmod 644 "$OPENDSH_CONFIG"

echo "openDsh configuration file created successfully."

# Create or replace openauto.ini configuration file
echo "Creating openauto.ini configuration file..."
OPENAUTO_CONFIG="/data/pku/dash/bin/openauto.ini"

# Create .config directory if it doesn't exist
mkdir -p "$(dirname "$OPENAUTO_CONFIG")"

# Remove existing file if it exists and create new one
if [ -f "$OPENAUTO_CONFIG" ]; then
  echo "Removing existing openauto.ini configuration..."
  rm "$OPENAUTO_CONFIG"
fi

# Create new openauto.ini configuration file
cat > "$OPENAUTO_CONFIG" <<EOF
[General]
HandednessOfTrafficType=0
ShowClock=true
[Video]
FPS=2
Resolution=2
ScreenDPI=210
OMXLayerIndex=1
MarginWidth=542
MarginHeight=0
WhitesreenWorkaround=true
[Input]
EnableTouchscreen=true
PlayButton=false
PauseButton=false
TogglePlayButton=false
NextTrackButton=false
PreviousTrackButton=false
HomeButton=false
PhoneButton=false
CallEndButton=false
VoiceCommandButton=false
LeftButton=false
RightButton=false
UpButton=false
DownButton=false
ScrollWheelButton=false
BackButton=false
EnterButton=false
[Bluetooth]
AdapterType=1
RemoteAdapterAddress=
[Audio]
MusicAudioChannelEnabled=false
SpeechAudioChannelEnabled=false
OutputBackendType=1
[WiFi]
SSID=Trabant601
Password=MeinTollesPasswort123
AdapterMAC=
AutoconnectLastBluetoothDevice=true
LastBluetoothPair=
EOF

# Set ownership to pi user
chown pi:pi "$OPENAUTO_CONFIG"

# Set appropriate permissions
chmod 644 "$OPENAUTO_CONFIG"

echo "openauto.ini configuration file created successfully."


######################################################################################
#Für Splashscreen



# Check and update /boot/firmware/cmdline.txt parameters
echo "Checking and updating /boot/firmware/cmdline.txt parameters..."
CMDLINE_FILE="/boot/firmware/cmdline.txt"

# Check if cmdline.txt exists
if [ -f "$CMDLINE_FILE" ]; then
  echo "Found $CMDLINE_FILE, checking parameters..."
    
    # Read current content (all on one line)
    CURRENT_CMDLINE=$(cat "$CMDLINE_FILE")
    
    # List of parameters to check and add
    PARAMETERS=("quiet" "splash" "logo.nologo" "vt.global_cursor_default=0" "plymouth.enable=1")
    
    # Check each parameter individually
    for PARAM in "${PARAMETERS[@]}"; do
        if [[ "$CURRENT_CMDLINE" == *"$PARAM"* ]]; then
            echo "Parameter '$PARAM' already present."
        else
            echo "Adding parameter '$PARAM' to cmdline.txt..."
            # Add parameter with space at the end of the line (no newline)
            CURRENT_CMDLINE="$CURRENT_CMDLINE $PARAM"
        fi
    done
    
    # Write back the updated content (ensure it stays on one line)
    echo "$CURRENT_CMDLINE" > "$CMDLINE_FILE"
    echo "cmdline.txt parameters updated successfully."
    
else
    echo "Warning: $CMDLINE_FILE not found. Creating new file with required parameters..."
    echo "quiet splash logo.nologo vt.global_cursor_default=0 plymouth.enable=1" > "$CMDLINE_FILE"
fi

echo "Boot configuration settings updated successfully."



sudo chown -R pi:pi /data/pku

sudo chmod 777 /data/pku/dash/bin/openauto.ini


echo "splash.sh script created successfully."
# Create or replace splash.sh script
echo "Creating splash.sh script..."
SPLASH_SCRIPT="/data/pku/splash.sh"

# Remove existing splash.sh script if it exists
if [ -f "$SPLASH_SCRIPT" ]; then
    echo "Removing existing splash.sh script..."
    rm "$SPLASH_SCRIPT"
fi

# Create new splash.sh script
cat > "$SPLASH_SCRIPT" <<'EOF'
#!/bin/bash
# Bild anzeigen
feh --fullscreen --auto-zoom --hide-pointer --title 'Splash' /home/pi/trabant.png &
pid=$!

# für 8 Sekunden alle 20 ms das Fenster in den Vordergrund holen
end=$((SECONDS+8))
while [ $SECONDS -lt $end ]; do
    wmctrl -r 'Splash' -b add,above
    sleep 0.02
done

# feh beenden
kill $pid
EOF

# Make the splash.sh script executable
chmod +x "$SPLASH_SCRIPT"

# Set ownership to pi user
chown pi:pi "$SPLASH_SCRIPT"

echo "splash.sh script created successfully."

# Create Plymouth theme "trabant"
echo "Creating Plymouth theme 'trabant'..."
PLYMOUTH_THEME_DIR="/usr/share/plymouth/themes/trabant"

# Create theme directory if it doesn't exist
if [ ! -d "$PLYMOUTH_THEME_DIR" ]; then
    echo "Creating Plymouth theme directory..."
    mkdir -p "$PLYMOUTH_THEME_DIR"
else
    echo "Plymouth theme directory already exists."
fi

# Create or replace trabant.script file
echo "Creating trabant.script file..."
cat > "$PLYMOUTH_THEME_DIR/trabant.script" <<'EOF'
// Bildschirmgröße ermitteln
screen_width = Window.GetWidth();
screen_height = Window.GetHeight();

// Hintergrund schwarz setzen
Window.SetBackgroundTopColor(0, 0, 0);
Window.SetBackgroundBottomColor(0, 0, 0);

// Trabant-Bild laden
theme_image = Image("trabant.png");
image_width = theme_image.GetWidth();
image_height = theme_image.GetHeight();

// Bild zentrieren (ohne Skalierung)
image_x = (screen_width - image_width) / 2;
image_y = (screen_height - image_height) / 2;

// Sprite erstellen und positionieren
if (Plymouth.GetMode() != "shutdown")
{
    sprite = Sprite(theme_image);
    sprite.SetPosition(image_x, image_y, -100);
}

// Message-Sprite für eventuelle Textnachrichten
message_sprite = Sprite();
message_sprite.SetPosition(0, screen_height, 10000);

// Callback-Funktion für Status-Updates
fun message_callback(text) {
    if (text) {
        my_image = Image.Text(text, 1, 1, 1);
        message_sprite.SetImage(my_image);
    }
}

Plymouth.SetUpdateStatusFunction(message_callback);
EOF

# Create or replace trabant.plymouth file
echo "Creating trabant.plymouth configuration file..."
cat > "$PLYMOUTH_THEME_DIR/trabant.plymouth" <<'EOF'
[Plymouth Theme]
Name=Trabant
Description=Custom fullscreen splash for Trabant
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/trabant
ScriptFile=/usr/share/plymouth/themes/trabant/trabant.script
EOF

# Set proper permissions for Plymouth theme files
chmod 644 "$PLYMOUTH_THEME_DIR/trabant.script"
chmod 644 "$PLYMOUTH_THEME_DIR/trabant.plymouth"
cp /data/pku/dash/trabant.png "/home/pi/trabant.png"
cp /data/pku/dash/trabant_rotated.png "$PLYMOUTH_THEME_DIR/trabant.png"

# Set the new Plymouth theme as default
echo "Setting Plymouth theme to 'trabant'..."
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
    if plymouth-set-default-theme -R trabant; then
        echo "Plymouth theme 'trabant' set as default successfully."
    else
        echo "Warning: Could not set Plymouth theme to 'trabant'."
    fi
else
    echo "Warning: plymouth-set-default-theme command not found."
fi


echo "Plymouth theme 'trabant' created successfully."
echo "Note: You need to place your 'trabant.png' image in $PLYMOUTH_THEME_DIR"
# Modify /etc/initramfs-tools/initramfs.conf
echo "Modifying /etc/initramfs-tools/initramfs.conf..."
INITRAMFS_CONF="/etc/initramfs-tools/initramfs.conf"

# Ensure the file exists
if [ -f "$INITRAMFS_CONF" ]; then
    # Update MODULES entry
    if grep -q "^MODULES=" "$INITRAMFS_CONF"; then
        sed -i 's/^MODULES=.*/MODULES=most/' "$INITRAMFS_CONF"
        echo "Updated MODULES entry to 'MODULES=most'."
    else
        echo "MODULES=most" >> "$INITRAMFS_CONF"
        echo "Added MODULES entry with value 'most'."
    fi

    # Update or add BOOT entry
    if grep -q "^BOOT=" "$INITRAMFS_CONF"; then
        sed -i 's/^BOOT=.*/BOOT=local/' "$INITRAMFS_CONF"
        echo "Updated BOOT entry to 'BOOT=local'."
    else
        echo "BOOT=local" >> "$INITRAMFS_CONF"
        echo "Added BOOT entry with value 'local'."
    fi
else
    echo "Error: $INITRAMFS_CONF not found. Cannot modify the file."
    exit 1
fi

echo "/etc/initramfs-tools/initramfs.conf modified successfully."
sudo update-initramfs -u





# -rwxr-xr-x 1 root root  152 Jun 15 12:58 plymouth
# /usr/share/initramfs-tools/scripts/init-bottom $ nano plymouth



# #!/bin/sh

# PREREQ="udev"

# prereqs()
# {
#         echo "${PREREQ}"
# }

# case ${1} in
#         prereqs)
#                 prereqs
#                 exit 0
#                 ;;
# esac

# #/usr/bin/plymouth --newroot=${rootmnt}
















echo ""
echo ""
echo ""
echo ""
echo ""

echo "You need to make a few changes that are difficult to automate:"
echo "cp /usr/lib/firmware/raspberrypi/bootloader-<newest>/stable/pieeprom-<newest>.bin /home/pi/new.bin"
echo "in my case is it /usr/lib/firmware/raspberrypi/bootloader-2712/stable/pieeprom-2025-06-09.bin"
echo "but it may change based on your system installation date and the firmware version.\n\n"

echo "Excecute: sudo rpi-eeprom-config --edit"
echo "Edit NET_INSTALL_AT_POWER_ON=1 to  NET_INSTALL_AT_POWER_ON=0
"






echo "After that all installations and configurations completed successfully."
echo "Please reboot your system to apply all changes."

# Update LXPanel configuration to set iconsize and height in the Global section
echo "Setting iconsize and height in the Global section of LXPanel configuration..."
PANEL_CONFIG_FILE="/etc/xdg/lxpanel/LXDE-pi/panels/panel"

if [ -f "$PANEL_CONFIG_FILE" ]; then
  echo "Updating iconsize and height values in existing LXPanel configuration..."
  
  # Update only the iconsize value within the Global section
  sed -i '/^Global {/,/^}/ s/^  iconsize=.*/  iconsize=80/' "$PANEL_CONFIG_FILE"
  
  # Update only the height value within the Global section  
  sed -i '/^Global {/,/^}/ s/^  height=.*/  height=80/' "$PANEL_CONFIG_FILE"
  
  echo "LXPanel configuration values updated successfully."
else
  echo "LXPanel configuration file not found. Creating a new one..."
  mkdir -p "$(dirname "$PANEL_CONFIG_FILE")"
  cat > "$PANEL_CONFIG_FILE" <<EOF
# lxpanel <profile> config file. Manually editing is not recommended.
# Use preference dialog in lxpanel to adjust config when you can.

Global {
  edge=top
  align=left
  margin=0
  widthtype=percent
  width=100
  height=80
  transparent=0
  tintcolor=#000000
  alpha=0
  autohide=0
  heightwhenhidden=2
  setdocktype=1
  setpartialstrut=1
  usefontcolor=0
  fontsize=12
  fontcolor=#ffffff
  usefontsize=0
  background=0
  backgroundfile=/usr/share/lxpanel/images/background.png
  iconsize=80
  monitor=0
  point_at_menu=0
}
EOF
fi

# Restart LXPanel to apply changes

# Set font size in LXDE Appearance Settings
echo "Setting font size to 40 in LXDE configuration..."

# Update desktop.conf for LXDE session settings
DESKTOP_CONF="/etc/xdg/lxsession/LXDE-pi/desktop.conf"
mkdir -p "$(dirname "$DESKTOP_CONF")"

if [ -f "$DESKTOP_CONF" ]; then
  echo "Updating font size in existing desktop.conf..."
  # Update or add font size setting
  if grep -q "^sGtk/FontName=" "$DESKTOP_CONF"; then
    sed -i 's/^sGtk\/FontName=.*/sGtk\/FontName=PibotoLt Regular 40/' "$DESKTOP_CONF"
  else
    echo "sGtk/FontName=PibotoLt Regular 40" >> "$DESKTOP_CONF"
  fi
else
  echo "Creating new desktop.conf with font size setting..."
  cat > "$DESKTOP_CONF" <<EOF
[GTK]
sGtk/FontName=PibotoLt Regular 40
EOF
fi

echo "Font size set to 40 successfully."

echo "Restarting LXPanel..."
lxpanelctl restart

# Create or replace /data/pku/splash.sh script
echo "Creating splash.sh script..."
SPLASH_SCRIPT="/data/pku/splash.sh"

# Remove existing file if it exists and create new one
if [ -f "$SPLASH_SCRIPT" ]; then
  echo "Removing existing splash.sh script..."
  rm "$SPLASH_SCRIPT"
fi

# Create new splash.sh script
cat > "$SPLASH_SCRIPT" <<'EOF'
#!/bin/bash
# Bild anzeigen
feh --fullscreen --auto-zoom --hide-pointer --title 'Splash' /data/pku/dash/trabant.png &
pid=$!

# für 8 Sekunden alle 20 ms das Fenster in den Vordergrund holen
end=$((SECONDS+8))
while [ $SECONDS -lt $end ]; do
  wmctrl -r 'Splash' -b add,above
  sleep 0.02
done

# feh beenden
kill $pid
EOF

# Make the splash script executable
chmod +x "$SPLASH_SCRIPT"

# Set ownership to pi user
chown pi:pi "$SPLASH_SCRIPT"

echo "splash.sh script created successfully."

# Create Plymouth theme "trabant"
echo "Creating Plymouth theme 'trabant'..."
PLYMOUTH_THEME_DIR="/usr/share/plymouth/themes/trabant"

# Create theme directory if it doesn't exist
if [ ! -d "$PLYMOUTH_THEME_DIR" ]; then
    echo "Creating Plymouth theme directory..."
    mkdir -p "$PLYMOUTH_THEME_DIR"
else
    echo "Plymouth theme directory already exists."
fi

# Create or replace trabant.script file
echo "Creating trabant.script file..."
cat > "$PLYMOUTH_THEME_DIR/trabant.script" <<'EOF'
// Bildschirmgröße ermitteln
screen_width = Window.GetWidth();
screen_height = Window.GetHeight();

// Hintergrund schwarz setzen
Window.SetBackgroundTopColor(0, 0, 0);
Window.SetBackgroundBottomColor(0, 0, 0);

// Trabant-Bild laden
theme_image = Image("trabant.png");
image_width = theme_image.GetWidth();
image_height = theme_image.GetHeight();

// Bild zentrieren (ohne Skalierung)
image_x = (screen_width - image_width) / 2;
image_y = (screen_height - image_height) / 2;

// Sprite erstellen und positionieren
if (Plymouth.GetMode() != "shutdown")
{
    sprite = Sprite(theme_image);
    sprite.SetPosition(image_x, image_y, -100);
}

// Message-Sprite für eventuelle Textnachrichten
message_sprite = Sprite();
message_sprite.SetPosition(0, screen_height, 10000);

// Callback-Funktion für Status-Updates
fun message_callback(text) {
    if (text) {
        my_image = Image.Text(text, 1, 1, 1);
        message_sprite.SetImage(my_image);
    }
}

Plymouth.SetUpdateStatusFunction(message_callback);
EOF

# Create or replace trabant.plymouth file
echo "Creating trabant.plymouth configuration file..."
cat > "$PLYMOUTH_THEME_DIR/trabant.plymouth" <<'EOF'
[Plymouth Theme]
Name=Trabant
Description=Custom fullscreen splash for Trabant
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/trabant
ScriptFile=/usr/share/plymouth/themes/trabant/trabant.script
EOF

# Set proper permissions for Plymouth theme files
chmod 644 "$PLYMOUTH_THEME_DIR/trabant.script"
chmod 644 "$PLYMOUTH_THEME_DIR/trabant.plymouth"

# Set the new Plymouth theme as default
echo "Setting Plymouth theme to 'trabant'..."
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
    if plymouth-set-default-theme -R trabant; then
        echo "Plymouth theme 'trabant' set as default successfully."
    else
        echo "Warning: Could not set Plymouth theme to 'trabant'."
    fi
else
    echo "Warning: plymouth-set-default-theme command not found."
fi

echo "Plymouth theme 'trabant' created successfully."
echo "Note: You need to place your 'trabant.png' image in $PLYMOUTH_THEME_DIR"

# Add boot configuration settings to /boot/config.txt
echo "Adding boot configuration settings to /boot/config.txt..."
CONFIG_FILE="/boot/config.txt"

# Remove existing NET_INSTALL_AT_POWER_ON entry if it exists
if grep -q "NET_INSTALL_AT_POWER_ON=1" "$CONFIG_FILE"; then
    echo "Removing NET_INSTALL_AT_POWER_ON=1 entry..."
    sed -i '/NET_INSTALL_AT_POWER_ON=1/d' "$CONFIG_FILE"
fi

# Update or add BOOT_ORDER setting
if grep -q "BOOT_ORDER=" "$CONFIG_FILE"; then
    echo "Updating existing BOOT_ORDER setting..."
    sed -i 's/BOOT_ORDER=.*/BOOT_ORDER=0x12/' "$CONFIG_FILE"
else
    echo "Adding BOOT_ORDER setting..."
    if ! grep -q "BOOT_ORDER=0x12" "$CONFIG_FILE"; then
        cat >> "$CONFIG_FILE" <<EOF

[all]
BOOT_UART=1
BOOT_ORDER=0x12
EOF
    fi
fi

# Ensure BOOT_UART=1 is present
if ! grep -q "BOOT_UART=1" "$CONFIG_FILE"; then
    echo "Adding BOOT_UART=1..."
    cat >> "$CONFIG_FILE" <<EOF

[all]
BOOT_UART=1
BOOT_ORDER=0x12
EOF
fi

echo "Boot configuration settings updated successfully."

echo ""
echo "All configurations completed successfully!"
echo "System is ready for reboot to apply all changes."