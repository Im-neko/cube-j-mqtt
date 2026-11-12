# セットアップ手順(Cube J、有線 LAN)

Cube J を、USB 有線 LAN でネットワークにつなぎ、B ルートの計測値を Home Assistant(MQTT)に送るまでの手順です。方法は 2 つあります。

- **方法 A(動作確認済み)**: USB メモリのランナーで有線 LAN の起動の仕組みを入れ、有線 LAN でつないでから、adb でブリッジを入れる。2026-11 に 1 台の Cube J で、この順番で動いた
- **方法 B(未検証)**: 方法 A で置くファイルを、USB メモリのスクリプト 1 回でまとめて置く。ファイルは方法 A と同じだが、**スクリプトを通しで実行したことはない**
- 迷ったら方法 A を使ってください。どちらも先に「共通の準備」を行います

目次:

- [共通の準備](#共通の準備)
  - [機材とアカウント](#機材とアカウント)
  - [設定ファイルを用意する](#設定ファイルを用意する)
  - [J1 向けの USB スクリプトを実行済みの Cube](#j1-向けの-usb-スクリプトを実行済みの-cube)
- [方法 A: 実機で動いた順番(動作確認済み)](#方法-a-実機で動いた順番動作確認済み)
  - [必要なもの](#必要なもの) / [手順](#手順) / [確認](#確認) / [うまくいかないとき](#うまくいかないとき)
- [方法 B: USB メモリ 1 回のセットアップ(未検証)](#方法-b-usb-メモリ-1-回のセットアップ未検証)
  - [必要なもの](#必要なもの-1) / [手順](#手順-1) / [確認](#確認-1) / [うまくいかないとき](#うまくいかないとき-1)

> [!WARNING]
> どちらの方法も Cube の `/system`(起動中のスロットのルートファイルシステム)を書き換えます。元に戻す方法は [notes.md](notes.md) の「元に戻す」。機器の不具合・ネットワーク上の危険は、利用者の責任で判断してください。

## 共通の準備

### 機材とアカウント

| もの | 備考 |
|---|---|
| Cube J | ファームウェア 3.2.36(system_b)で確認 |
| USB メモリ | FAT32。USB メモリのスクリプトの実行に使う |
| USB 有線 LAN アダプター | **Realtek RTL8153(USB ID 0bda:8153)で確認**。Cube のカーネルの cdc_ether で `eth0` になる。asix・ax88179_178a・smsc95xx などのドライバーもカーネルにある(未確認) |
| LAN ケーブル | ルーターのある LAN へ |
| adb を使える PC | Android の platform-tools。Cube と同じ LAN に置く |
| Home Assistant と MQTT ブローカー | Mosquitto など。MQTT 統合を設定し、ブリッジ用の MQTT のユーザーを作っておく |
| B ルートの認証 ID・パスワード | 電力会社に申し込んで受け取る |

> [!IMPORTANT]
> 有線 LAN アダプターは **ハブを使わず、Cube の USB ポートに直接** 挿してください。ハブ経由ではリンクが上がりませんでした(電力不足の疑い)。

### 設定ファイルを用意する

```sh
git clone https://github.com/Im-neko/cube-j-mqtt.git
cd cube-j-mqtt
cp config/config.example.json config/config.json   # config/config.json は .gitignore 済み
$EDITOR config/config.json
./scripts/fetch-bridge.sh                           # build/mqtt_bridge.py を取得(sha256 を確認)
```

`config/config.json` に書くもの(値は自分で書く。他人に渡さない):

| キー | 中身 |
|---|---|
| `br_id` | B ルートの認証 ID(32 文字) |
| `br_pwd` | B ルートのパスワード(12 文字) |
| `mqtt_host` / `mqtt_port` | MQTT ブローカー(Home Assistant)の IP アドレスとポート(通常 1883) |
| `mqtt_user` / `mqtt_pass` | ブローカーのユーザー名・パスワード |
| `device_id` | HA 上のデバイスの識別子(既定 `cubej1`。トピックとエンティティ ID に入る) |
| `serial_port` | Wi-SUN のシリアル。J でも `/dev/ttyS1` のまま |
| `poll_interval` | 計測値を取りに行く間隔(秒) |

### J1 向けの USB スクリプトを実行済みの Cube

kotarou2211/cube-j1-mqtt-webui(J1 向け)の USB スクリプトを実行した Cube には、`/system/etc/init/` に `wisund.rc`・`ndeclite_agent.rc`(スタブ)・`config_web.rc`・`mqtt_ha_bridge.rc` が新しく作られています。

- `wisund.rc`・`ndeclite_agent.rc`: J には元々そのサービスが無いので、何も止めていない。残しても害は無い(消すなら [notes.md](notes.md) の「元に戻す」)
- `config_web.rc`: `/data/local/config_web.py` が無いと、再起動を繰り返す。J では使わないので、消してよい
- `mqtt_ha_bridge.rc`: 方法 A の A-3 で差し替える

その USB スクリプトの手順の「Cube が出す AP に接続して Wi-Fi を設定」は、内蔵 Wi-Fi が初期化に失敗する個体ではできません([付録 A](appendix/wifi-chip-failure.md))。

## 方法 A: 実機で動いた順番(動作確認済み)

- 確認した Cube には、**先に J1 向けの USB スクリプトを実行してあった**(上の「[J1 向けの USB スクリプトを実行済みの Cube](#j1-向けの-usb-スクリプトを実行済みの-cube)」)。実行していない Cube で方法 A だけを行ったことはない。方法 A で置くファイルはそのスクリプトに依存しない見込みだが、確かめていない
- 下のコマンドは、実際に行った操作(ファイルの送り方は adb push と別の方法も使った)を、手順として書き直したもの。この形のまま通しで実行したことはない

### 必要なもの

- 「[機材とアカウント](#機材とアカウント)」のすべて(USB メモリはランナーの実行に使う)
- 「[設定ファイルを用意する](#設定ファイルを用意する)」で作った `config/config.json` と `build/mqtt_bridge.py`

### 手順

以下、Cube の IP アドレスを `192.0.2.3` として書きます(自分の環境の値に読み替える)。

#### A-1. USB メモリのランナーで、有線 LAN の起動の仕組みを入れる

`usb/runner` は、USB メモリの `production_tool/cmd.sh` を root で実行し、出力を USB メモリの `run-cubej.txt` に書き戻す小さな仕組みです。`usb/cmd/install-ethup.sh` は、`/system/bin/ethup.sh` と `/system/etc/init/ethup.rc` を新しく置きます(既存のファイルは書き換えません)。

```sh
# USB メモリを /media/usb にマウントした例
./scripts/make-usb.sh run /media/usb usb/cmd/install-ethup.sh
sync
```

1. Cube の電源を切り、USB メモリを挿して電源を入れる
2. LED が **黄の点灯** → **マゼンタの点滅 5 回** になったら完了(黄のまま止まったら、スクリプトが途中で止まっている)
3. 電源を切って USB メモリを抜き、PC で `run-cubej.txt` を開いて `ethup.sh`・`ethup.rc` が置かれたことを確かめる

`ethup.rc` は起動時に読まれるので、このときの `start ethup` は「no such service」になります(次の起動から有効)。

#### A-2. 有線 LAN でつなぐ

1. RTL8153 を **ハブ無しで** Cube に挿し、LAN ケーブルをつなぐ
2. 電源を入れる。`ethup.sh` が `eth0` を見つけて DHCP で IP を取り、adb を TCP 5555 で待ち受けさせる
3. ルーターの接続一覧で Cube の IP を調べる(RTL8153 の MAC アドレスで探す)
4. PC から adb でつなぐ

```sh
adb connect 192.0.2.3:5555
adb -s 192.0.2.3:5555 shell 'getprop ro.nextdrive.model; ifconfig eth0'
```

adb の接続は同時に 1 つだけにしてください。

#### A-3. ブリッジを入れる

```sh
CUBE="-s 192.0.2.3:5555"
adb $CUBE shell 'mount -o rw,remount /; mkdir -p /system/etc/cubej /data/local/cubej-backup'
# 置き換える rc を退避(J1 向けの USB スクリプトを実行していた場合にある)
adb $CUBE shell '[ -f /system/etc/init/mqtt_ha_bridge.rc ] && cp -p /system/etc/init/mqtt_ha_bridge.rc /data/local/cubej-backup/'
adb $CUBE push build/mqtt_bridge.py   /system/etc/cubej/mqtt_bridge.py
adb $CUBE push build/mqtt_bridge.py   /data/local/mqtt_bridge.py
adb $CUBE push cube/cubej_bridge.sh   /system/bin/cubej_bridge.sh
adb $CUBE push cube/mqtt_ha_bridge.rc /system/etc/init/mqtt_ha_bridge.rc
adb $CUBE push config/config.json     /data/local/config.json
adb $CUBE shell 'chmod 755 /system/bin/cubej_bridge.sh /data/local/mqtt_bridge.py; chmod 644 /system/etc/init/mqtt_ha_bridge.rc; chmod 600 /data/local/config.json; sync; mount -o ro,remount /'
adb $CUBE reboot
```

- `cubej_bridge.sh` は、`eth0` に IP が付くのを最大 240 秒待ち、`stop ndechonetd` で `/dev/ttyS1` を空けてから、ブリッジを起動します。
- `mqtt_ha_bridge.rc` は、ブリッジを直接ではなく `cubej_bridge.sh` を起動するように差し替えたものです。
- `config.json` には認証情報が入るので、`/data/local` にだけ置きます(`/system` には置かない)。

### 確認

ブリッジが動いているかを確かめます。

```sh
adb connect 192.0.2.3:5555
adb -s 192.0.2.3:5555 shell 'getprop init.svc.mqtt_ha_bridge; getprop init.svc.ndechonetd; tail -n 30 /data/local/mqtt_bridge.log'
```

- `init.svc.mqtt_ha_bridge` が `running`、`init.svc.ndechonetd` が `stopped`
- ログに PAN の検出 → PANA 認証の成功 → `Measurements: {...power_w...}` が出る(初回は数分かかる)
- Home Assistant に「Cube J1 Smart Meter」のデバイスとセンサーが自動で出る([home-assistant.md](home-assistant.md))
- もう一度 `adb reboot` して、再起動後も自動で計測値が出ることを確かめる

### うまくいかないとき

- A-1 で LED が黄のまま止まったら、スクリプトが途中で止まっている。USB メモリの `run-cubej.txt` を見る
- 有線 LAN・adb・ブリッジの症状ごとの原因は [troubleshooting.md](troubleshooting.md)

## 方法 B: USB メモリ 1 回のセットアップ(未検証)

`usb/setup` は、方法 A の A-1 と A-3 で置くファイル(`ethup.sh`・`ethup.rc`・`cubej_bridge.sh`・`mqtt_ha_bridge.rc`・`mqtt_bridge.py`・`config.json`)を、USB メモリから 1 回で置きます。置き換える既存のファイルは、初回だけ `/data/local/cubej-backup/` に退避します。**このスクリプトを通しで実行したことはありません。**

### 必要なもの

- 「[機材とアカウント](#機材とアカウント)」のすべて
- 「[設定ファイルを用意する](#設定ファイルを用意する)」で作った `config/config.json` と `build/mqtt_bridge.py`(どちらも USB メモリに入る)

### 手順

```sh
./scripts/fetch-bridge.sh
./scripts/make-usb.sh setup /media/usb    # config/config.json も USB メモリに入る
sync
```

1. USB メモリだけを挿して電源を入れる。LED が **黄の点灯** → **白の点滅 10 回** で完了。結果は USB メモリの `setup-cubej.txt`
2. 電源を切り、**USB メモリをすぐに抜いて消すか、`config.json` を削除する**(USB メモリに認証情報が残るため)
3. RTL8153 をハブ無しで挿して電源を入れる。以降は方法 A の A-2 の 3. と、下の「確認」と同じ

### 確認

方法 A の「[確認](#確認)」と同じです。

### うまくいかないとき

- 結果は USB メモリの `setup-cubej.txt` に出る
- 動かなかったときは、方法 A に切り替えてください
- 症状ごとの原因は [troubleshooting.md](troubleshooting.md)
