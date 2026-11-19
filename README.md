# cube-j-mqtt

NextDrive **Cube J**(無印)で、スマートメーターの計測値(B ルート)を取り、MQTT で Home Assistant に送るための USB メモリのセットアップです。Cube J の内蔵の Wi-SUN モジュールを使い、ネットワークには **USB 有線 LAN アダプター** を使います。Cube のサービスは 2025-03-31 に終了しています。

このリポジトリは [kotarou2211/cube-j1-mqtt-webui](https://github.com/kotarou2211/cube-j1-mqtt-webui)(元は [tsuyopon123/cube-j1-mqtt](https://github.com/tsuyopon123/cube-j1-mqtt)、Cube J1 向け)のフォークです。出典は末尾の「[ライセンスと出典](#ライセンスと出典)」。

> [!WARNING]
> Cube の `/system` を書き換えます。adb(TCP 5555)が認証なしの root のシェルで待ち受けます。家庭内の LAN だけで、内容を理解したうえで、自分の責任で使ってください。このリポジトリの利用で生じた損害について、作成者は責任を負いません。

## 使い方

1. **USB メモリ(FAT32)に、このリポジトリの中身をそのままコピーする。** USB メモリの直下に `CubeJMTS.txt` と `production_tool/` が来るようにする(GitHub の「Download ZIP」なら、展開してできたフォルダの**中身**をコピーする)。`README.md`・`LICENSE` なども一緒に入ってかまわない。
2. **設定を書く。** USB メモリの `production_tool/config.example.json` を、同じフォルダに `config.json` という名前でコピーし、B ルートの ID・パスワードと MQTT の接続先を書く(下の「[設定](#設定)」)。
3. **Cube の電源を切り、USB メモリを挿して電源を入れる。** LED が **黄の点灯** → **白の点滅 10 回** になったら完了。結果は USB メモリの `setup-cubej.txt` に書かれる。
4. **電源を切って USB メモリを抜く。** USB メモリの `production_tool/config.json` は認証情報なので消す。
5. **USB 有線 LAN アダプターをハブを使わず Cube に直接挿し、LAN ケーブルをつないで電源を入れる。** 数分で Home Assistant にデバイス「Cube J1 Smart Meter」とセンサーが自動で出る(下の「[Home Assistant](#home-assistant)」)。

## 必要なもの

| もの | 備考 |
|---|---|
| Cube J | ファームウェア 3.2.36 で確認 |
| USB メモリ | FAT32(通常のフォーマットでよい。Cube は 1 つ目のパーティション `sda1` を読む) |
| USB 有線 LAN アダプター | **Realtek RTL8153 で確認**(Cube のカーネルの cdc_ether で `eth0` になる)。**ハブを使わず直挿し**(ハブ経由ではリンクが上がらなかった) |
| Home Assistant と MQTT ブローカー | Mosquitto など。MQTT 統合を設定し、ブリッジ用の MQTT のユーザーを作っておく |
| B ルートの認証 ID・パスワード | 電力会社に申し込んで受け取る |

## 設定

`production_tool/config.json`(`config.example.json` をコピーして作る。git には入らない。UTF-8 の BOM 無しで保存する):

| キー | 中身 |
|---|---|
| `br_id` | B ルートの認証 ID(32 文字) |
| `br_pwd` | B ルートのパスワード(12 文字) |
| `mqtt_host` / `mqtt_port` | MQTT ブローカーの IP アドレスとポート(通常 1883) |
| `mqtt_user` / `mqtt_pass` | ブローカーのユーザー名・パスワード |
| `device_id` | Home Assistant 上のデバイスの識別子(既定 `cubej1`。トピックとエンティティ ID に入る) |
| `serial_port` | Wi-SUN のシリアル。`/dev/ttyS1` のまま |
| `poll_interval` | 計測値を取りに行く間隔(秒) |

## USB メモリのスクリプトがすること

Cube は、USB メモリの直下に `CubeJMTS.txt` があると、`production_tool/` を `/tmp/production_tool/` にコピーし、`production_tool/production_tool` を root で実行します(Cube の `/usr/sbin/launch_pt_init.sh`)。このスクリプトは次を行います。

- `/system` に置く: `ethup.sh`・`ethup.rc`(起動のたびに USB 有線 LAN を DHCP で上げ、adb を TCP 5555 で待ち受けさせる)、`cubej_bridge.sh`・`mqtt_ha_bridge.rc`(有線 LAN の IP を最大 240 秒待ち、Wi-SUN の `/dev/ttyS1` を握る標準のサービス `ndechonetd` を止めてから、ブリッジを起動する)、ブリッジ本体の控え `/system/etc/cubej/mqtt_bridge.py`
- `/data/local/` に置く: `mqtt_bridge.py`、`config.json`(権限 600。どちらも既存のものは退避せずに上書きする)
- `/system` の置き換える既存のファイルは、初回だけ `/data/local/cubej-backup/` に退避する。Wi-Fi の設定ファイルには触れない
- `ethup.sh` は、起動時に `lo`・`sit0`・`wlan0`・`p2p*` 以外で最初に見つかったネットワークデバイスを有線 LAN とみなして DHCP をかける。USB Wi-Fi のドングル(`ra0` など)を挿して使っている Cube では、そのドングルに DHCP をかけてしまうので、この構成は向かない

USB メモリに `update.img` を置かないでください(Cube はファームウェアの更新として扱います)。

## Home Assistant

ブリッジは MQTT の自動検出に対応しています。デバイス「**Cube J1 Smart Meter**」(名前はブリッジの中で固定)と、次のセンサーが出ます。

| センサー | 単位 | トピック(`device_id` が `cubej1` の例) |
|---|---|---|
| 瞬時電力 | W | `cubej/cubej1/power` |
| 積算電力量(正方向=買電) | kWh | `cubej/cubej1/energy_forward` |
| 積算電力量(逆方向=売電) | kWh | `cubej/cubej1/energy_reverse` |
| 瞬時電流 R 相・T 相 | A | `cubej/cubej1/current_r`・`current_t` |

エネルギーダッシュボードは、**設定 → ダッシュボード → エネルギー** の「電力網」で、消費に `Cube J1 Smart Meter Cumulative Energy Fwd`、返還に `... Energy Rev` を選びます。

## うまくいかないとき

まず USB メモリの `setup-cubej.txt` を見ます。有線 LAN でつながったら、adb で Cube に入れます(Cube の IP はルーターの接続一覧で、アダプターの MAC アドレスで探す)。

```sh
adb connect <Cube の IP>:5555
adb -s <Cube の IP>:5555 shell 'getprop init.svc.mqtt_ha_bridge; getprop init.svc.ndechonetd; tail -n 30 /data/local/mqtt_bridge.log'
```

`init.svc.mqtt_ha_bridge` が `running`、`init.svc.ndechonetd` が `stopped` で、ログに `Measurements: {...}` が出ていれば動いています(初回は数分かかる)。

| 症状 | 原因・対処 |
|---|---|
| LED が黄のまま | スクリプトが途中で止まった。USB メモリに `setup-cubej.txt` があれば、それを見る |
| `setup-cubej.txt` に「config.json が無い」「雛形の値(`<...>` か 192.0.2.x)が残っている」 | 「設定」をやり直して、もう一度 USB メモリを挿して電源を入れる |
| 有線 LAN の IP が付かない・adb が届かない | アダプターをハブ経由で挿していないか。`ethup.rc` は起動時に読まれるので、セットアップの後に電源の入れ直しが要る |
| ログに `MQTT: connection refused code 5` | MQTT のユーザー名かパスワードがブローカーに拒否された。ブローカーのユーザーと `config.json` を直す(`adb push` で `/data/local/config.json` に送り直すか、USB メモリのセットアップをやり直す) |
| ログに `MQTT ping: no response` のあと再接続 | 既知の挙動。再接続して回復する |
| `init.svc.config_web` が `restarting` を繰り返す | 上流の J1 向けの USB スクリプトを先に実行した Cube に残る rc。`/system/etc/init/config_web.rc` を消してよい |
| 内蔵 Wi-Fi・`CubeJ-XXXXXX` の AP が出ない | 確認した個体では、内蔵 Wi-Fi のチップの初期化が毎回失敗していた。そのため有線 LAN を使う |

本体のボタンの約 8 秒の長押しは `/data` を初期化します(コードの読み取りからの推定)。`/system` に置いたものは残るので、`config.json` だけを送り直してください。

## 開発の状況

**リリース前**(2026-11 時点)。1 台の Cube J(ファームウェア 3.2.36)で確かめたもので、他の個体・ファームウェアでは確かめていません。確かめた Cube には、先に上流の J1 向けの USB スクリプトを実行してありました。

| 確かめたこと | 状況 |
|---|---|
| 有線 LAN(RTL8153、ハブ無し)+ ブリッジで、計測値を MQTT で送る | **確認済み**(2026-11-11)。瞬時電力・積算電力量・電流を送信し、再起動後も自動で起動した。このときは、同じ内容の `ethup.sh`・`ethup.rc`・`mqtt_ha_bridge.rc`・ブリッジ本体と、コメント 1 行だけが違う `cubej_bridge.sh` を、USB メモリの別のスクリプトと adb で置いた |
| USB メモリのスクリプト(`production_tool/production_tool`)の通しの実行 | **確認済み**(2026-11-19)。このリポジトリの中身をコピーした FAT32 を Cube の `/mnt/usb` にマウントし、Cube が USB メモリを見つけたときに実行するのと同じ `/usr/sbin/launch_pt_init.sh` を実行した。全ファイルが置かれ(md5 一致)、`/` は読み取り専用に戻り、`setup-cubej.txt` が USB メモリに書かれ、LED が白で点滅した。2 回目の実行では退避を上書きしなかった |
| セットアップ後の再起動で、ブリッジが自動で起動して計測値が出る | **確認済み**(2026-11-19)。再起動から約 4 分(有線 LAN を待つ 240 秒を含む)でブリッジが起動し、MQTT のブローカーに瞬時電力が 1 分ごとに届いた。ただし、このときの Cube は有線 LAN の代わりに USB Wi-Fi でつながっていたので、`ethup.sh` だけは USB Wi-Fi 用に手を入れた版で再起動した(有線 LAN を上げる部分は上の 2026-11-11 の確認による) |
| Home Assistant にデバイス・センサーが自動で出る | 作業者は Home Assistant の画面では確かめていない。この Cube のセンサーを Home Assistant で使っている実績と、ブリッジが自動検出の設定(`homeassistant/sensor/...`)を送ることによる |
| USB メモリを挿して電源を入れたときの自動の実行 | **未確認**。試験した Cube の USB ポートは別の機器で使っていたため、本物の USB メモリは挿していない。Cube のプログラム(`gndctrl`)が `/dev/block/sda1` を vfat で `/mnt/usb` にマウントし、`CubeJMTS.txt` があれば `launch_pt_init.sh` を実行することは、プログラムの中の文字列から読み取った。上流の J1 向けの USB スクリプトと、同じ仕組みの診断用の USB メモリは、この Cube で実際に動いた |

未確認の点の確かめ方: 「[使い方](#使い方)」の 1〜3 を行い、LED が白で 10 回点滅し、USB メモリに `setup-cubej.txt` ができて `== setup end` の行があれば確認できたことになります。

## ライセンスと出典

- [LICENSE](LICENSE)(MIT License)。上流の著作権表示(Copyright (c) 2026 tsuyopon)を保ち、このフォークの追加分の表示を足しています。
- `production_tool/mqtt_bridge.py`(ブリッジ本体)は、[kotarou2211/cube-j1-mqtt-webui](https://github.com/kotarou2211/cube-j1-mqtt-webui) のコミット `ceee77c` のものを変更せずに含めています(元は [tsuyopon123/cube-j1-mqtt](https://github.com/tsuyopon123/cube-j1-mqtt))。どちらも MIT License で、著作権表示は上の LICENSE と同じです。
- `mqtt_ha_bridge.rc`・`ethup.rc`・`config.example.json` は上流の `mqtt_ha_bridge.rc`・`config.json` の形を写し、`production_tool/production_tool` は上流の同名のスクリプトの流れ(USB メモリから root で実行され、`/` を書き込み可能にして rc を置き、LED を点滅させる)を参考に、Cube J 向けに書いたものです。
- NextDrive・Cube J・Cube J1 は各社の製品名です。このリポジトリは NextDrive とは関係ありません。
