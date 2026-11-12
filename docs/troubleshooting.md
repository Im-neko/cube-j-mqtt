# トラブルシュート

adb でつながる場合は、まず次を見ます(Cube の IP は例)。

```sh
adb connect 192.0.2.3:5555
adb -s 192.0.2.3:5555 shell
getprop init.svc.mqtt_ha_bridge; getprop init.svc.ndechonetd; getprop init.svc.ethup
tail -n 50 /data/local/mqtt_bridge.log
cat /data/local/ethup.log
ifconfig eth0; ip route
```

## ネットワークにつながらない(adb も届かない)

| 症状 | 原因・確かめること |
|---|---|
| USB 有線 LAN のリンクが上がらない | **ハブ経由**だとリンクが上がらなかった。Cube の USB ポートに直接挿す |
| 有線 LAN の IP が付かない | `ethup.rc`・`ethup.sh` が `/system` に無い(A-1 をやり直す)。`ethup.rc` は起動時に読まれるので、置いた直後は電源の入れ直しが要る |
| 内蔵 Wi-Fi・`CubeJ-XXXXXX` の AP が出ない | 内蔵 Wi-Fi のチップの初期化に失敗している個体がある([付録 A](appendix/wifi-chip-failure.md))。Wi-Fi の設定では直らない |
| adb がつながらない | adb の TCP 5555 は、電源を入れ直すと消える(`persist.adb.tcp.port` が -1 に戻る)。`ethup.sh` が起動のたびに設定する。同時に 2 つの adb をつながない |

adb が届かないときの調べ方: USB メモリのランナー(`./scripts/make-usb.sh run <USB> <cmd.sh>`)で、読み取りだけのコマンドを書いた `cmd.sh` を実行し、USB メモリの `run-cubej.txt` で結果を見る。例: `usb/cmd/check-ethup.sh`(有線 LAN の起動の結果)。

## ブリッジが動かない

| ログ・症状 | 原因・対処 |
|---|---|
| `MQTT: connection refused code 5` | MQTT のユーザー名かパスワードが、ブローカーに拒否された。ネットワークは通っている。ブローカー側でユーザーを登録し直し、`config.json` を送り直す。15 秒ごとに再試行し続けるので、直すまで `stop mqtt_ha_bridge` で止めておく |
| `/dev/ttyS1` が開けない・Wi-SUN の応答が無い | `ndechonetd` が ttyS1 を握っている。`getprop init.svc.ndechonetd` が `running` なら `stop ndechonetd`。`cubej_bridge.sh` 経由で起動していれば自動で止まる |
| `init.svc.mqtt_ha_bridge` が `restarting` を繰り返す | `/data/local/config.json` か `mqtt_bridge.py` が無い。`/data/local` の自前のファイルが電源の入れ直しで消えたことがある(原因不明)。`mqtt_bridge.py` は `/system/etc/cubej/` からラッパーが戻す。`config.json` は adb で送り直す |
| `config_web` が `restarting` を繰り返す | J1 向けの USB スクリプト(kotarou2211/cube-j1-mqtt-webui)が入れた Web 管理画面の rc が残っている。J では使わないので、`/system/etc/init/config_web.rc` を消してよい |
| `MQTT ping: no response (empty)` のあと再接続する | 有線のときから出る既知の挙動。再接続して回復する |
| HA にセンサーが出ない | ブリッジのログに `Measurements:` が出ているか。出ていれば HA 側(MQTT 統合・自動検出のプレフィックス `homeassistant`) |

## 本体のボタンを長押しした(リセット)

約 8 秒の長押しで、userdata(`/data`)だけが初期化されます(コードの読み取りからの推定。[notes.md](notes.md))。`/system` に置いたもの(有線 LAN の起動・ブリッジのラッパー・ブリッジの控え)は残るので、有線 LAN と adb は戻ります。`/data/local/config.json` が消えるので、adb で送り直してください。
