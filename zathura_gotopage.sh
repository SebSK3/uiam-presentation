#!/usr/bin/env bash
# zathura_goto_all.sh
# Sends org.pwmt.zathura.GotoPage to all zathura D-Bus instances
# Tracks last page number in /tmp/zathura_pagenumber
# Usage:
#   ./zathura_goto_all.sh          -> increment page by 1 and go to it
#   ./zathura_goto_all.sh 1        -> decrement page by 1 and go to it
#   ./zathura_goto_all.sh <number> -> go directly to <number>

set -u
PREFIX="org.pwmt.zathura.PID-"
PAGE_FILE="/tmp/zathura_pagenumber"

# Initialize page number if missing
if [ ! -f "$PAGE_FILE" ]; then
  echo 1 > "$PAGE_FILE"
fi

# Read current page number
PAGE=$(<"$PAGE_FILE")

# Argument handling
if [ $# -eq 0 ]; then
  # No argument → increment
  PAGE=$((PAGE + 1))
elif [ "$1" = "1" ]; then
  # Argument 1 → decrement
  PAGE=$((PAGE - 1))
  if [ "$PAGE" -lt 1 ]; then
    PAGE=1
  fi
else
  # Direct page number
  PAGE="$1"
fi

# Save the new page number
echo "$PAGE" > "$PAGE_FILE"

echo "Current page: $PAGE"

# Get all active D-Bus names
names_raw=$(dbus-send --session --dest=org.freedesktop.DBus \
  --print-reply --type=method_call \
  /org/freedesktop/DBus org.freedesktop.DBus.ListNames 2>/dev/null)

if [ -z "$names_raw" ]; then
  echo "Could not contact session bus."
  exit 2
fi

# Extract names
mapfile -t names < <(printf '%s\n' "$names_raw" | awk -F'"' '/string /{print $2}')

echo $PAGE

found=0
for name in "${names[@]}"; do
  case "$name" in
    "${PREFIX}"*)
      found=1
      echo "-> Sending GotoPage $PAGE to $name"
      if ! dbus-send --session --dest="$name" --type=method_call \
         /org/pwmt/zathura org.pwmt.zathura.GotoPage uint32:"$PAGE" >/dev/null 2>&1; then
        echo "   [!] failed to send to $name" >&2
      fi
      ;;
  esac
done

if [ $found -eq 0 ]; then
  echo "No D-Bus targets starting with '${PREFIX}' found."
  exit 3
fi

exit 0
