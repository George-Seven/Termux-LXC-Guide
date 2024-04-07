#!/usr/bin/env sh

mount -o remount,rw /sys/fs/cgroup

for cg in schedtune cpu cpuacct cpu,cpuacct; do
  umount -Rl "/sys/fs/cgroup/${cg}" 2>/dev/null >/dev/null
  rm -rf "/sys/fs/cgroup/${cg}"
done

for cg in cpu cpuacct; do
  mkdir -p "/sys/fs/cgroup/${cg}"
  mount -t cgroup -o "rw,nosuid,nodev,noexec,relatime,${cg}" "${cg}" "/sys/fs/cgroup/${cg}"
done

mount -o remount,ro /sys/fs/cgroup

# Fix permission of deb files for _apt user
# find /home -type f -name '*\.deb' -exec setfacl -m u:_apt:rwx '{}' +

exit 0
