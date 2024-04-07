#!/usr/bin/env sh

# Environment variables for temporary chroot
PATH=/usr/sbin:/usr/bin:/sbin:/bin
HOME=/root
TMPDIR=/tmp
unset LD_PRELOAD
unset PREFIX
unset ANDROID_ROOT
unset ANDROID_DATA
unset SUDO_USER
unset SUDO_GID
