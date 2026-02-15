#!/bin/bash
# Summarize proxy access logs into a periodic egress audit report.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [[ -f "$PROJECT_DIR/.env" ]]; then
    # shellcheck disable=SC1090
    source "$PROJECT_DIR/.env"
fi

WINDOW_MINUTES="${AUDIT_WINDOW_MINUTES:-60}"
LOG_FILE="${EGRESS_PROXY_ACCESS_LOG:-$PROJECT_DIR/logs/egress-proxy/access.log}"
OUT_DIR="$PROJECT_DIR/logs/audit"
STAMP="$(date +%Y%m%d_%H%M%S)"
NOW_HUMAN="$(date '+%Y-%m-%d %H:%M:%S %Z')"
REPORT_FILE="$OUT_DIR/egress-audit-$STAMP.md"
LATEST_FILE="$OUT_DIR/latest.md"

usage() {
    echo "Usage: bash scripts/audit-egress.sh [--window MINUTES] [--log LOG_PATH]"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --window)
            WINDOW_MINUTES="$2"
            shift 2
            ;;
        --log)
            LOG_FILE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            usage
            exit 1
            ;;
    esac
done

if ! [[ "$WINDOW_MINUTES" =~ ^[0-9]+$ ]] || [[ "$WINDOW_MINUTES" -le 0 ]]; then
    echo "WINDOW_MINUTES must be a positive integer."
    exit 1
fi

mkdir -p "$OUT_DIR"

if date -v-1M +%s >/dev/null 2>&1; then
    SINCE_EPOCH="$(date -v-"$WINDOW_MINUTES"M +%s)"
else
    SINCE_EPOCH="$(date -d "-$WINDOW_MINUTES minutes" +%s)"
fi

if [[ ! -f "$LOG_FILE" ]]; then
    cat > "$REPORT_FILE" <<EOF
# Egress Audit Report

- Generated: $NOW_HUMAN
- Window: last $WINDOW_MINUTES minutes
- Status: no proxy log file found at \`$LOG_FILE\`
EOF
    cp "$REPORT_FILE" "$LATEST_FILE"
    echo "Audit report written: $REPORT_FILE"
    exit 0
fi

TMP_SUMMARY="$(mktemp)"
trap 'rm -f "$TMP_SUMMARY"' EXIT

awk -v since="$SINCE_EPOCH" '
function normalize_host(method, raw, host, parts) {
    host = raw
    if (method == "CONNECT") {
        split(host, parts, ":")
        host = parts[1]
    } else {
        gsub(/^[a-zA-Z]+:\/\//, "", host)
        split(host, parts, "/")
        host = parts[1]
        split(host, parts, ":")
        host = parts[1]
    }
    if (host == "" || host == "-") {
        host = "unknown"
    }
    return host
}

{
    if (NF < 7) {
        next
    }
    ts = $1
    sub(/\..*$/, "", ts)
    if (ts < since) {
        next
    }

    method = $6
    url = $7
    if (method == "-" || $4 ~ /^NONE_NONE/) {
        next
    }
    split($4, statusParts, "/")
    code = statusParts[2]
    host = normalize_host(method, url)

    total++
    hostCount[host]++
    methodCount[method]++
    codeCount[code]++
}

END {
    print "TOTAL\t" total
    for (h in hostCount) print "HOST\t" hostCount[h] "\t" h
    for (m in methodCount) print "METHOD\t" methodCount[m] "\t" m
    for (c in codeCount) print "CODE\t" codeCount[c] "\t" c
}
' "$LOG_FILE" > "$TMP_SUMMARY"

TOTAL="$(awk -F'\t' '$1=="TOTAL"{print $2}' "$TMP_SUMMARY")"
TOTAL="${TOTAL:-0}"

{
    echo "# Egress Audit Report"
    echo ""
    echo "- Generated: $NOW_HUMAN"
    echo "- Window: last $WINDOW_MINUTES minutes"
    echo "- Source log: \`$LOG_FILE\`"
    echo "- Total requests: $TOTAL"
    echo ""

    echo "## Top Destinations"
    awk -F'\t' '$1=="HOST"{print $2 "\t" $3}' "$TMP_SUMMARY" | sort -nr | head -n 10 | \
    awk -F'\t' '{printf "- %s (%s requests)\n", $2, $1}'
    echo ""

    echo "## Methods"
    awk -F'\t' '$1=="METHOD"{print $2 "\t" $3}' "$TMP_SUMMARY" | sort -nr | \
    awk -F'\t' '{printf "- %s: %s\n", $2, $1}'
    echo ""

    echo "## Response Codes"
    awk -F'\t' '$1=="CODE"{print $2 "\t" $3}' "$TMP_SUMMARY" | sort -nr | \
    awk -F'\t' '{printf "- %s: %s\n", $2, $1}'
    echo ""

    echo "## Notes"
    echo "- CONNECT requests expose destination host:port, not HTTPS payload."
    echo "- To force all egress through Headscale-managed path, keep host on a Tailscale exit node."
} > "$REPORT_FILE"

cp "$REPORT_FILE" "$LATEST_FILE"

echo "Audit report written: $REPORT_FILE"
echo "Latest report: $LATEST_FILE"
