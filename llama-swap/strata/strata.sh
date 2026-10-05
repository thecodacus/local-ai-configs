#!/bin/sh
# Start Strata on the port llama-swap hands it: strata.sh PORT [GPU] [CONFIG]
#   no GPU arg = both cards (layer split); "0" = GPU0 only. Context comes from --max-context in the config (128k).
#   CONFIG: a config file in $STRATA_DIR, strata-iq3_xxs.json by default. strata-1gpu passes
#   strata-iq3_xxs-1gpu-vision.json, which adds the image encoder on GPU1 (the card that run leaves free).
# exec, so llama-swap's SIGTERM reaches server.py, which stops the engine.
STRATA_DIR=${STRATA_DIR:-/opt/strata}   # your Strata checkout (installed with its own ./setup.sh)
cd "$STRATA_DIR" || exit 1
port=$1
config=${3:-strata-iq3_xxs.json}
if [ -n "$2" ]; then set -- --gpu "$2"; else set --; fi
exec "$STRATA_DIR/.venv/bin/python" serve/server.py --engine strata --config "$STRATA_DIR/$config" --port "$port" "$@"
