#!/bin/bash
# Notification module for ralph.sh
# Cross-platform sound and desktop notifications
# Dependencies: None

# Play notification sound cross-platform
# Usage: play_notification_sound
# Supports macOS, Linux (PulseAudio), Windows (WSL), with terminal bell fallback
play_notification_sound() {
  (
    # Try macOS first (afplay)
    if command -v afplay &> /dev/null; then
      afplay /System/Library/Sounds/Glass.aiff 2>/dev/null || true
    # Try Linux (PulseAudio)
    elif command -v paplay &> /dev/null; then
      paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || true
    # Try Windows/WSL (PowerShell)
    elif command -v powershell.exe &> /dev/null; then
      powershell.exe -Command "[System.Media.SystemSounds]::Asterisk.Play()" 2>/dev/null || true
    fi
    # Always try terminal bell as additional notification
    echo -e '\a' 2>/dev/null || true
  ) &
}

# Show desktop notification cross-platform
# Usage: show_notification "title" "message"
# Supports macOS (osascript), Linux (notify-send), fails silently on unsupported platforms
show_notification() {
  local title="$1"
  local message="$2"
  (
    # Try macOS (osascript)
    if command -v osascript &> /dev/null; then
      osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null || true
    # Try Linux (notify-send)
    elif command -v notify-send &> /dev/null; then
      notify-send "$title" "$message" 2>/dev/null || true
    fi
  ) &
}

# Send push notification via self-hosted ntfy
# Usage: send_ralph_ntfy "title" "body"
# Requires: NTFY_URL and NTFY_RALPH_TOPIC env vars
send_ralph_ntfy() {
  local title="$1"
  local body="$2"
  local url="${NTFY_URL:-}"
  local topic="${NTFY_RALPH_TOPIC:-ralph}"

  if [ -z "${url}" ] || ! command -v curl &>/dev/null; then
    return 0
  fi

  (curl -sf \
    -H "Title: ${title}" \
    -H "Priority: high" \
    -d "${body}" \
    "${url}/${topic}" >/dev/null 2>&1 || true) &
}
