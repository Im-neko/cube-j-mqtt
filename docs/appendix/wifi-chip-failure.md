# 付録 A: 内蔵 Wi-Fi チップの初期化の失敗

1 台の Cube J で、内蔵 Wi-Fi が一度も使えなかった記録です。このリポジトリが有線 LAN を使う理由です。J 全体のことか、この個体だけのことかは分かりません。

## 症状

- J1 向けの USB スクリプト(kotarou2211/cube-j1-mqtt-webui)の実行は成功する(白の点滅 10 回)が、`CubeJ-XXXXXX` の AP が出ない。自宅の Wi-Fi にもつながらない(ルーターの接続一覧に出ない)。LED は青の点灯。
- `wpa_supplicant.conf` の SSID は正しく、設定の誤りではない(WPA2 のみの 2.4GHz の SSID でも同じ)。

## カーネルのログ(事実)

`dmesg` に、次の流れが約 5 秒ごとに、際限なく繰り返し出ていました。

```text
dhdsdio_write_vars: Downloaded NVRAM image is corrupted
... HT Avail timeout ...
wl_android_wifi_on failed (-1)
```

- チップは **BCM4345 rev6(AP6255 系)**。SDIO の F1 signature・チップ ID の読み出しは成功する。
- ドライバー(bcmdhd)は、NVRAM をチップに書き込み → 読み戻し → 比較する(`dhdsdio_write_vars`)。正常なら `Download, Upload and compare of NVRAM succeeded` と出るところが、毎回 **不一致**。
- そのあと `HT Avail timeout`(チップのファームウェアが起動しない)→ `wl_android_wifi_on failed` → wpa_supplicant が status 255 で終了、を繰り返す。`wlan0` は DOWN のまま。AP(p2p)も STA も使えない。

## 試したこと(事実)

- NVRAM のファイル(ap6255 用、2012 バイト)とファームウェア(`fw_bcm43455c0_ag_p2p.bin`)は、中身・大きさとも正常に見える。モジュールの引数は ap6212 のファイルだが、ドライバーが chip ID から ap6255 のファイルに置き換える。
- `config.txt`(元の中身は `ccode=JP` と `regrev=45` の 2 行)に `txglom_mode=0` や `dhd_poll=1` を足しても、同じ失敗(元に戻した)。
- 電源の不足ではない(コンセントに直挿しのアダプター)。

## 推測(確かめていない)

レジスタの読み出しは通るのに、ブロック転送の読み戻しだけが壊れるのは、SDIO のデータ線かクロックの、ハードウェアの不具合・接触不良でよく見られる形。ソフトウェアの設定では直らない見込み。

## 結論

内蔵 Wi-Fi は、ソフトウェアでは復旧できませんでした。代わりに USB 有線 LAN(RTL8153、ハブ無し)を使います — [setup.md](../setup.md)

## 同じ症状か確かめるには

adb かシリアルで root のシェルが使えれば:

```sh
dmesg | grep -E 'NVRAM|HT Avail|wl_android_wifi_on|F1 signature|chip'
getprop nextdrive.wifi_module
ifconfig wlan0
```

adb が使えない(ネットワークが無い)ときは、USB メモリのランナー(`./scripts/make-usb.sh run <USB> <cmd.sh>`)に、上のコマンドを書いた `cmd.sh` を渡すと、結果が USB メモリの `run-cubej.txt` に出ます。
