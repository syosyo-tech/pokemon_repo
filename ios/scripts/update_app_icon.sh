#!/usr/bin/env bash
set -euo pipefail

# このスクリプトは Xcode の Run Script Build Phase から呼び出してください。
# 役割: assets/icon/app_icon.png の内容が変わっていたら
#       flutter_launcher_icons を実行して各OSのアイコンを再生成します。

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
ICON_PATH="$ROOT_DIR/assets/icon/app_icon.png"
HASH_FILE="$ROOT_DIR/ios/.app_icon.hash"

if [[ ! -f "$ICON_PATH" ]]; then
  echo "[update_app_icon] icon not found: $ICON_PATH"
  exit 0
fi

# md5 コマンドは環境により md5 / md5sum のどちらか
if command -v md5 >/dev/null 2>&1; then
  CUR_HASH="$(md5 -q "$ICON_PATH")"
else
  CUR_HASH="$(md5sum "$ICON_PATH" | awk '{print $1}')"
fi

PREV_HASH=""
if [[ -f "$HASH_FILE" ]]; then
  PREV_HASH="$(cat "$HASH_FILE" || true)"
fi

if [[ "$CUR_HASH" == "$PREV_HASH" ]]; then
  echo "[update_app_icon] icon not changed, skip"
  exit 0
fi

echo "[update_app_icon] icon changed, generating launcher icons..."
"$FLUTTER_ROOT/bin/flutter" pub get
"$FLUTTER_ROOT/bin/flutter" pub run flutter_launcher_icons

echo "$CUR_HASH" > "$HASH_FILE"
echo "[update_app_icon] done"

