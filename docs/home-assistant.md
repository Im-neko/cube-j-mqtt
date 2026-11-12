# Home Assistant の設定

## 前提

- MQTT ブローカー(Mosquitto broker のアドオンなど)と、MQTT 統合を設定しておく。
- ブリッジ用の MQTT のユーザーを作り、`config/config.json` の `mqtt_user`・`mqtt_pass` に書く。ブリッジのログに `connection refused code 5` が出たら、このユーザー名かパスワードがブローカーに拒否されている(ブローカー側でユーザーを登録し直して直った)。

## 自動で登録されるセンサー

ブリッジ(`mqtt_bridge.py`)は MQTT の自動検出(MQTT Discovery)に対応しています。ブリッジが起動すると、デバイス「**Cube J1 Smart Meter**」(名前はブリッジの中で固定。J でもこの名前)と、次のセンサーが出ます。

| センサー | ECHONET Lite の EPC | 単位 | トピック(`device_id` が `cubej1` の例) |
|---|---|---|---|
| 瞬時電力 | E7 | W | `cubej/cubej1/power` |
| 積算電力量(正方向=買電) | E0 | kWh | `cubej/cubej1/energy_forward` |
| 積算電力量(逆方向=売電) | E3 | kWh | `cubej/cubej1/energy_reverse` |
| 瞬時電流 R 相 | E8 | A | `cubej/cubej1/current_r` |
| 瞬時電流 T 相 | E8 | A | `cubej/cubej1/current_t` |

自動検出の設定は `homeassistant/sensor/<device_id>/<センサー>/config` に出ます。積算電力量は、係数(D3)と単位(E1)を掛けて kWh にしてあります。

確かめ方: HA の **開発者ツール → 状態** で `cube` を検索し、値が数字で出ていること(`unavailable` ならブリッジが止まっている)。

## ダッシュボードの例

[examples/home-assistant/cube-power-dashboard.yaml](../examples/home-assistant/cube-power-dashboard.yaml) は、上のセンサーを使った電力のダッシュボードの例です(瞬時電力のゲージと推移、今日・今週・今月の使用量、1 時間ごと・1 日ごとの棒グラフ、売電、電流の推移)。

1. **開発者ツール → 状態** で、5 つのエンティティ ID を確かめる。YAML の ID(`sensor.cube_j1_smart_meter_instantaneous_power` など)は、デバイス名とセンサー名から付く推定。違えば YAML の中を全部置き換える(対応表は YAML の冒頭)
2. **設定 → ダッシュボード → ダッシュボードを追加 → 新しいダッシュボードを最初から作成**
3. 作ったダッシュボードを開き、編集 → **︙ → RAW 設定エディタ** に YAML を全部貼って保存

使用量は、買電の積算の長期統計の変化量(`change`)から出しています。統計は 1 時間ごとにまとまるので、最大 1 時間ほど遅れます。統計は Cube をつないだ日からしか無いので、週間・月間のグラフは最初は短くなります。HA の設定ファイルの編集と再起動は要りません。

## エネルギーダッシュボード

**設定 → ダッシュボード → エネルギー** の「電力網」に、

- 電力網からの消費: `Cube J1 Smart Meter Cumulative Energy Fwd`
- 電力網への返還: `Cube J1 Smart Meter Cumulative Energy Rev`

を選ぶと、ほぼリアルタイムの使用量になります。ほかの統計(電力会社のサイトから取り込んだ使用量など)が既に入っていると、使用量を 2 回数えるので、どちらか片方にしてください。

## 使用量をセンサーとして持つ(任意)

使用量をオートメーションで使いたいときは、HA の設定ファイルに `utility_meter` を足して再起動します(ID は確かめたもの)。

```yaml
utility_meter:
  cube_import_daily:
    source: sensor.cube_j1_smart_meter_cumulative_energy_fwd
    cycle: daily
  cube_import_monthly:
    source: sensor.cube_j1_smart_meter_cumulative_energy_fwd
    cycle: monthly
```
