#!/usr/bin/env sh
set -eu
PYTHON="${PYTHON:-python3}"
"$PYTHON" -m pip install --upgrade all-in-one-infer soundfile
"$PYTHON" "$(dirname "$0")/allin1_bridge.py" --probe
echo "First analysis will download model checkpoints and can take a while."
