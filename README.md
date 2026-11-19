# cube-j-mqtt

NextDrive **Cube J**(無印)で、スマートメーターの計測値(B ルート)を取り、MQTT で Home Assistant に送るための手順とスクリプトです。Cube J には内蔵の Wi-SUN モジュールがあります。Cube のサービスは 2025-03-31 に終了しています。

- このリポジトリは [kotarou2211/cube-j1-mqtt-webui](https://github.com/kotarou2211/cube-j1-mqtt-webui) のフォークです(元は [tsuyopon123/cube-j1-mqtt](https://github.com/tsuyopon123/cube-j1-mqtt))。Cube J 向けに、B ルートを取って MQTT に出す手順とスクリプトを足したものです。
- このリポジトリが対象にするのは Cube J(無印)だけです(Cube J1 では確かめていません)。ネットワークは **USB 有線 LAN** を使います。
- ブリッジ本体(`production_tool/mqtt_bridge.py`)は、[kotarou2211/cube-j1-mqtt-webui](https://github.com/kotarou2211/cube-j1-mqtt-webui) のものを、変更せずにこのリポジトリに含めています。他者の著作物の出典とライセンスは [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) にまとめています。

> [!WARNING]
> Cube の `/system` を書き換えます。機器の動作不良や、ネットワーク上の危険(adb の TCP 5555 は認証なしで root のシェルになる)が生じる可能性があります。家庭内の LAN だけで、内容を理解したうえで、自分の責任で使ってください。このリポジトリの利用で生じた損害について、作成者は責任を負いません。

## 開発の状況

- **リリース前**(2026-11 時点)。1 台の Cube J で動いた手順をまとめたもので、他の個体・他のファームウェアでは確かめていません。
- 動作の確認:

| 構成 | 状況 |
|---|---|
| USB 有線 LAN(RTL8153、ハブ無し)+ ブリッジ | **動作を確認**。B ルートの計測値(瞬時電力・積算電力量・電流)を MQTT で送信し、再起動後も自動で起動する([docs/setup.md](docs/setup.md) の方法 A)。確認した Cube には先に kotarou2211/cube-j1-mqtt-webui の USB スクリプト(J1 向け)を実行してあり、実行していない Cube では未確認 |
| USB メモリ 1 回のセットアップ(`usb/setup`) | **未検証**。方法 A と同じファイルを置くが、スクリプトを通しで実行したことはない(方法 B) |
| 内蔵 Wi-Fi | この個体では、チップの初期化に失敗して使えない([付録 A](docs/appendix/wifi-chip-failure.md)) |

## Cube J で必要になること

詳しい理由は [docs/notes.md](docs/notes.md) の「この構成にした理由」。

- **有線 LAN**: USB 有線 LAN アダプターを、ハブ無しで Cube に直挿しする。起動のたびに DHCP と adb(TCP 5555)を設定する `ethup.sh`・`ethup.rc` を置く
- **Wi-SUN(`/dev/ttyS1`)の解放**: 標準のサービス `ndechonetd` が `/dev/ttyS1` を握っているので、ブリッジの前に止める
- **ブリッジの起動**: ラッパー `cubej_bridge.sh` が、IP が付くのを待ち、`ndechonetd` を止めてから、ブリッジを起動する

## 必要なもの

- Cube J(ファームウェア 3.2.36 で確認)
- FAT32 の USB メモリ
- USB 有線 LAN アダプター(**RTL8153 で確認**)と LAN ケーブル。**ハブを使わず Cube に直挿し**
- adb を使える PC(Android の platform-tools)、`curl`・`sha256sum`
- Home Assistant と MQTT ブローカー(Mosquitto など)、ブリッジ用の MQTT のユーザー
- B ルートの認証 ID・パスワード(電力会社に申し込む)

## 手順(概要)

方法は 2 つあります。詳しくは [docs/setup.md](docs/setup.md)。

### 方法 A: 実機で動いた順番(動作確認済み)

1. `config/config.example.json` を `config/config.json` にコピーして、B ルートの ID・パスワードと MQTT の接続先を書く(`config/config.json` は git に入らない)
2. `./scripts/make-usb.sh run <USB メモリ> usb/cmd/install-ethup.sh` で USB メモリを作り、Cube に挿して電源を入れる(有線 LAN の起動の仕組みが `/system` に入る)
3. USB メモリを抜き、有線 LAN アダプターを直挿しして電源を入れ直す。ルーターで Cube の IP を調べ、`adb connect <IP>:5555`
4. adb でブリッジ一式(`cube/cubej_bridge.sh`・`cube/mqtt_ha_bridge.rc`・`production_tool/mqtt_bridge.py`・`config.json`)を置いて再起動する
5. Home Assistant に「Cube J1 Smart Meter」のセンサーが自動で出る(デバイス名はブリッジの中で固定。[docs/home-assistant.md](docs/home-assistant.md))

### 方法 B: USB メモリ 1 回のセットアップ(未検証)

方法 A の 3・5 で置くファイルを、USB メモリのスクリプト 1 回でまとめて置きます。スクリプトを通しで実行したことはありません。手順は [docs/setup.md の方法 B](docs/setup.md#方法-b-usb-メモリ-1-回のセットアップ未検証)。

## ドキュメント

| 文書 | 中身 |
|---|---|
| [docs/setup.md](docs/setup.md) | セットアップ手順(共通の準備、方法 A: 動作確認済み、方法 B: 未検証) |
| [docs/home-assistant.md](docs/home-assistant.md) | Home Assistant の設定、センサー、ダッシュボードの例 |
| [docs/troubleshooting.md](docs/troubleshooting.md) | トラブルシュート |
| [docs/notes.md](docs/notes.md) | 機器の情報、この構成にした理由、USB メモリの自動実行の仕組み、本体リセット、吸い出し、元に戻す |
| [付録 A: 内蔵 Wi-Fi チップの初期化の失敗](docs/appendix/wifi-chip-failure.md) | 有線 LAN を使う理由になった、内蔵 Wi-Fi の失敗の記録 |

## ファイル構成

```text
config/                 設定の例(config.example.json)。実際の設定はここに置き、git に入れない
cube/                   Cube の /system に置くファイル
  ethup.sh, ethup.rc      USB 有線 LAN を DHCP で上げ、adb を TCP 5555 で待ち受けさせる
  cubej_bridge.sh         IP を待ち、ndechonetd を止めて、ブリッジを起動する
  mqtt_ha_bridge.rc       ブリッジの rc(cubej_bridge.sh を起動する)
production_tool/       ブリッジ本体(mqtt_bridge.py。上流のまま、変更なし)
usb/                    USB メモリから Cube に実行させるスクリプト
  runner                  汎用のランナー(cmd.sh を root で実行し、結果を USB メモリに書く)
  cmd/install-ethup.sh    ランナーで ethup を置く(方法 A)
  cmd/check-ethup.sh      ランナーで有線 LAN の起動の結果を見る(読み取りのみ)
  setup                   1 回のセットアップ(方法 B、未検証)
scripts/
  make-usb.sh             USB メモリの中身を作る
examples/home-assistant/ ダッシュボードの例
```

## ライセンスと出典

- このリポジトリは、全体が [LICENSE](LICENSE)(MIT License)に従います。
- 他者の著作物(含めているブリッジ本体、形を写した `cube/mqtt_ha_bridge.rc` など)の出典・著作権表示・ライセンス文は [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) に置いています。
- NextDrive・Cube J・Cube J1 は、各社の製品名です。このリポジトリは、NextDrive とは関係ありません。
