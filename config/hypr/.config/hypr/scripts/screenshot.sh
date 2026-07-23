#!/bin/sh
DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILE="$DIR/$(date +%Y%m%d_%H%M%S).png"
TMP="$(mktemp /tmp/screenshot-freeze-XXXXXX.png)"

grim "$TMP" || { rm -f "$TMP"; exit 1; }

# Freeze the live view
hyprpicker -r -z -q &
HPID=$!
sleep 0.15

cleanup() {
	kill "$HPID" 2>/dev/null
	wait "$HPID" 2>/dev/null
	rm -f "$TMP"
}
trap cleanup EXIT INT TERM

# Run slurp: capture geometry to stdout, Escape/Esc messages to stderr
REGION="$(slurp 2>/tmp/slurp-err)"

kill "$HPID" 2>/dev/null
wait "$HPID" 2>/dev/null
trap - EXIT INT TERM

# Check if Escape was pressed (requires patched slurp)
if grep -q "ESC pressed" /tmp/slurp-err 2>/dev/null; then
	rm -f /tmp/slurp-err
	exit 0
fi
rm -f /tmp/slurp-err

RW=0
RH=0
if [ -n "$REGION" ]; then
	RW=$(echo "$REGION" | cut -d' ' -f2 | cut -dx -f1)
	RH=$(echo "$REGION" | cut -d' ' -f2 | cut -dx -f2)
fi

crop_from() {
	GX=$(echo "$1" | cut -d, -f1)
	GY=$(echo "$1" | cut -d, -f2 | cut -d' ' -f1)
	GW=$(echo "$1" | cut -d' ' -f2 | cut -dx -f1)
	GH=$(echo "$1" | cut -d' ' -f2 | cut -dx -f2)
	convert "$TMP" -crop "${GW}x${GH}+${GX}+${GY}" +repage "$FILE"
}

if [ -z "$REGION" ] || [ "$RW" -le 1 ] || [ "$RH" -le 1 ]; then
	# Clicked (no drag): capture the focused/active window, else full screen.
	GEOM=$(hyprctl activewindow -j 2>/dev/null | python3 -c "
import sys, json
try:
	w = json.load(sys.stdin)
	at = w.get('at', [0, 0])
	sz = w.get('size', [0, 0])
	if sz[0] > 0 and sz[1] > 0:
		print(f'{at[0]},{at[1]} {sz[0]}x{sz[1]}')
except Exception:
	pass
")
	if [ -n "$GEOM" ]; then
		crop_from "$GEOM"
	else
		cp "$TMP" "$FILE"
	fi
else
	crop_from "$REGION"
fi

rm -f "$TMP"
wl-copy < "$FILE" && swappy -f "$FILE" && notify-send -i image-x-generic-symbolic "Screenshot saved" "$FILE"
