#!/bin/sh
# USB メモリ(FAT32)に書く中身を作る。出力先のルートに CubeJMTS.txt と production_tool/ を置く。
#   setup <出力先>          方法 B(未検証)の 1 回のセットアップ。config/config.json と build/mqtt_bridge.py を含める
#   run   <出力先> <cmd.sh>  汎用のランナー。cmd.sh(例 usb/cmd/install-ethup.sh)を root で実行し、
#                            出力を USB メモリの run-cubej.txt に書く(開始=黄、完了=マゼンタの点滅 5 回)
# 出力先は USB メモリのマウント先か、あとでコピーするための作業ディレクトリ(例 build/usb)。
set -e
D=$(cd "$(dirname "$0")/.." && pwd)
MODE=$1; DEST=$2
[ -n "$MODE" ] && [ -n "$DEST" ] || { echo "usage: $0 setup <dest> | run <dest> <cmd.sh>" >&2; exit 2; }
P="$DEST/production_tool"
mkdir -p "$P"
: > "$DEST/CubeJMTS.txt"
case "$MODE" in
setup)
  [ -f "$D/build/mqtt_bridge.py" ] || { echo "build/mqtt_bridge.py が無い。先に scripts/fetch-bridge.sh を実行する" >&2; exit 1; }
  [ -f "$D/config/config.json" ] || echo "注意: config/config.json が無い(USB メモリには入れずに作る。あとで adb で置く)" >&2
  cp "$D/usb/setup" "$P/production_tool"
  cp "$D/cube/ethup.sh" "$D/cube/ethup.rc" "$D/cube/cubej_bridge.sh" "$D/cube/mqtt_ha_bridge.rc" "$D/build/mqtt_bridge.py" "$P/"
  [ -f "$D/config/config.json" ] && cp "$D/config/config.json" "$P/"
  ;;
run)
  CMD=$3
  [ -f "$CMD" ] || { echo "cmd.sh が無い: $CMD" >&2; exit 2; }
  cp "$D/usb/runner" "$P/production_tool"
  cp "$CMD" "$P/cmd.sh"
  # install-ethup.sh が使うファイル
  cp "$D/cube/ethup.sh" "$D/cube/ethup.rc" "$P/"
  ;;
*) echo "usage: $0 setup <dest> | run <dest> <cmd.sh>" >&2; exit 2 ;;
esac
chmod 755 "$P/production_tool"
ls -la "$DEST" "$P"
