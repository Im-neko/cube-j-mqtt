# 作業の記録の要点(2026-11)

1 台の Cube J を Home Assistant につなぐまでに調べたこと・試したことの要点です。個人の環境の値(IP アドレス・MAC アドレス・ホスト名)と認証情報は載せていません。

## 経緯

1. **J1 向けの USB スクリプトを実行**(kotarou2211/cube-j1-mqtt-webui のもの): 実行は成功(白の点滅 10 回)したが、`CubeJ-XXXXXX` の AP が出ず、自宅の Wi-Fi にもつながらなかった(LED は青の点灯のまま。Wi-Fi の設定の書き直し、WPA2 のみの 2.4GHz の SSID も駄目だった)。
2. **USB メモリの診断**(読み取りだけのスクリプト): 内蔵 Wi-Fi のチップの初期化が毎回失敗していると分かった([付録 A](appendix/wifi-chip-failure.md))。設定の誤りではない。USB の外部ポートはホスト専用で、カーネルに USB 有線 LAN のドライバー(asix・ax88179_178a・cdc_ether・cdc_ncm・rndis_host・smsc95xx など)がある。
3. **有線 LAN**: USB メモリのランナーで `ethup.sh`・`ethup.rc` を置き、RTL8153 をハブ無しで挿して DHCP で IP を取得。adb(TCP 5555)で root のシェルに入れた。
4. **ブリッジの起動**: `stop ndechonetd` → ブリッジ起動。最初は MQTT の認証エラー(code 5)。ブローカーのユーザーを登録し直して解決し、PAN の検出 → PANA 認証 → 計測値の取得・配信に成功。`cubej_bridge.sh` と差し替えた `mqtt_ha_bridge.rc` で、再起動後も自動で起動することを確かめた。
5. **全パーティションの吸い出し**(下の「吸い出し」)。

## 機器の情報(実機)

- `ro.nextdrive.model=Cube-J`、ファームウェア 3.2.36(system_b、2018-07)。system_a は 3.2.0007(2017-07)。
- Linux 3.10.0 #25 SMP PREEMPT(2018-07-09 のビルド、gcc 4.6.x-google)、ARMv7、Rockchip RK3128。
- Python 2.7.13(termios などの標準モジュールあり)。`/` の空きは約 16MB、`/data` は約 12GB。
- Wi-Fi は SDIO 接続の Broadcom BCM4345 rev6(AP6255 系)で、プロパティ `nextdrive.wifi_module=ap6212` とは食い違う。Wi-SUN は `/dev/ttyS1`(115200bps)。
- eMMC(`mmcblk0`)のパーティション: uboot・misc・boot_a・boot_b・recovery・kpanic・cache・backup・system_a・system_b・userdata(と rpmb)。A/B の 2 スロットで、起動中は b(root=mmcblk0p10、system_b がルートファイルシステム)。`/system` を書き換えると system_b が変わる。スロットの切り替えは uboot(misc)の操作が要り、試していない。
- USB の外に出ているポートは EHCI のホスト専用で、PC とつないで adb はできない。ハブ経由では有線 LAN アダプター(RTL8153)のリンクが上がらなかった(電力不足の疑い)。ハブ無しの直挿しで動いた。
- 起動時に待ち受けているポート: adbd(5555。TCP の設定があるとき)、80・443・8883。
- サービス(system_b の `/system/etc/init/`): `ndechonetd`(Wi-SUN、`/dev/ttyS1`)、`EchonetLiteAgent`、`NDCloudDaemon`、`gndctrl`(ボタン・LED・USB メモリの自動実行)、`wifimgr`、`bluejizz` など。

## この構成にした理由

実機で確かめたことです(1 台だけなので、個体差か J 全体の特徴かは分かりません)。

- **Wi-SUN(`/dev/ttyS1`)**: 標準のサービス `ndechonetd`(`/usr/sbin/ndechonetd /dev/ttyS1 1`)が握っているので、ブリッジの前に `stop ndechonetd` が要る。止めても `gndctrl` は ndechonetd を再起動しなかった(15 秒観察)が、再起動すると元に戻るので、起動のたびにラッパー(`cube/cubej_bridge.sh`)が止める。J1 向けのスクリプトが無効化する `wisund`・`NDEcLiteAgent` のバイナリは、J の system_b には無い(スタブの rc を作っても何も止まらない)。
  - 推測(未確認): ndechonetd の rc を `disabled` にすれば、ラッパーで止めなくても済む。元の rc の退避が要るので試していない。
- **ブリッジ本体**: J でも、ブリッジ(`mqtt_bridge.py`)を変更せずに使えた。`/dev/ttyS1` の SKSTACK コマンドで、PAN のスキャン → PANA 認証 → 計測値の取得まで動いた。`config.json` の形・トピック・Home Assistant の自動登録は [setup.md](setup.md)・[home-assistant.md](home-assistant.md) のとおり。
- **ネットワークと adb の起動**: `persist.adb.tcp.port` は、電源を入れ直すと -1 に戻っていた。persist の設定に頼らず、`ethup.sh` が起動のたびに adb の TCP 5555 を設定する。標準のファームウェアは有線 LAN を自動で上げない。
- **ブリッジの起動の順番**: 内蔵 Wi-Fi が使えず、ネットワークが付く前にブリッジを起動しても MQTT につながらない。ラッパーが IP を待つ。
- **ブリッジ本体の控え**: `/data/local/` の自前のファイル(config.json・mqtt_bridge.py)が、ある電源の入れ直しのあとで消えていた(その後は消えなかった。原因は分かっていない)。ブリッジ本体は `/system/etc/cubej/` に控えを置き、無ければラッパーがコピーする。config.json は認証情報なので `/data/local` にだけ置く。
- MQTT の `connection refused code 5` は、ブローカーの認証エラー(ユーザー名かパスワードの誤り)で、ネットワークの問題ではない。

