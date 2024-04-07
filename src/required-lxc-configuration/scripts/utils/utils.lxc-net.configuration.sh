#!/usr/bin/env sh

if [ $(id -u) -ne 0 ]; then
  echo "Run it with sudo -"
  echo ""
  echo "  sudo bash \""$0"\""
  echo ""
  exit 1
fi

export TMPDIR="$(dirname "$(mktemp -u)")"
if [ -n "${PREFIX}" ] && [ "x${PREFIX}" = "x/data/data/com.termux/files/usr" ]; then
  IS_TERMUX="true"
  LXC_NET_PATH="${PREFIX}/bin/lxc-net."
  chown "${SUDO_USER}" "${PREFIX}/etc/lxc/default.conf"
  chgrp "${SUDO_USER}" "${PREFIX}/etc/lxc/default.conf"
  if ! [ -f "${LXC_NET_PATH}" ]; then
    if ! curl -sL "https://github.com/lxc/lxc/blob/main/config/init/common/lxc-net.in?raw=true" -o "${LXC_NET_PATH}"; then
      "No internet connection"
      exit 1
    fi
  fi
  chown "${SUDO_USER}" "${LXC_NET_PATH}"
  chgrp "${SUDO_USER}" "${LXC_NET_PATH}"
  chmod 755 "${LXC_NET_PATH}"
  termux-fix-shebang "${LXC_NET_PATH}"
  required_configuration='#!/data/data/com.termux/files/usr/bin/env sh

if [ $(id -u) -ne 0 ]; then
  echo "Run it with sudo -"
  echo ""
  echo "  sudo \""$0"\""
  echo ""
  exit 1
fi

case "$1" in
    start|restart|reload|force-reload)
        start-stop-daemon -K -q -n lxc-net. 2>/dev/null >/dev/null
        lxc-net. stop 2>/dev/null >/dev/null
        kill -s 9 $(ps -eo pid,args=cmd | grep -F "logcat -T 1 *:S NetworkController" | awk '\''{print $1}'\'') 2>/dev/null >/dev/null
        exec start-stop-daemon -S -b -q -x "${PREFIX}/bin/lxc-net." -- start
    ;;

    stop)
        start-stop-daemon -K -q -n lxc-net. 2>/dev/null >/dev/null
        lxc-net. stop 2>/dev/null >/dev/null
        kill -s 9 $(ps -eo pid,args=cmd | grep -F "logcat -T 1 *:S NetworkController" | awk '\''{print $1}'\'') 2>/dev/null >/dev/null
    ;;

    *)
        echo "Usage: $0 {start|stop}"
        exit 2
esac

exit $?'
  echo "${required_configuration}" > "${PREFIX}/bin/lxc-net"
  chown "${SUDO_USER}" "${PREFIX}/bin/lxc-net"
  chgrp "${SUDO_USER}" "${PREFIX}/bin/lxc-net"
  chmod 755 "${PREFIX}/bin/lxc-net"
  sed -i '/# Start Termux specific fixes/,/# End Termux specific fixes/d' "${LXC_NET_PATH}"
  required_configuration='# Start Termux specific fixes
getent(){
false
}
# End Termux specific fixes'
  echo "${required_configuration}" | sed -i -e "1r /dev/stdin" "${LXC_NET_PATH}"
  LXC_NET_PATHS="${LXC_NET_PATH}"
else
  IS_TERMUX="false"
  LXC_NET_PATHS="/usr/libexec/lxc/lxc-net /usr/lib/aarch64-linux-gnu/lxc/lxc-net /usr/lib/arm-linux-gnu/lxc/lxc-net /usr/lib/x86_64-linux-gnu/lxc/lxc-net /usr/lib/x86-linux-gnu/lxc/lxc-net"
  sed -i -E 's/.*(ConditionVirtualization=.*)/# \1/g' /usr/lib/systemd/system/lxc-net.service
fi

for LXC_NET_PATH in ${LXC_NET_PATHS}; do
  
  chmod 755 "${LXC_NET_PATH}" 2>/dev/null >/dev/null || continue
  sed -i -E 's/ *\|\| \{ exit 0; \}//g' "${LXC_NET_PATH}"
  
  if [ "x${IS_TERMUX}" = "xtrue" ]; then
    sed -i 's/.*LXC_BRIDGE_MAC=.*/LXC_BRIDGE_MAC="00:17:3e:00:00:00"/g' "${LXC_NET_PATH}"
    sed -i 's/.*LXC_ADDR=.*/LXC_ADDR="10.0.4.1"/g' "${LXC_NET_PATH}"
    sed -i 's#.*LXC_NETWORK=.*#LXC_NETWORK="10.0.4.0/24"#g' "${LXC_NET_PATH}"
    sed -i 's/.*LXC_DHCP_RANGE=.*/LXC_DHCP_RANGE="10.0.4.2,10.0.4.254"/g' "${LXC_NET_PATH}"
    sed -i 's/.*LXC_IPV6_ADDR=.*/LXC_IPV6_ADDR="fc11:4514:1919:811::1"/g' "${LXC_NET_PATH}"
    sed -i 's#.*LXC_IPV6_NETWORK=.*#LXC_IPV6_NETWORK="fc11:4514:1919:811::/64"#g' "${LXC_NET_PATH}"
    sed -i "s#.*distrosysconfdir=.*#distrosysconfdir=\"${PREFIX}/etc/default\"#g" "${LXC_NET_PATH}"
    sed -i "s#.*varrun=.*#varrun=\"${PREFIX}/var/run/lxc\"#g" "${LXC_NET_PATH}"
    sed -i "s#.*varlib=.*#varlib=\"${PREFIX}/var/lib\"#g" "${LXC_NET_PATH}"
    
  fi
  
  sed -i 's/.*LXC_USE_NFT=.*/LXC_USE_NFT="false"/g' "${LXC_NET_PATH}"
  sed -i 's/.*LXC_IPV6_NAT=.*/LXC_USE_NFT="false"/g' "${LXC_NET_PATH}"
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

  if command -v logcat 2>/dev/null >/dev/null; then
    logcat -T 1 *:S NetworkController | grep --line-buffered "CONNECTIVITY_CHANGE" | while read line; do sleep 1; networkFixConnection; done
  fi
  
  return 0
}
# End adjustment for Android iptables'

  echo "${required_configuration}" | sed -i -e "1r /dev/stdin" "${LXC_NET_PATH}"
done

exit 0