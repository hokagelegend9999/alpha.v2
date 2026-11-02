#!/usr/bin/env bash
set -euo pipefail

WORK_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SCRIPT_FILE="$WORK_DIR/$(basename -- "${BASH_SOURCE[0]}")"
SYSTEMD_DIR=/etc/systemd/system
SERVICE=slowdns.service
ENV_FILE="$WORK_DIR/slowdns.env"
KEY_FILE="$WORK_DIR/server.key"
BINARY=""
UDP_ADDR=""
DOMAIN=""
UPSTREAM=127.0.0.1:22
EXTRA_ARGS=""
DIRECT_IP=""
INTERFACE=""
DIRECT_BINDINGS=""
LISTENER_BINDINGS=""
TEMP_DIR=""

fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }

help() {
	cat <<EOF
SlowDNS installer

Usage: bash $SCRIPT_FILE [install|uninstall]
  No argument   Show the Install / Uninstall menu.
  install       Install or restart using the saved configuration and keys.
  uninstall     Remove the service; keep the configuration, keys, and binary.
  -h, -help, --help
                Show this help without making changes.

Examples:
  sudo bash $SCRIPT_FILE install
  sudo bash $SCRIPT_FILE uninstall

Place the slowdns binary beside this installer. Linux with systemd is required.
Settings: $ENV_FILE
Keys:     $WORK_DIR/server.key and $WORK_DIR/server.pub
EOF
}

ask() {
	local answer
	read -r -p "$1 [$2]: " answer || fail "Input cancelled"
	printf -v "$3" '%s' "${answer:-$2}"
}

check_host() {
	[ "$(id -u)" = 0 ] || fail "Run with sudo bash $SCRIPT_FILE"
	[ "$(uname -s)" = Linux ] || fail "This installer requires Linux with systemd"
	local command
	for command in systemctl ss ip install stat; do
		command -v "$command" >/dev/null || fail "Required command not found: $command"
	done
	[[ "$SCRIPT_FILE" =~ ^/[A-Za-z0-9_./-]+$ ]] || fail "Use an installer path without spaces or special characters"
}

