#!/bin/sh
# ブリッジ本体(mqtt_bridge.py)を、動作を確かめた版(kotarou2211/cube-j1-mqtt-webui の固定のコミット)から取得し、
# sha256 を確かめて build/mqtt_bridge.py に置く。このリポジトリには mqtt_bridge.py を含めない(THIRD_PARTY_NOTICES.md)。
set -e
REPO=kotarou2211/cube-j1-mqtt-webui
COMMIT=ceee77c6b53fda0a44197fda72a855c07c9a61da
SHA256=8492c230dafe276beb80922975a2d7a24bfa767b2311eac8c7bb0b0d4aa24f09
D=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$D/build"
OUT="$D/build/mqtt_bridge.py"
curl -fsSL -o "$OUT.tmp" "https://raw.githubusercontent.com/$REPO/$COMMIT/production_tool/mqtt_bridge.py"
echo "$SHA256  $OUT.tmp" | sha256sum -c -
mv "$OUT.tmp" "$OUT"
echo "$OUT ($REPO@$COMMIT)"