## USB メモリの自動実行の仕組み(J)

`gndctrl` が USB メモリ(`/mnt/usb`)に `CubeJMTS.txt` を見つけると、`/usr/sbin/launch_pt_init.sh` を実行します。このスクリプトは、`/mnt/usb/production_tool/` があれば `/tmp/production_tool/` にコピーし、`production_tool/production_tool` を root で実行します。J でも動きました。

## 本体リセット(ボタンの長押し)で初期化されるもの

コードの読み取り(`gndctrl` の逆アセンブル、uboot・recovery のイメージ)からの推定です。実機でリセットはしていません。

- ボタンは `/dev/input/event0` の KEY_POWER。`gndctrl` が押している時間を数える。
  - 約 3 秒超: AP モード・Wi-Fi の設定に関わる処理
  - 約 8 秒超: LED を赤の点灯にして、`reboot(…, "erase_userdata")`。uboot → recovery の `--wipe_all` が userdata(`/data`)を `mkfs.ext4` で作り直す
- **消えるもの**: `/data` の全部(`/data/local/config.json`、ログ、NextDrive のクラウドとの関連付けなど)
- **残るもの**: `/system`(このリポジトリで置いたファイルを含む)、boot・uboot・recovery など
- 確かめていないこと: uboot が実際に `--wipe_all` を渡すか、リセット後の初回起動の様子。

## 吸い出し(バックアップ)

作業の前後に、adb の `dd` で eMMC の全パーティションを吸い出し、機器側と md5 を照合しました。このリポジトリには、イメージを含めません(大きく、機器の固有の値と認証情報を含むため)。

- 取れたもの: 先頭 4MB(ローダー領域)、uboot・misc・boot_a・boot_b・recovery・kpanic・cache・backup・system_a・system_b(各 768MB)・userdata。
- 取れないもの: rpmb(認証鍵が要る)。この機器に eMMC の boot0/boot1 は無い。
- 取り方の例(Cube の IP は例。パーティションごとに `adb exec-out` で PC に流す。実際の吸い出しは adb の `dd` で行ったが、下のコマンドはその形を書き直した例で、この形のまま実行したことはない):

```sh
adb -s 192.0.2.3:5555 shell 'ls -l /dev/block/by-name/'
adb -s 192.0.2.3:5555 exec-out 'dd if=/dev/block/by-name/boot_b bs=1M 2>/dev/null' > boot_b.img
adb -s 192.0.2.3:5555 shell 'md5sum /dev/block/by-name/boot_b'; md5sum boot_b.img
```

- 注意: **userdata のイメージには認証情報**(B ルートの ID・パスワード、MQTT、Wi-Fi のパスワード)が入る。人に渡す前に必ず除く。
- 吸い出しは、J1 向けの USB スクリプトと有線 LAN のブリッジを入れた**後**の状態。工場出荷時そのものの吸い出しは無い。

## 元に戻す(返品・譲渡の前)

> [!NOTE]
> **未実行**です。ファイルの一覧と、それを消すコマンドを手順として書いただけで、実機で実行したことはありません。

このリポジトリと J1 向けの USB スクリプトが `/system` に置くファイルは、すべて新しく作るファイルです(J の元の構成には無かった。スクリプトが作る rc の日付と、スクリプトの実装の読み取りからの判断)。

1. 次を消す:
   - `/system/etc/init/`: `ethup.rc`・`mqtt_ha_bridge.rc`・(J1 向けの USB スクリプトを実行していれば)`wisund.rc`・`ndeclite_agent.rc`・`config_web.rc`
   - `/system/bin/`: `ethup.sh`・`cubej_bridge.sh`
   - `/system/etc/cubej/`
   - `/data/local/` の自前のファイル: `config.json`(認証情報)・`mqtt_bridge.py`・`config_web.py`・`led_effect.sh`・各ログ・`cubej-backup/`
2. 電源を入れ直し、`ndechonetd`・`wpa_supplicant` などの元のサービスが起動することを、`getprop init.svc.*` と `dmesg` で確かめる

```sh
CUBE="-s 192.0.2.3:5555"
adb $CUBE shell 'mount -o rw,remount /; rm -f /system/etc/init/ethup.rc /system/etc/init/mqtt_ha_bridge.rc /system/etc/init/wisund.rc /system/etc/init/ndeclite_agent.rc /system/etc/init/config_web.rc /system/bin/ethup.sh /system/bin/cubej_bridge.sh; rm -rf /system/etc/cubej; sync; mount -o ro,remount /'
adb $CUBE shell 'rm -rf /data/local/config.json /data/local/mqtt_bridge.py /data/local/config_web.py /data/local/led_effect.sh /data/local/*.log /data/local/cubej-backup'
```

`ethup` を消すと、次の起動から有線 LAN も adb も上がらなくなります。消すのは最後にしてください。`/data` の残りを消すなら、本体リセット(約 8 秒の長押し)も使えます(上の推定のとおり、`/system` は消えない)。
