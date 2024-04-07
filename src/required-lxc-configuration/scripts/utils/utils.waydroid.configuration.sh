#!/usr/bin/env sh

if [ $(id -u) -ne 0 ]; then
  echo "Run it with sudo -"
  echo ""
  echo "  sudo bash \""$0"\""
  echo ""
  exit 1
fi

TMPDIR="$(dirname "$(mktemp -u)")"
LXC_NET_PATH="/usr/lib/waydroid/data/scripts/waydroid-net.sh"

chmod 755 "${LXC_NET_PATH}" || exit 1

sed -i -E 's/ *\|\| \{ exit 0; \}//g' "${LXC_NET_PATH}"

sed -i '/lxcFixNetwork/d' "${LXC_NET_PATH}"

line_start="$(($(grep -nm 1 -F "start)" "${LXC_NET_PATH}" | sed 's/:.*//')+1))"
line_end="$(wc -l "${LXC_NET_PATH}" | sed 's/ .*//')"
for i in $(seq -s " " "${line_start}" "${line_end}"); do
  if sed -n "${i}{p;q}" "${LXC_NET_PATH}" | grep -q "start"; then
    sed -i "${i}s/.*/        \( start )\n        lxcFixNetwork/" "${LXC_NET_PATH}"
    break
  fi
done

sed -i '/# Start adjustment for Android iptables/,/# End adjustment for Android iptables/d' "${LXC_NET_PATH}"
required_configuration='# Start adjustment for Android iptables

if [ $(id -u) -ne 0 ]; then
  echo "Run it with sudo -"
  echo ""
  echo "  sudo \""$0"\""
  echo ""
  exit 1
fi

lxcFixNetwork(){
  networkFixConnection(){
    
    IP_ROUTE="$(ip route get 8.8.8.8)"
    gateway="$(echo "${IP_ROUTE}" | awk '\''{ for(i=1; i<=NF; i++) { if($i == "via") { print $(i+1); break; } } }'\'')"
    if [ -z "$gateway" ]; then
      echo "No internet connection"
      return 1
    fi
    interface="$(echo "${IP_ROUTE}" | awk '\''{ for(i=1; i<=NF; i++) { if($i == "via") { print $(i+3); break; } } }'\'')"
    
    if ! ip route | grep -q "default via ${gateway} dev ${interface} "; then
      ip route add default via "${gateway}" dev "${interface}"
    fi
    ip rule add pref 1 from all lookup main
    ip rule add pref 2 from all lookup default
  }

  networkFixConnection

  return 0
}
# End adjustment for Android iptables'

echo "${required_configuration}" | sed -i -e "1r /dev/stdin" "${LXC_NET_PATH}"

if [ -f /var/lib/waydroid/waydroid.cfg ]; then
  sed -i -E '/ro\.hardware\.gralloc/d' /var/lib/waydroid/waydroid.cfg
  sed -i -E '/ro\.hardware\.egl/d' /var/lib/waydroid/waydroid.cfg
  if ! grep -q -F '[properties]' /var/lib/waydroid/waydroid.cfg; then
    echo "[properties]" >> /var/lib/waydroid/waydroid.cfg
  fi
  line_start="$(grep -nm 1 -F '[properties]' /var/lib/waydroid/waydroid.cfg | sed 's/:.*//')"
  sed -i "${line_start}a ro.hardware.egl = swiftshader" /var/lib/waydroid/waydroid.cfg
  sed -i "${line_start}a ro.hardware.gralloc = default" /var/lib/waydroid/waydroid.cfg
fi

exit 0