check_owned_files() {
	local file owner mode
	for file in "$@"; do
		[ ! -L "$file" ] || fail "Use regular files in the installation folder, not symbolic links"
		[ -e "$file" ] || continue
		read -r owner mode <<< "$(stat -Lc '%u %a' "$file")"
		[[ "$owner" = 0 && "$mode" =~ ^[0-7]{3,4}$ ]] && (( (8#$mode & 022) == 0 )) ||
			fail "Keep the installation folder and files owned by root and not writable by other users"
	done
}

check_unit() {
	local fragment dropins file="$SYSTEMD_DIR/$SERVICE"
	fragment="$(systemctl show "$SERVICE" --property=FragmentPath --value)"
	dropins="$(systemctl show "$SERVICE" --property=DropInPaths --value)"
	[ -z "$dropins" ] || fail "The service has drop-ins; review them before reinstalling"
	[ -z "$fragment" ] || [ "$fragment" = "$file" ] || fail "The existing service was not created by this installer"
	[ ! -L "$file" ] || fail "The existing service is a symbolic link; review it before continuing"
	[ ! -f "$file" ] || {
		[ -f "$ENV_FILE" ] || fail "The existing service configuration is missing"
		grep -Fxq "WorkingDirectory=$WORK_DIR" "$file" && grep -Fxq "EnvironmentFile=$ENV_FILE" "$file" ||
			fail "The existing service uses a different installation folder or configuration"
	}
}

read_config() {
	local name value seen=" "
	while IFS='=' read -r name value || [ -n "$name" ]; do
		case "$name" in
			SLOWDNS_BINARY|SLOWDNS_UDP_ADDR|SLOWDNS_DOMAIN|SLOWDNS_UPSTREAM_ADDR|SLOWDNS_PRIVKEY_FILE|SLOWDNS_EXTRA_ARGS|SLOWDNS_DIRECT_IPV4|SLOWDNS_DIRECT_INTERFACE|SLOWDNS_DIRECT_BINDINGS) ;;
			*) continue ;;
		esac
		[[ "$seen" != *" $name "* ]] || fail "Duplicate setting: $name"
		seen+="$name "
		case "$value" in \"*\"|\'*\') value="${value:1:${#value}-2}" ;; esac
		case "$value" in *[\"\'\\\$\`%]*|*[[:cntrl:]]*) fail "Unsupported value for $name; configuration was not changed" ;; esac
		case "$name" in
			SLOWDNS_BINARY) BINARY="$value" ;; SLOWDNS_UDP_ADDR) UDP_ADDR="$value" ;;
			SLOWDNS_DOMAIN) DOMAIN="$value" ;; SLOWDNS_UPSTREAM_ADDR) UPSTREAM="$value" ;;
			SLOWDNS_PRIVKEY_FILE) KEY_FILE="$value" ;; SLOWDNS_EXTRA_ARGS) EXTRA_ARGS="$value" ;;
			SLOWDNS_DIRECT_IPV4) DIRECT_IP="$value" ;; SLOWDNS_DIRECT_INTERFACE) INTERFACE="$value" ;;
			SLOWDNS_DIRECT_BINDINGS) DIRECT_BINDINGS="$value" ;;
		esac
	done < "$ENV_FILE"
	case "$KEY_FILE" in /*) ;; *) KEY_FILE="$WORK_DIR/$KEY_FILE" ;; esac
	[ -s "$KEY_FILE" ] || fail "The existing private key is missing or empty; no replacement was created"
}

new_config() {
	local address port
	# Integrasi otomatis menangkap variabel AUTO_NS dari Bot Telegram
	if [[ -n "${AUTO_NS:-}" ]]; then
		DOMAIN=$(echo "$AUTO_NS" | tr -d '[:space:]')
	else
		ask 'SlowDNS domain' '' DOMAIN
	fi
	
	address="auto"
	port="53"
	UPSTREAM="127.0.0.1:22"
	
	case "$address" in auto) address="" ;; \[*\]) ;; *:*) address="[$address]" ;; esac
	UDP_ADDR="$address:$port"
}

address_bindings() {
	local host="${1%:*}" family rows query=()
	host="${host#\[}"; host="${host%\]}"
	case "$host" in ''|0.0.0.0|::) host="" ;; esac
	for family in 4 6; do
		query=(-o -"$family" address show scope global)
		if [ -n "$host" ]; then
			if [[ "$host" == *:* ]]; then
				[ "$family" = 6 ] || continue
				[[ "$host" =~ ^[A-Fa-f0-9:.]+$ ]] || return 1
				query+=(to "$host/128")
			else
				[ "$family" = 4 ] || continue
				[[ "$host" =~ ^[0-9.]+$ ]] || return 1
				query+=(to "$host/32")
			fi
		fi
		rows="$(ip "${query[@]}")" || return 1
		printf '%s\n' "$rows" | awk '
			($3=="inet" || $3=="inet6") && $0 !~ / (tentative|dadfailed) / {
				sub(/@.*/, "", $2); split($4, addr, "/"); print addr[1] "," $2
			}'
	done
}

prepare_listener() {
	local host="${UDP_ADDR%:*}" address port="${UDP_ADDR##*:}"
	LISTENER_BINDINGS="$(address_bindings "$UDP_ADDR" | sort -u)" || fail "Could not inspect listener addresses"
	[ -n "$LISTENER_BINDINGS" ] || fail "Choose a VPS IP assigned to this host (not loopback or link-local)"
	LISTENER_BINDINGS="${LISTENER_BINDINGS//$'\n'/ }"
	[ ! -f "$ENV_FILE" ] || return 0
	port="$((10#$port))"
	case "$host" in ''|0.0.0.0|'[::]') UDP_ADDR=":$port" ;;
		*) address="${LISTENER_BINDINGS%%,*}"
			case "$address" in *:*) UDP_ADDR="[$address]:$port" ;; *) UDP_ADDR="$address:$port" ;; esac ;;
	esac
	[ "$port" != 53 ] || DIRECT_BINDINGS="$LISTENER_BINDINGS"
}

resolve_binary() {
	local arch
	if [ -z "$BINARY" ]; then
		BINARY=slowdns
		if [ ! -f "$WORK_DIR/$BINARY" ]; then
			case "$(uname -m)" in
				x86_64) arch=amd64 ;; i?86) arch=386 ;; aarch64|arm64) arch=arm64 ;; armv7l) arch=arm ;;
				*) fail "Unsupported Linux architecture" ;;
			esac
			BINARY="slowdns-$arch"
		fi
	fi
	case "$BINARY" in slowdns|slowdns-386|slowdns-amd64|slowdns-arm|slowdns-arm64) ;;
		*) fail "Use a slowdns binary that matches the VPS architecture" ;;
	esac
	[ -f "$WORK_DIR/$BINARY" ] || fail "Place the slowdns binary for your VPS architecture beside the installer"
}

