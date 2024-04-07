#!/usr/bin/env sh

# Mounts for temporary chroot
case "$1" in
    mount)
        mkdir -p /proc
        mount -nt proc proc /proc
        mkdir -p /dev
        mount -t tmpfs none /dev
        # mount -nt sysfs sysfs /sys
        # mount -nt tmpfs none /tmp
        mknod -m 622 /dev/console c 5 1
        mknod -m 666 /dev/null c 1 3
        mknod -m 666 /dev/full c 1 7
        mknod -m 666 /dev/zero c 1 5
        mknod -m 666 /dev/ptmx c 5 2
        mknod -m 666 /dev/tty c 5 0
        mknod -m 444 /dev/random c 1 8
        mknod -m 444 /dev/urandom c 1 9
        ln -nsf /proc/self/fd /dev/fd
        ln -nsf /proc/self/fd/0 /dev/stdin
        ln -nsf /proc/self/fd/1 /dev/stdout
        ln -nsf /proc/self/fd/2 /dev/stderr
        ln -nsf /proc/kcore /dev/core
        chown -v root:tty /dev/console 2>/dev/null >/dev/null
        chown -v root:tty /dev/ptmx 2>/dev/null >/dev/null
        chown -v root:tty /dev/tty 2>/dev/null >/dev/null
        mkdir -p /dev/pts
        mount -t devpts devtpts /dev/pts
        mkdir -p /dev/shm
        mkdir -p /tmp
        chmod 1777 /tmp
    ;;

    umount)
        umount -Rl /dev
        umount -Rl /proc
    ;;

    *)
        echo "Usage: $0 {mount|umount}"
        exit 1
esac

exit 0
