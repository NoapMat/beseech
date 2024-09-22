#!/bin/bash
connect_proxy(){
	path_config="${1}"
	[[ -e "${path_config}" ]] || { printf '%s\n' "Error: Config Not found" ; return 1 ;}
	sudo openvpn --config "${path_config}" --daemon --log openvpn.log --writepid openvpn.pid --connect-retry-max 3 --auth-user-pass pass.txt &
	while :; do
		if [[ -e "openvpn.log" ]]; then
                     sudo grep -Eiq 'SIGUSR1|TLS Error: TLS handshake failed|Fatal TLS error|Restart pause' && break
                fi
		tch_ip="$(dig +short myip.opendns.com @resolver1.opendns.com)"
                echo "After VPN: ${tch_ip}"
                [[ "${serv_ip}" != "${tch_ip}" ]] && exit 0
		echo "stat #$((i+=1))"
		[[ "$i" -gt 10 ]] && break
		sleep 6
	done
	[[ -e "openvpn.pid" ]] && { sudo kill "$(sudo cat openvpn.pid)" 2>/dev/null || true ;}
	{ rm -f openvpn.* ovpn.ovpn 2>/dev/null || true ;}
	unset path_config pid_vpn
	return 1
}

get_vpn(){
	mode="udp"
	hello="$(curl -sLk "https://www.vpngate.net/en/" -A "aaa" | sed -n -E "/Japan/ s/.*.*href='(do_openvpn\.aspx[^']*)'.*/\1/p" | sed -n -E "s|.*ip=([^\&]*)\&.*|\1#https://www.vpngate.net/en/&|p")"
	list="$(printf '%s' "${hello}" | cut -d"#" -f2 | grep -vE '219\.100' | shuf)"
        echo "getting config"
	while IFS= read -r lists; do
		dl_file="$(curl -sLk "${lists}" -A "aaa" | sed -nE 's|amp;||g;s|.*href.*"(/common/.*[0-9]_'"${mode}"'[^"]*)".*|https://www.vpngate.net\1|p')"
		[[ -n "${dl_file}" ]] && break
	done <<-EOF
	$(printf '%s' "$list")
	EOF
	[[ -z "${dl_file}" ]] && return 1
	curl -sLf "$dl_file" -A "aaa" -o ovpn.ovpn || return 1
        echo "got new config"
	unset i dl_file list hello mode lists
}

serv_ip="$(dig +short myip.opendns.com @resolver1.opendns.com)"
echo "Current Server Ip: ${serv_ip}"
while true; do
	connect_proxy "ovpn.ovpn" || { { get_vpn || echo "error from get_vpn function" ;} ; continue ;}
done
