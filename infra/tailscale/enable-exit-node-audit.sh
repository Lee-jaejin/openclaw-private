#!/bin/bash
# Configure a Linux Tailscale exit node with NAT + egress flow logging.
# Run this script on the exit-node host (not inside OpenClaw container).

set -euo pipefail

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "Run as root on the exit-node host."
    exit 1
fi

if ! command -v tailscale &> /dev/null; then
    echo "tailscale CLI not found."
    exit 1
fi

if ! command -v iptables &> /dev/null; then
    echo "iptables not found."
    exit 1
fi

TS_IF="${TS_IF:-tailscale0}"
WAN_IF="${WAN_IF:-$(ip -4 route show default | awk 'NR==1{print $5}')}"
LOG_PREFIX="${LOG_PREFIX:-OC_EGRESS}"
FLOW_LOG_PATH="${FLOW_LOG_PATH:-/var/log/openclaw/egress-flow.log}"

if [[ -z "$WAN_IF" ]]; then
    echo "Could not determine WAN_IF. Set WAN_IF explicitly."
    exit 1
fi

mkdir -p "$(dirname "$FLOW_LOG_PATH")"

echo "Enabling IPv4 forwarding..."
sysctl -w net.ipv4.ip_forward=1 >/dev/null

echo "Configuring NAT for exit-node forwarding..."
iptables -t nat -C POSTROUTING -o "$WAN_IF" -j MASQUERADE 2>/dev/null \
    || iptables -t nat -A POSTROUTING -o "$WAN_IF" -j MASQUERADE

echo "Installing forwarding rules..."
iptables -N OC_EGRESS_AUDIT 2>/dev/null || true
iptables -F OC_EGRESS_AUDIT
iptables -A OC_EGRESS_AUDIT -m conntrack --ctstate NEW,ESTABLISHED,RELATED \
    -m limit --limit 30/second --limit-burst 60 \
    -j LOG --log-prefix "$LOG_PREFIX " --log-level 6
iptables -A OC_EGRESS_AUDIT -j ACCEPT

iptables -C FORWARD -i "$TS_IF" -o "$WAN_IF" -j OC_EGRESS_AUDIT 2>/dev/null \
    || iptables -A FORWARD -i "$TS_IF" -o "$WAN_IF" -j OC_EGRESS_AUDIT
iptables -C FORWARD -i "$WAN_IF" -o "$TS_IF" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null \
    || iptables -A FORWARD -i "$WAN_IF" -o "$TS_IF" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

echo "Advertising this node as a Tailscale exit node..."
tailscale set --advertise-exit-node=true

if command -v rsyslogd &> /dev/null && [[ -d /etc/rsyslog.d ]]; then
    RSYSLOG_CONF="/etc/rsyslog.d/30-openclaw-egress.conf"
    cat > "$RSYSLOG_CONF" <<EOF
:msg, contains, "$LOG_PREFIX " $FLOW_LOG_PATH
& stop
EOF
    if command -v systemctl &> /dev/null; then
        systemctl restart rsyslog || true
    fi
    echo "rsyslog routing configured: $RSYSLOG_CONF"
else
    echo "rsyslog not detected. Use journalctl -k -g \"$LOG_PREFIX\" for flow logs."
fi

echo ""
echo "Exit-node audit setup complete."
echo "- Exit interface: $WAN_IF"
echo "- Tailscale interface: $TS_IF"
echo "- Log prefix: $LOG_PREFIX"
echo "- Flow log path: $FLOW_LOG_PATH"
