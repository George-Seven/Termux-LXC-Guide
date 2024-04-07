#!/usr/bin/env sh

umount -Rl /dev/binderfs
rm -rf /dev/binderfs
mkdir -p /dev/binderfs
mount -t binder binder /dev/binderfs

for i in binder hwbinder vndbinder; do
  ln -nsf "/dev/binderfs/anbox-${i}" "/dev/${i}"
done

exit 0
