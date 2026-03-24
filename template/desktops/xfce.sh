export XDG_CONFIG_HOME="${HOME}/.sn_desktop_config"
export XDG_DATA_HOME="${HOME}/.sn_desktop_data"
export XDG_DESKTOP_DIR="${HOME}/SN_Desktop"

if [ ! -d "$XDG_CONFIG_HOME" ]; then rsync -av /mnt/shared/public/sn_desktop/.config "$XDG_CONFIG_HOME"; fi
if [ ! -d "$XDG_DATA_HOME" ]; then rsync -av /mnt/shared/public/sn_desktop/data "$XDG_DATA_HOME"; fi
if [ ! -d "$XDG_DESKTOP_DIR" ]; then rsync -av /mnt/shared/public/sn_desktop/Desktop "$XDG_DESKTOP_DIR"; fi

CONFIG="${XDG_CONFIG_HOME}"
DATA="${XDG_DATA_HOME}"

# Remove any preconfigured monitors
if [[ -f "${CONFIG}/monitors.xml" ]]; then
  mv "${CONFIG}/monitors.xml" "${CONFIG}/monitors.xml.bak"
fi

# Copy over default panel if doesn't exist, otherwise it will prompt the user
PANEL_CONFIG="${CONFIG}/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
if [[ ! -e "${PANEL_CONFIG}" ]]; then
  mkdir -p "$(dirname "${PANEL_CONFIG}")"
  cp "/etc/xdg/xfce4/panel/default.xml" "${PANEL_CONFIG}"
fi

# Disable startup services
xfconf-query -c xfce4-session -p /startup/ssh-agent/enabled -n -t bool -s false
xfconf-query -c xfce4-session -p /startup/gpg-agent/enabled -n -t bool -s false

# Disable useless services on autostart
AUTOSTART="${CONFIG}/autostart"
rm -fr "${AUTOSTART}"    # clean up previous autostarts
mkdir -p "${AUTOSTART}"
for service in "pulseaudio" "rhsm-icon" "spice-vdagent" "tracker-extract" "tracker-miner-apps" "tracker-miner-user-guides" "xfce4-power-manager" "xfce-polkit"; do
  echo -e "[Desktop Entry]\nHidden=true" > "${AUTOSTART}/${service}.desktop"
done

# Run Xfce4 Terminal as login shell (sets proper TERM)
TERM_CONFIG="${CONFIG}/xfce4/terminal/terminalrc"
if [[ ! -e "${TERM_CONFIG}" ]]; then
  mkdir -p "$(dirname "${TERM_CONFIG}")"
  sed 's/^ \{4\}//' > "${TERM_CONFIG}" << EOL
    [Configuration]
    CommandLoginShell=TRUE
EOL
else
  sed -i \
    '/^CommandLoginShell=/{h;s/=.*/=TRUE/};${x;/^$/{s//CommandLoginShell=TRUE/;H};x}' \
    "${TERM_CONFIG}"
fi

# launch dbus first through eval becuase it can conflict with a conda environment
# see https://github.com/OSC/ondemand/issues/700
eval $(dbus-launch --sh-syntax)

# Start up xfce desktop (block until user logs out of desktop)
xfce4-session
