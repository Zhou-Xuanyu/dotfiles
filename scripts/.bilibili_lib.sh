#############################################
# claude generated code which haven't be check by human
#############################################
# .bilibili_lib.sh — shared logic for gunquxuexi (ban) and the unban script.
# Sourced, not executed.
# Missing hosts entries / Caddy block are created automatically (in unbanned state).
CADDYFILE="/opt/homebrew/etc/Caddyfile"
HOSTSFILE="/etc/hosts"
REDIRECT="canvas.illinois.edu/"
BILI_HOSTS=(bilibili.com www.bilibili.com m.bilibili.com search.bilibili.com
            space.bilibili.com live.bilibili.com t.bilibili.com b23.tv)

ensure_hosts() {
    local missing=()
    for host in "${BILI_HOSTS[@]}"; do
        grep -qE "^#?127\.0\.0\.1 ${host//./\\.}$" "$HOSTSFILE" || missing+=("$host")
    done
    [[ ${#missing[@]} -eq 0 ]] && return
    echo "Adding missing hosts entries: ${missing[*]}"
    {
        echo "# bilibili ban (managed by gunquxuexi)"
        for host in "${missing[@]}"; do
            echo "#127.0.0.1 $host"
            echo "#::1 $host"
        done
    } | sudo tee -a "$HOSTSFILE" >/dev/null
}

ensure_caddy() {
    [[ -f "$CADDYFILE" ]] && grep -q "# BEGIN_BILIBILI_BAN" "$CADDYFILE" && return
    echo "Adding bilibili block to $CADDYFILE"
    local http_hosts="" https_hosts=""
    for host in "${BILI_HOSTS[@]}"; do
        http_hosts+="http://$host, "
        https_hosts+="https://$host, "
    done
    cat >> "$CADDYFILE" <<EOF
# BEGIN_BILIBILI_BAN
#${http_hosts%, } {
#	redir http://${REDIRECT} 302
#}
#${https_hosts%, } {
#	tls internal
#	redir https://${REDIRECT} 302
#}
# END_BILIBILI_BAN
EOF
}

is_banned() {
    grep -q "^127\.0\.0\.1 bilibili\.com$" "$HOSTSFILE"
}

toggle_hosts() {
    local action="$1"  # ban | unban
    for host in "${BILI_HOSTS[@]}"; do
        escaped="${host//./\\.}"
        if [[ "$action" == "ban" ]]; then
            # remove leading # if present
            sudo sed -i '' -E "s/^#((127\.0\.0\.1|::1) ${escaped})$/\1/" "$HOSTSFILE"
        else
            # add leading # if not already commented
            sudo sed -i '' -E "s/^((127\.0\.0\.1|::1) ${escaped})$/#\1/" "$HOSTSFILE"
        fi
    done
}

toggle_caddy() {
    local action="$1"  # ban | unban
    python3 - "$CADDYFILE" "$action" <<'PYEOF'
import sys, re

path, action = sys.argv[1], sys.argv[2]
with open(path) as f:
    content = f.read()

pattern = r'(# BEGIN_BILIBILI_BAN\n)(.*?)(# END_BILIBILI_BAN)'

def transform(m):
    start, body, end = m.group(1), m.group(2), m.group(3)
    lines = body.split('\n')
    if action == 'ban':
        # ban = activate caddy redirect (uncomment)
        lines = [(l[1:] if l.startswith('#') else l) for l in lines]
    else:
        # unban = deactivate caddy redirect (comment out)
        lines = [('#' + l if l and not l.startswith('#') else l) for l in lines]
    return start + '\n'.join(lines) + end

content = re.sub(pattern, transform, content, flags=re.DOTALL)
with open(path, 'w') as f:
    f.write(content)
PYEOF
}

reload_all() {
    echo "Reloading Caddy..."
    caddy reload --config "$CADDYFILE" 2>/dev/null || caddy start --config "$CADDYFILE"

    echo "Flushing DNS cache..."
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
}
