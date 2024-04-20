#!/usr/bin/env sh

# Pre-start script for LXC containers

[ -n "${LXC_ROOTFS_PATH}" ] && [ -n "${LXC_CONFIG_FILE}" ] || { echo "Variable LXC_ROOTFS_PATH/LXC_CONFIG_FILE not set"; exit 1; }
CONFIG_PATH="$(cd "$(dirname "${0}")"; cd ../../../..; pwd)"
CONFIG_BASENAME="$(basename "${CONFIG_PATH}")"

# This will do a bunch of important things -
# Mount the required cgroups
if ! mountpoint -q /sys/fs/cgroup 2>/dev/null >/dev/null; then
  mkdir -p /sys/fs/cgroup
  mount -t tmpfs -o rw,nosuid,nodev,noexec,relatime cgroup_root /sys/fs/cgroup
fi

for cg in blkio cpu cpuacct cpuset devices freezer memory pids; do
  if ! mountpoint -q "/sys/fs/cgroup/${cg}" 2>/dev/null >/dev/null; then
    mkdir -p "/sys/fs/cgroup/${cg}"
    mount -t cgroup -o "rw,nosuid,nodev,noexec,relatime,${cg}" "${cg}" "/sys/fs/cgroup/${cg}" 2>/dev/null >/dev/null
  fi
done

mkdir -p /sys/fs/cgroup/systemd
mount -t cgroup -o none,name=systemd systemd /sys/fs/cgroup/systemd 2>/dev/null >/dev/null
umount -Rl /sys/fs/cgroup/cg2_bpf 2>/dev/null >/dev/null
umount -Rl /sys/fs/cgroup/schedtune 2>/dev/null >/dev/null
umount -Rl "${LXC_ROOTFS_PATH}" 2>/dev/null >/dev/null

# Sets correct DNS resolver to fix connectivity
sed -i -E 's/^( *#* *)?DNS=.*/DNS=1.1.1.1/g' "${LXC_ROOTFS_PATH}/etc/systemd/resolved.conf"

# Use dnsmasq if available
#sed -i -E 's/^( *#* *)?DNSStubListener=.*/DNSStubListener=no/g' "${LXC_ROOTFS_PATH}/etc/systemd/resolved.conf"
#sed -i -E 's/^( *#* *)?bind-interfaces.*/bind-interfaces/g' "${LXC_ROOTFS_PATH}/etc/dnsmasq.conf"

# Fix connectivity inside container
lxc-net start

# Adds Termux colors
sed -i '/TERM/d' "${LXC_ROOTFS_PATH}/etc/environment"
echo 'TERM="'${TERM}'"' >> "${LXC_ROOTFS_PATH}/etc/environment"

# Use PulseAudio for sound
sed -i '/PULSE_SERVER/d' "${LXC_ROOTFS_PATH}/etc/environment"
echo 'PULSE_SERVER="10.0.4.1:4713"' >> "${LXC_ROOTFS_PATH}/etc/environment"
su "${SUDO_USER}" -c "PATH='${PREFIX}/bin:${PATH}' HOME='${PREFIX}/var/run/lxc-pulse' pulseaudio --start --load='module-native-protocol-tcp auth-ip-acl=10.0.4.0/24 auth-anonymous=1' --exit-idle-time=-1"
restorecon -R "${PREFIX}/var/run/lxc-pulse"

# Remove redundant dialog
# http://c-nergy.be/blog/?p=12073
mkdir -p "${LXC_ROOTFS_PATH}/etc/polkit-1/localauthority/50-local.d"
chmod 755 "${LXC_ROOTFS_PATH}/etc/polkit-1/localauthority/50-local.d"

required_configuration='[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes'

echo "${required_configuration}" > "${LXC_ROOTFS_PATH}/etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla"

# Makes non-funtional udevadm always return true, or else some packages and snaps gives errors when trying to install
if [ ! -e "${LXC_ROOTFS_PATH}/usr/bin/udevadm." ]; then
  mv -f "${LXC_ROOTFS_PATH}/usr/bin/udevadm" "${LXC_ROOTFS_PATH}/usr/bin/udevadm."
fi

required_configuration='#!/usr/bin/bash
/usr/bin/udevadm. "$@" || true'

echo "${required_configuration}" > "${LXC_ROOTFS_PATH}/usr/bin/udevadm"
chmod 755 "${LXC_ROOTFS_PATH}/usr/bin/udevadm"

