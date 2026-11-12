# USB 有線 LAN を起動時に自動で有効にする仕組みを入れ(新しいファイル 2 つの追加のみ、既存のファイルは書き換えない)、
# その場で有効にして、結果を出力する。
PT=/tmp/production_tool
echo "== 設置"
mount -o rw,remount /
cp $PT/ethup.sh /system/bin/ethup.sh && chmod 755 /system/bin/ethup.sh
cp $PT/ethup.rc /system/etc/init/ethup.rc && chmod 644 /system/etc/init/ethup.rc
ls -l /system/bin/ethup.sh /system/etc/init/ethup.rc

echo "== いまの USB・ネットワークデバイス"
ls /sys/bus/usb/devices; cat /sys/bus/usb/devices/*/product 2>/dev/null
ls /sys/class/net

echo "== 起動(ethup)と待機"
start ethup
sleep 25
cat /data/local/ethup.log 2>&1
ls /sys/class/net
ifconfig -a 2>&1
ip route 2>&1
getprop | grep -iE "dhcp|net\." 

echo "== adb を TCP 5555 で再起動(ethup.sh と同じ設定。persist にも設定する)"
setprop service.adb.tcp.port 5555
setprop persist.adb.tcp.port 5555
stop adbd
sleep 1
start adbd
sleep 2
ps | grep -i adbd

echo "== 待ち受けポート"
netstat -ln 2>&1 | head -n 30
echo "== iptables"
iptables -L -n 2>&1 | head -n 40
echo "== dmesg: usb / 有線 LAN"
dmesg 2>&1 | grep -iE "usb|eth|asix|ax88|smsc|dm96|cdc_|rndis|hub" | tail -n 40
