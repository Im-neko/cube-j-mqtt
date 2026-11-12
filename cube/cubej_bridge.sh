#!/system/bin/sh
# 有線 LAN(eth0)の IP が付くのを待ち、ttyS1 を握る ndechonetd を止めてから、ブリッジを起動する
i=0
while [ $i -lt 120 ]; do
  ifconfig eth0 2>/dev/null | grep "inet addr" >/dev/null && break
  sleep 2
  i=$((i+1))
done
[ -f /data/local/mqtt_bridge.py ] || cp /system/etc/cubej/mqtt_bridge.py /data/local/mqtt_bridge.py
stop ndechonetd
sleep 1
exec /usr/bin/python /data/local/mqtt_bridge.py