# Copy temporary config files to rootfs /tmp
rm -rf "${LXC_ROOTFS_PATH}/tmp/${CONFIG_BASENAME}"
mkdir -p "${LXC_ROOTFS_PATH}/tmp"
cp -rf "${CONFIG_PATH}" "${LXC_ROOTFS_PATH}/tmp"

# If LXC is available, fixes running containers like Waydroid
# TODO - add instructions to README.md
# Specifically container LXC package must be built with these two patches applied -
# https://github.com/termux/termux-packages/blob/master/root-packages/lxc/src-lxc-cgroups-cgfsng.c.patch
# https://github.com/termux/termux-packages/blob/master/root-packages/lxc/src-lxc-pam-pam_cgfs.c.patch
if [ -e "${LXC_ROOTFS_PATH}/usr/lib/systemd/system/lxc-net.service" ] || [ -f "${LXC_ROOTFS_PATH}/usr/libexec/lxc/lxc-net" ] || [ -f "${LXC_ROOTFS_PATH}/usr/lib/aarch64-linux-gnu/lxc/lxc-net" ] || [ -f "${LXC_ROOTFS_PATH}/usr/lib/arm-linux-gnu/lxc/lxc-net" ] || [ -f "${LXC_ROOTFS_PATH}/usr/lib/x86_64-linux-gnu/lxc/lxc-net" ] || [ -f "${LXC_ROOTFS_PATH}/usr/lib/x86-linux-gnu/lxc/lxc-net" ]; then
  LD_PRELOAD= chroot "${LXC_ROOTFS_PATH}" usr/bin/sh -c " \
    . '/tmp/${CONFIG_BASENAME}/src/required-lxc-configuration/scripts/utils/utils.set-env.sh'; \
    '/tmp/${CONFIG_BASENAME}/src/required-lxc-configuration/scripts/utils/utils.temp-mount.sh' mount; \
    '/tmp/${CONFIG_BASENAME}/src/required-lxc-configuration/scripts/utils/utils.lxc-net.configuration.sh'; \
    '/tmp/${CONFIG_BASENAME}/src/required-lxc-configuration/scripts/utils/utils.temp-mount.sh' umount; \
  "
fi

# If Waydroid available, fixes Waydroid configs
# TODO - Add instructions to README.md
# Compile kernel with extra binders.
# Originally -
# CONFIG_ANDROID_BINDER_DEVICES="binder,hwbinder,vndbinder"
# Add more like this -
# CONFIG_ANDROID_BINDER_DEVICES="binder,hwbinder,vndbinder,anbox-binder,anbox-hwbinder,anbox-vndbinder"
if [ -e "${LXC_ROOTFS_PATH}/usr/lib/systemd/system/waydroid-container.service" ] || [ -f "${LXC_ROOTFS_PATH}/usr/lib/waydroid/data/scripts/waydroid-net.sh" ] || [ -f "${LXC_ROOTFS_PATH}/var/lib/waydroid/waydroid.cfg" ]; then
  LD_PRELOAD= chroot "${LXC_ROOTFS_PATH}" usr/bin/sh -c " \
    . '/tmp/${CONFIG_BASENAME}/src/required-lxc-configuration/scripts/utils/utils.set-env.sh'; \
    '/tmp/${CONFIG_BASENAME}/src/required-lxc-configuration/scripts/utils/utils.temp-mount.sh' mount; \
    '/tmp/${CONFIG_BASENAME}/src/required-lxc-configuration/scripts/utils/utils.waydroid.configuration.sh'; \
    '/tmp/${CONFIG_BASENAME}/src/required-lxc-configuration/scripts/utils/utils.temp-mount.sh' umount; \
  "
fi

# Fixes iptables command as Android requires legacy mode
rm -rf "${LXC_ROOTFS_PATH}/usr/sbin/iptables" "${LXC_ROOTFS_PATH}/usr/sbin/ip6tables"
ln -nsf /usr/sbin/iptables-legacy "${LXC_ROOTFS_PATH}/usr/sbin/iptables"
ln -nsf /usr/sbin/ip6tables-legacy "${LXC_ROOTFS_PATH}/usr/sbin/ip6tables"

