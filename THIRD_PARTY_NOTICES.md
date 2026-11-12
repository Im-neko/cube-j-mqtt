# サードパーティの表示

このリポジトリは kotarou2211/cube-j1-mqtt-webui のフォークです(元は tsuyopon123/cube-j1-mqtt)。上流の履歴を含み、Cube J 向けの手順・スクリプト・記録を足しています。このリポジトリ自身のライセンスは [LICENSE](LICENSE)(MIT License。上流の著作権表示を残し、追加分の表示を足した)です。このファイルには、このリポジトリが取得して使う・形を写した他者のファイルの出典と、その著作権表示・許諾の文を、MIT License の条件(著作権表示と許諾の文を含めること)に従って載せます。

## 取得して使うもの

| ファイル | 取得元 | 扱い |
|---|---|---|
| `mqtt_bridge.py`(ブリッジ本体) | kotarou2211/cube-j1-mqtt-webui の `production_tool/mqtt_bridge.py`(コミット `ceee77c6b53fda0a44197fda72a855c07c9a61da`) | このリポジトリには含めない。`scripts/fetch-bridge.sh` が固定のコミットから取得し、sha256 を確かめる。変更せずに使う。取得したファイルは取得元の MIT License(下の表示と同じ)に従う |

## 形を写したファイル

| このリポジトリのファイル | 参考元のファイル | 変えたところ |
|---|---|---|
| `cube/mqtt_ha_bridge.rc` | tsuyopon123/cube-j1-mqtt・kotarou2211/cube-j1-mqtt-webui の `production_tool/mqtt_ha_bridge.rc` | 起動するコマンドを `/usr/bin/python /data/local/mqtt_bridge.py` から `/system/bin/cubej_bridge.sh` に変えた。`class`・`user`・`group`・`seclabel` の行は同じ |
| `config/config.example.json` | 同じ 2 つのリポジトリの `production_tool/config.json` | キーと `mqtt_port`・`device_id`・`serial_port`・`poll_interval` の値は同じ。認証情報と接続先の値をプレースホルダー(`mqtt_host` は例示用のアドレス 192.0.2.10)にした |
| `cube/ethup.rc` | 同じ 2 つのリポジトリの `production_tool/mqtt_ha_bridge.rc` | rc の書式(`class late_start`・`user root`・`group root`・`seclabel u:r:shell:s0`)に従い、サービス名とコマンドを `ethup`・`/system/bin/ethup.sh` にして `oneshot` を足した |

## 流れを参考にしたもの

`usb/setup`・`usb/runner`・`scripts/make-usb.sh` は、tsuyopon123/cube-j1-mqtt の `production_tool/production_tool` の流れ(USB メモリの `CubeJMTS.txt` で `/tmp/production_tool` から root で実行される、`/` を rw で再マウントして rc を置く、最後に LED を点滅させる)を参考に、Cube J 向けに新しく書いたものです。

## 著作権表示とライセンス文

元は次の 2 つのリポジトリです。どちらの `LICENSE` も、次の文面と同じです。

- tsuyopon123/cube-j1-mqtt: https://github.com/tsuyopon123/cube-j1-mqtt
- kotarou2211/cube-j1-mqtt-webui: https://github.com/kotarou2211/cube-j1-mqtt-webui

```text
MIT License

Copyright (c) 2026 tsuyopon

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