check_endpoint() {
	local host="${2%:*}" port="${2##*:}"
	[[ "$2" == *:* && "$port" =~ ^[0-9]{1,5}$ ]] || fail "$1 must use address:port format"
	(( 10#$port >= 1 && 10#$port <= 65535 )) || fail "$1 port must be between 1 and 65535"
	[[ "$host" =~ ^[A-Za-z0-9.-]*$ || "$host" =~ ^\[[A-Fa-f0-9:.]+\]$ ]] || fail "Invalid $1 address"
	[ "$1" != upstream ] || [ -n "$host" ] || fail "The upstream address is empty"
}

check_config() {
	check_endpoint UDP "$UDP_ADDR"
	check_endpoint upstream "$UPSTREAM"
	local label labels name="${DOMAIN%.}"
	[ -n "$name" ] && [ "${#name}" -le 253 ] || fail "Invalid domain"
	case "$name" in .*|*.|*..*|t.example.com) fail "Enter your SlowDNS domain" ;; esac
	IFS=. read -r -a labels <<< "$name"
	for label in "${labels[@]}"; do
		[[ "$label" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$ ]] || fail "Invalid domain label"
	done
	[[ "$KEY_FILE" == "$WORK_DIR/"* && "$KEY_FILE" =~ ^/[A-Za-z0-9_./-]+$ ]] || fail "Keep the private key in the installation folder"
	case "$KEY_FILE" in */../*) fail "Invalid private key path" ;; esac
	case " $EXTRA_ARGS " in *" -udp"*|*" --udp"*|*" -privkey"*|*" --privkey"*|*" -gen-key"*|*" --gen-key"*)
		fail "Set the listener and private key in their own fields, not in SLOWDNS_EXTRA_ARGS" ;;
	esac
	if [ -e "$KEY_FILE" ]; then
		[ -s "$KEY_FILE" ] || fail "The private key is empty; the file was not changed"
	elif [ -e "$WORK_DIR/server.pub" ]; then
		fail "The public key exists without its private key; the key pair was not replaced"
	fi
}

exec_start() {
	printf 'ExecStart=%s/%s -udp ${SLOWDNS_UDP_ADDR} -privkey-file ${SLOWDNS_PRIVKEY_FILE} $SLOWDNS_EXTRA_ARGS ${SLOWDNS_DOMAIN} ${SLOWDNS_UPSTREAM_ADDR}\n' "$WORK_DIR" "$BINARY"
}

network_hooks() {
	if [ -n "$DIRECT_BINDINGS" ]; then
		printf 'ExecStartPre=+/bin/bash %s __network start bindings ${SLOWDNS_UDP_ADDR} $SLOWDNS_DIRECT_BINDINGS\n' "$SCRIPT_FILE"
		printf 'ExecStopPost=+/bin/bash %s __network stop bindings ${SLOWDNS_UDP_ADDR} $SLOWDNS_DIRECT_BINDINGS\n' "$SCRIPT_FILE"
		return
	fi
	[ -n "$DIRECT_IP" ] || return 0
	printf 'ExecStartPre=+/bin/bash %s __network start %s %s ${SLOWDNS_UDP_ADDR}\n' "$SCRIPT_FILE" "$DIRECT_IP" "$INTERFACE"
	printf 'ExecStopPost=+/bin/bash %s __network stop %s %s\n' "$SCRIPT_FILE" "$DIRECT_IP" "$INTERFACE"
}

check_runtime() {
	local file="$SYSTEMD_DIR/$SERVICE" actual
	if [ -f "$file" ]; then
		actual="$(grep '^ExecStart=' "$file" || true)"
		[ "$actual" = "$(exec_start)" ] || fail "The existing service arguments differ; the service was not changed"
		actual="$(grep -E '^Exec(StartPre|StopPost)=' "$file" || true)"
		[ "$actual" = "$(network_hooks)" ] || fail "The existing service hooks differ; review them before reinstalling"
	fi
	[ -n "$DIRECT_IP$INTERFACE$DIRECT_BINDINGS" ] || return 0
	local binding targets="$DIRECT_BINDINGS" bindings=() command checked=" "
	if [ -n "$DIRECT_IP$INTERFACE" ]; then
		[ -z "$targets" ] || fail "Do not mix old and new NOTRACK settings"
		[[ "$DIRECT_IP" =~ ^[0-9.]+$ && "$UDP_ADDR" = "$DIRECT_IP:53" ]] || fail "Invalid direct IPv4 listener"
		targets="$DIRECT_IP,$INTERFACE"
	fi
	[ "${UDP_ADDR##*:}" = 53 ] || fail "NOTRACK requires a direct listener on UDP 53"
	read -r -a bindings <<< "$targets"
	for binding in "${bindings[@]}"; do
		check_binding "$binding"
		[[ " $LISTENER_BINDINGS " == *" $binding "* ]] || fail "The NOTRACK address is not assigned to this listener"
		command=iptables; [[ "$binding" != *:* ]] || command=ip6tables
		[[ "$checked" != *" $command "* ]] || continue
		command -v "$command" >/dev/null || fail "Direct UDP 53 requires $command"
		"$command" -w 5 -t raw -S >/dev/null || fail "Could not check the $command raw table"
		checked+="$command "
	done
}

listeners() {
	local sockets
	sockets="$(ss -H -O -lunpe "sport = :${UDP_ADDR##*:}")" || return 1
	printf '%s\n' "$sockets" | awk -v host="${UDP_ADDR%:*}" '
		$1=="UNCONN" {address=$4; sub(/:[^:]*$/, "", address)
		if(host=="" || host=="0.0.0.0" || host=="[::]" || address==host ||
		   address=="*" || (address=="0.0.0.0" && host !~ /:/) ||
		   (address=="[::]" && (host ~ /:/ || $0 !~ /v6only:1/))) print}'
}

check_port() {
	local sockets pid line owners
	sockets="$(listeners)" || fail "Could not check UDP listeners"
	[ -n "$sockets" ] || return 0
	pid="$(systemctl show "$SERVICE" --property=MainPID --value)"
	[[ "$pid" =~ ^[1-9][0-9]*$ ]] || fail "UDP $UDP_ADDR is already in use by another process"
	while IFS= read -r line; do
		owners="$(printf '%s\n' "$line" | grep -oE 'pid=[0-9]+' | sort -u)" || owners=""
		[ "$owners" = "pid=$pid" ] || fail "UDP $UDP_ADDR conflicts with another service"
	done <<< "$sockets"
}

raw_rule() {
	local action="$1" chain="$2" status
	shift 2
	if "$NET_TOOL" -w 5 -t raw -C "$chain" "$@" 2>/dev/null; then
		[ "$action" = start ] || "$NET_TOOL" -w 5 -t raw -D "$chain" "$@"
	else
		status=$?
		[ "$status" -eq 1 ] || return "$status"
		[ "$action" = stop ] || "$NET_TOOL" -w 5 -t raw -I "$chain" 1 "$@"
	fi
}

network_rules() {
	local action="$1" address="$2" interface="$3" NET_TOOL=iptables marker=slowdns-direct
	[[ "$address" != *:* ]] || NET_TOOL=ip6tables
	raw_rule "$action" PREROUTING -i "$interface" -d "$address" -p udp --dport 53 \
		-m comment --comment "$marker" -j CT --notrack || return $?
	raw_rule "$action" OUTPUT -s "$address" -p udp --sport 53 \
		-m comment --comment "$marker" -j CT --notrack
}

check_binding() {
	[[ "$1" =~ ^[A-Fa-f0-9:.]+,[A-Za-z0-9_][A-Za-z0-9_.:-]*$ ]] || fail "Invalid NOTRACK address or interface"
	case "${1%%,*}" in 0.*|127.*|::|::1) fail "NOTRACK requires a non-loopback VPS IP" ;; esac
}

network_hook() {
	[ "$#" -ge 3 ] || fail "Invalid hook arguments"
	local action="$1" listener binding allowed status=0 bindings=()
	case "$action" in start|stop) ;; *) fail "Invalid hook action" ;; esac
	if [ "$2" = bindings ]; then
		[ "$#" -gt 3 ] || fail "Missing NOTRACK addresses"
		listener="$3"; shift 3; bindings=("$@")
	else
		[ "$#" -le 4 ] || fail "Invalid hook arguments"
		listener="${4:-$2:53}"; bindings=("$2,$3")
		[ "$action" != start ] || [ "$listener" = "$2:53" ] || fail "The NOTRACK listener must use the same IP on UDP 53"
	fi
	[ "${#bindings[@]}" -gt 0 ] || fail "Missing NOTRACK addresses"
	for binding in "${bindings[@]}"; do check_binding "$binding"; done
	if [ "$action" = start ]; then
		[ "${listener##*:}" = 53 ] || fail "NOTRACK requires a direct listener on UDP 53"
		allowed="$(address_bindings "$listener")" || fail "Could not inspect NOTRACK addresses"
		allowed=" ${allowed//$'\n'/ } "
		for binding in "${bindings[@]}"; do
			[[ "$allowed" == *" $binding "* ]] || fail "The NOTRACK address is not assigned to this listener"
		done
	fi
	for binding in "${bindings[@]}"; do
		if network_rules "$action" "${binding%%,*}" "${binding#*,}"; then continue; else status=$?; fi
		if [ "$action" = start ]; then
			for binding in "${bindings[@]}"; do network_rules stop "${binding%%,*}" "${binding#*,}" || true; done
			break
		fi
	done
	return "$status"
}

write_files() {
	if [ ! -f "$KEY_FILE" ]; then
		"$WORK_DIR/$BINARY" -gen-key -privkey-file "$TEMP_DIR/server.key" -pubkey-file "$TEMP_DIR/server.pub"
		install -m 0600 "$TEMP_DIR/server.key" "$KEY_FILE"
		install -m 0644 "$TEMP_DIR/server.pub" "$WORK_DIR/server.pub"
	fi
	if [ ! -f "$ENV_FILE" ]; then
		cat > "$TEMP_DIR/environment" <<EOF
SLOWDNS_BINARY="$BINARY"
SLOWDNS_UDP_ADDR="$UDP_ADDR"
SLOWDNS_PRIVKEY_FILE="$KEY_FILE"
SLOWDNS_DOMAIN="$DOMAIN"
SLOWDNS_UPSTREAM_ADDR="$UPSTREAM"
SLOWDNS_EXTRA_ARGS="$EXTRA_ARGS"
SLOWDNS_DIRECT_IPV4="$DIRECT_IP"
SLOWDNS_DIRECT_INTERFACE="$INTERFACE"
SLOWDNS_DIRECT_BINDINGS="$DIRECT_BINDINGS"
EOF
		install -m 0600 "$TEMP_DIR/environment" "$ENV_FILE"
	fi
	[ ! -f "$SYSTEMD_DIR/$SERVICE" ] || return 0
	cat > "$TEMP_DIR/$SERVICE" <<EOF
[Unit]
Description=SlowDNS server by Hokage Legend
After=network-online.target
Wants=network-online.target

[Service]
WorkingDirectory=$WORK_DIR
EnvironmentFile=$ENV_FILE
$(exec_start)
$(network_hooks)
Restart=on-failure
RestartSec=5s
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF
	install -D -m 0644 "$TEMP_DIR/$SERVICE" "$SYSTEMD_DIR/$SERVICE"
	systemctl daemon-reload
}

verify_listener() {
	local attempt pid sockets binding ready bindings=()
	read -r -a bindings <<< "$LISTENER_BINDINGS"
	for attempt in 1 2 3 4 5; do
		systemctl is-active --quiet "$SERVICE" || fail "The service is not active; check journalctl -u $SERVICE"
		pid="$(systemctl show "$SERVICE" --property=MainPID --value)"
		sockets="$(listeners)" || fail "Could not check the listener"
		if [[ "$pid" =~ ^[1-9][0-9]*$ ]]; then
			sockets="$(printf '%s\n' "$sockets" | grep -E "pid=$pid([,)])" || true)"
			ready=true
			for binding in "${bindings[@]}"; do
				family_listener "$binding" "$sockets" || ready=false
			done
			[ "$ready" = false ] || return 0
		fi
		sleep 1
	done
	fail "The service has no UDP listener verified for every selected IP family at $UDP_ADDR"
}

family_listener() {
	local family=4
	[[ "$1" != *:* ]] || family=6
	printf '%s\n' "$2" | awk -v family="$family" -v ip="${1%%,*}" '
		$1=="UNCONN" {
			address=$4; sub(/:[^:]*$/, "", address)
			dual=(address=="*" || address=="[::]") && $0 ~ /v6only:0([[:space:]]|$)/
			if(family==4 && (address==ip || address=="0.0.0.0" || dual)) ok=1
			if(family==6 && (address=="[" ip "]" || address=="[::]" || dual)) ok=1
		} END {exit !ok}'
}

install_service() {
	check_owned_files "$WORK_DIR" "$SCRIPT_FILE"
	if [ -f "$ENV_FILE" ]; then read_config; else new_config; fi
	resolve_binary
	check_config
	prepare_listener
	check_runtime
	check_port
	TEMP_DIR="$(mktemp -d "$WORK_DIR/.slowdns-install.XXXXXX")"
	trap 'rm -rf -- "$TEMP_DIR"' EXIT
	trap 'exit 1' HUP INT TERM
	chmod 0755 "$WORK_DIR/$BINARY"
	write_files
	systemctl enable "$SERVICE"
	systemctl restart "$SERVICE"
	verify_listener
	
	# Integrasi Notifikasi Telegram Otomatis (jika variabel AUTO_CHATID diatur oleh bot)
	if [[ -n "${AUTO_CHATID:-}" ]]; then
		PUBKEY="$(cat "$WORK_DIR/server.pub" 2>/dev/null || echo "N/A")"
		TOKEN="8401742770:AAFs81f2dBEfAIgr9uq2i_96ryclSG95ue8"
		URL="https://api.telegram.org/bot$TOKEN/sendMessage"
		
		TEXT="<b>✅ SLOWDNS INSTALLED SUCCESSFULLY</b>%0A"
		TEXT+="<code>─────────────────────────────</code>%0A"
		TEXT+="📡 <b>IP VPS      :</b> <code>$(curl -s ifconfig.me)</code>%0A"
		TEXT+="🌐 <b>NS Domain   :</b> <code>$DOMAIN</code>%0A"
		TEXT+="🔑 <b>Pub Key     :</b> <code>$PUBKEY</code>%0A"
		TEXT+="🔌 <b>Target Port :</b> <code>$UPSTREAM</code>%0A"
		TEXT+="📅 <b>Waktu       :</b> <code>$(date +'%Y-%m-%d %H:%M:%S')</code>%0A"
		TEXT+="<code>─────────────────────────────</code>%0A"
		TEXT+="🚀 <b>Hokage Legend SlowDNS Service V8</b>"
		
		KEYBOARD='{"inline_keyboard": [[{"text": "🔙 KEMBALI KE MENU", "callback_data": "menu"}]]}'
		
		curl -s -X POST "$URL" \
			 -d chat_id="$AUTO_CHATID" \
			 -d text="$TEXT" \
			 -d parse_mode="html" \
			 -d reply_markup="$KEYBOARD" > /dev/null 2>&1
	fi

	printf 'SlowDNS is running: %s\nConfiguration: %s\nPublic key: %s/server.pub\n' "$UDP_ADDR" "$ENV_FILE" "$WORK_DIR"
	printf '%s\n' 'Check your firewall and DNS delegation, then try connecting from HTTP Custom.'
}

uninstall_service() {
	check_unit
	[ -f "$SYSTEMD_DIR/$SERVICE" ] || fail "This folder does not have an installed SlowDNS service"
	systemctl stop "$SERVICE"
	systemctl disable "$SERVICE"
	rm -f "$SYSTEMD_DIR/$SERVICE"
	systemctl daemon-reload
	printf 'Service removed. The binary, configuration, and keys remain in %s\n' "$WORK_DIR"
}

main() {
	local action="${1:-}"
	if [ "$action" = __network ]; then shift; network_hook "$@"; return; fi
	[ "$#" -le 1 ] || fail "Use install or uninstall; see --help for examples"
	case "$action" in -h|-help|--help) help; return ;; esac
	check_host
	if [ -z "$action" ]; then
		install_service
		return
	fi
	case "$action" in 1|install) install_service ;; 2|uninstall) uninstall_service ;; *) install_service ;; esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then main "${1:-install}"; fi
