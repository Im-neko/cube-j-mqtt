#!/system/bin/sh
# lo / sit0 / wlan0 / p2p 以外のネットワークデバイス(USB 有線 LAN)が現れるまで待ち、DHCP で IP を取る
LOG=/data/local/ethup.log
i=0
while [ $i -lt 150 ]; do
  for n in /sys/class/net/*; do
    d=${n##*/}
    case "$d" in lo|sit0|wlan0|p2p*) continue;; esac
    echo "$(date) found $d" >> $LOG
    ifconfig $d up >> $LOG 2>&1
    dhcpcd $d >> $LOG 2>&1
    ifconfig $d >> $LOG 2>&1
    # adb を TCP 5555 で待ち受けさせる(persist の設定は、電源を入れ直すと消えるため、毎回設定する)
    setprop service.adb.tcp.port 5555 >> $LOG 2>&1
    stop adbd >> $LOG 2>&1
    sleep 1
    start adbd >> $LOG 2>&1
    echo "$(date) adb restarted" >> $LOG
    exit 0
  done
  sleep 2
  i=$((i+1))
done
echo "$(date) no usb ethernet" >> $LOG
