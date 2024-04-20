#!/data/data/com.termux/files/usr/bin/env sh

# Some necessary environment variables
GITHUB_URL="https://github.com/George-Seven/Termux-LXC-Guide"
export HOME="/data/data/com.termux/files/home"
GITHUB_DIR="${HOME}/$(basename "${GITHUB_URL}")"
DEPENDENCIES="lxc tsu nano mount-utils pulseaudio termux-tools dos2unix curl git iptables dnsmasq"
export TMPDIR="$(dirname "$(mktemp -u)")"

clear 2>/dev/null

# Check if Termux dependencies are installed
for i in root-repo x11-repo tur-repo ${DEPENDENCIES}; do
  if ! dpkg-query -W -f"\${db:Status-Abbrev}\n" "${i}" 2>/dev/null | grep -Eq "^.i"; then
    [ -z "${apt_update}" ] && { apt update || exit 1; } && apt_update=true
    yes | pkg install -y "${i}" || exit 1
  fi
done

clear 2>/dev/null

# Set correct permissions for configurations directory
# Helpful if you create new configs on the go and don't want to chown, chgrp and chmod them every time to be Termux compatible
sudo test -d "${GITHUB_DIR}" && export SUDO_USER="$(sudo /system/bin/pm list packages -U com.termux | grep -F "package:com.termux " | sed 's/.*://')" || exit 1
sudo chown -R "${SUDO_USER}:${SUDO_USER}" "${GITHUB_DIR}" || exit 1
sudo chgrp -R "${SUDO_USER}" "${GITHUB_DIR}"
sudo restorecon -R "${GITHUB_DIR}" 2>/dev/null >/dev/null
chmod 755 "${GITHUB_DIR}"
cd "${GITHUB_DIR}"
chmod 755 ".git" 2>/dev/null >/dev/null
find . -maxdepth 1 -type f -name "*\.sh" -exec chmod 744 "{}" \;
find . -maxdepth 1 -type f ! -name "*\.sh" -exec chmod 644 "{}" \;
for i in $(find . -maxdepth 1 -type d ! -name "\." ! -name "\.git"); do
  find "${i}" -type d -exec chmod 755 "{}" \;
  find "${i}" -type f -name "*\.sh" -exec chmod 744 "{}" \;
  find "${i}" -type f -name "*\.sh" -exec dos2unix "{}" \; 2>/dev/null >/dev/null
  find "${i}" -type f ! -name "*\.sh" -exec chmod 644 "{}" \;
done

# Correctly configure LXC
# Fixes colors, network, etc.
mkdir -p "${PREFIX}/etc/lxc"
sudo chown -R "${SUDO_USER}:${SUDO_USER}" "${PREFIX}/etc/lxc"
sudo chgrp -R "${SUDO_USER}" "${PREFIX}/etc/lxc"
sudo restorecon -R "${PREFIX}/etc/lxc" 2>/dev/null >/dev/null
chmod 700 "${PREFIX}/etc/lxc"
rm -rf "${PREFIX}/etc/lxc/default.conf"

required_configuration='lxc.net.0.type = veth
lxc.net.0.link = lxcbr0
lxc.net.0.flags = up
lxc.net.0.hwaddr = 00:17:3e:xx:xx:xx
lxc.hook.version = 1
lxc.tty.max = 10
lxc.environment = TERM
lxc.cgroup.devices.allow = a
lxc.mount.auto = cgroup:mixed sys:mixed proc:mixed
lxc.hook.pre-start = "'${GITHUB_DIR}'/src/required-lxc-configuration/scripts/utils/utils.pre-start.sh"
lxc.hook.post-stop = "'${GITHUB_DIR}'/src/required-lxc-configuration/scripts/utils/utils.post-stop.sh"

# Uncomment "lxc.cgroup.memory.limit_in_bytes" to limit max RAM usage allowed for the container (remove the #)
# lxc.cgroup.memory.limit_in_bytes = 3G'

echo "${required_configuration}" > "${PREFIX}/etc/lxc/default.conf"
sudo chown "${SUDO_USER}:${SUDO_USER}" "${PREFIX}/etc/lxc/default.conf"
sudo chgrp "${SUDO_USER}" "${PREFIX}/etc/lxc/default.conf"
sudo restorecon "${PREFIX}/etc/lxc/default.conf" 2>/dev/null >/dev/null
chmod 644 "${PREFIX}/etc/lxc/default.conf"
sudo sh -c "export SUDO_USER='${SUDO_USER}'; src/required-lxc-configuration/scripts/utils/utils.lxc-net.configuration.sh" || exit 1

echo "
 Termux LXC configurations completed.

 If you haven't created a container yet, you can
 create a new Ubuntu container using this command -

  sudo lxc-create -t download -n ubuntu -- --no-validate -d ubuntu -r jammy -a arm64


 You can login to the container using -

  sudo lxc-start -F -n ubuntu

 Eg:- username is 'ubuntu' and password is 'password'
      without quotes.
"

exit 0