# Sets up container internals
mkdir -p "${LXC_ROOTFS_PATH}/etc/tmpfiles.d"
required_configuration='#Type Path       Mode User Group Age Argument
c!     /dev/cuse  0666 root root  -   10:203
c!     /dev/fuse  0666 root root  -   10:229
c!     /dev/ashmem  0666 root root  -   10:58
# d!     /dev/dri  0755 root root  -   -
# c!     /dev/dri/card0  0666 root root  -   226:0
# c!     /dev/dri/renderD128  0666 root root  -   226:128
c!     /dev/loop-control  0600 root root  -   10:237'
echo "${required_configuration}" > "${LXC_ROOTFS_PATH}/etc/tmpfiles.d/required.lxc-setup.conf"

for i in $(seq -s " " 0 255); do
  echo "b!     /dev/loop${i}  0600 root root  -   7:$((${i} * 8))" >> "${LXC_ROOTFS_PATH}/etc/tmpfiles.d/required.lxc-setup.conf"
done

mkdir -p "${LXC_ROOTFS_PATH}/etc/systemd/system/multi-user.target.wants"
rm -rf "${LXC_ROOTFS_PATH}/usr/lib/required-lxc-configuration"
cp -rf "${LXC_ROOTFS_PATH}/tmp/${CONFIG_BASENAME}/src/required-lxc-configuration" "${LXC_ROOTFS_PATH}/usr/lib"
find "${LXC_ROOTFS_PATH}/etc/systemd/system" -maxdepth 1 -type l -name "required\.*\.service" -delete
find "${LXC_ROOTFS_PATH}/etc/systemd/system/multi-user.target.wants" -maxdepth 1 -type l -name "required\.*\.service" -delete

for i in $(find "${LXC_ROOTFS_PATH}/usr/lib/required-lxc-configuration/services" -maxdepth 1 -type f -name "required\.*\.service"); do
  service_name="$(basename "${i}")"
  ln -nsf "/usr/lib/required-lxc-configuration/services/${service_name}" "${LXC_ROOTFS_PATH}/etc/systemd/system/${service_name}"
  ln -nsf "/etc/systemd/system/${service_name}" "${LXC_ROOTFS_PATH}/etc/systemd/system/multi-user.target.wants/${service_name}"
done

# LXC does not set a default password for us, so we have to set it ourselves.
# We usually need to chroot into the container and manually set the password.
# It's boring to do this for every new container, so we will automate it.
# This one-time hook will set a temporary password called 'password' for the 'root' user and the default user (eg:- 'ubuntu'). 
# This is useful for newbies and you can change it later from inside the container.
# It'll run ONLY ONCE at the very first run of the container, so it won't interfere if the password is changed by the user later on.
# Temporary password for 'root' is 'password' (no quotes).
# Remember to change your password later using command 'passwd'
if ! grep -Eq "^# RESET_PASSWORD_ONCE=done" "${LXC_CONFIG_FILE}"; then
  sed -i '/RESET_PASSWORD_ONCE/d' "${LXC_CONFIG_FILE}"
  LD_PRELOAD= chroot "${LXC_ROOTFS_PATH}" usr/bin/sh -c " \
    . '/tmp/${CONFIG_BASENAME}/src/required-lxc-configuration/scripts/utils/utils.set-env.sh'; \
    '/tmp/${CONFIG_BASENAME}/src/required-lxc-configuration/scripts/utils/utils.temp-mount.sh' mount; \
    echo password | sed 's/.*/\0\n\0/' | passwd root 2>/dev/null >/dev/null; \
    echo password | sed 's/.*/\0\n\0/' | passwd ubuntu 2>/dev/null >/dev/null; \
    '/tmp/${CONFIG_BASENAME}/src/required-lxc-configuration/scripts/utils/utils.temp-mount.sh' umount; \
  "
  echo "# RESET_PASSWORD_ONCE=done" >> "${LXC_CONFIG_FILE}"
fi

# Remove temporary config files from rootfs /tmp
rm -rf "${LXC_ROOTFS_PATH}/tmp/${CONFIG_BASENAME}"

# Sets temporary suid for the rootfs using bind mounts, otherwise normal users inside the container won't be able to use sudo commands
mount -B "${LXC_ROOTFS_PATH}" "${LXC_ROOTFS_PATH}"
mount -i -o remount,suid "${LXC_ROOTFS_PATH}"

exit 0