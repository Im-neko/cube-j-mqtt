# 読み取りのみ: 有線 LAN の起動(ethup)の結果の確認
echo "== ethup の状態"
getprop init.svc.ethup
ls -l /system/bin/ethup.sh /system/etc/init/ethup.rc 2>&1
echo "== ethup.log"
cat /data/local/ethup.log 2>&1
echo "== ネットワーク"
ls /sys/class/net
ifconfig -a 2>&1 | grep -A6 -E "^eth|^usb"
cat /sys/class/net/eth0/carrier /sys/class/net/eth0/operstate 2>&1
ip route 2>&1
ps | grep -iE "dhcp|ethup|adbd" 
echo "== dmesg: eth0 / リンク / dhcp / init の ethup"
dmesg 2>&1 | grep -iE "eth0|ethup|dhcp|link is|cdc_ether|r8152|rtl8" | tail -n 30
echo "== logcat(dhcp・ethup・eth0)"
logcat -d 2>&1 | grep -iE "dhcp|ethup|eth0" | tail -n 30
echo "== 待ち受け"
netstat -ln 2>&1 | grep -E ":5555|:8080"
