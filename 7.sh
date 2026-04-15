#!/bin/bash
 
# ================= Root Check =================
if [[ $EUID -ne 0 ]]; then
echo "[!] Please run as root (sudo)"
exit 1
fi
 
# ================= Variables =================
TARGETS="ip.txt"
OUTDIR="nmap_output"
ALIVE=$TARGETS
PORTS="ports.txt"
 
mkdir -p "$OUTDIR"
 
pause() {
read -p "Press Enter to continue..."
}
 
# ================= Functions =================
 
alive_scan() {
echo "[+] Alive Host Discovery"
nmap -sn -T4 -iL "$TARGETS" -oA "$OUTDIR/alive_scan"
grep "Up" "$OUTDIR/alive_scan.gnmap" | awk '{print $2}' > alive_ips.txt
ALIVE="alive_ips.txt"
}
 
default_tcp() {
echo "[+] Default TCP Scan"
nmap -Pn -sS -T4 -iL "$ALIVE" -oA "$OUTDIR/default_tcp"
}
 
full_port_scan() {
echo "[+] Full Port Scan"
nmap -Pn -sS -p- -T4 -iL "$ALIVE" -oA "$OUTDIR/full_port"
 
grep '/open' "$OUTDIR/full_port.gnmap" | \
awk '{for(i=1;i<=NF;i++) if($i ~ /^[0-9]+\/open/){split($i,p,"/"); print p[1]}}' | \
sort -n -u > "$PORTS"
 
if [ -s "$PORTS" ]; then
echo "[+] Extracted Ports:"
cat "$PORTS"
else
echo "[-] No open ports found!"
fi
}
 
port_list() {
if [ -s "$PORTS" ]; then
paste -sd, "$PORTS"
else
echo ""
fi
}
 
version_scan() {
ports=$(port_list)
[ -z "$ports" ] && echo "[-] No ports available. Run Full Port Scan first." && return
nmap -Pn -sS -sV -p "$ports" -iL "$ALIVE" -oA "$OUTDIR/version_scan"
}
 
default_scripts() {
ports=$(port_list)
[ -z "$ports" ] && echo "[-] No ports available. Run Full Port Scan first." && return
nmap -Pn -sS -sC -p "$ports" -iL "$ALIVE" -oA "$OUTDIR/default_scripts"
}
 
vuln_scan() {
ports=$(port_list)
[ -z "$ports" ] && echo "[-] No ports available. Run Full Port Scan first." && return
nmap -Pn -sS --script vuln -p "$ports" -iL "$ALIVE" -oA "$OUTDIR/vuln_scan"
}
 
ssl_cert() {
ports=$(port_list)
[ -z "$ports" ] && echo "[-] No ports available. Run Full Port Scan first." && return
nmap -Pn -sS --script ssl-cert -p "$ports" -iL "$ALIVE" -oA "$OUTDIR/ssl_cert"
}
 
ssl_ciphers() {
ports=$(port_list)
[ -z "$ports" ] && echo "[-] No ports available. Run Full Port Scan first." && return
nmap -Pn -sS --script ssl-enum-ciphers -p "$ports" -iL "$ALIVE" -oA "$OUTDIR/ssl_ciphers"
}
 
ssl_dh() {
ports=$(port_list)
[ -z "$ports" ] && echo "[-] No ports available. Run Full Port Scan first." && return
nmap -Pn -sS --script ssl-dh-params -p "$ports" -iL "$ALIVE" -oA "$OUTDIR/ssl_dh"
}
 
http_methods() {
ports=$(port_list)
[ -z "$ports" ] && echo "[-] No ports available. Run Full Port Scan first." && return
nmap -Pn -sS --script http-methods -p "$ports" -iL "$ALIVE" -oA "$OUTDIR/http_methods"
}
 
http_headers() {
ports=$(port_list)
[ -z "$ports" ] && echo "[-] No ports available. Run Full Port Scan first." && return
nmap -Pn -sS --script http-security-headers -p "$ports" -iL "$ALIVE" -oA "$OUTDIR/http_headers"
}
 
http_enum() {
ports=$(port_list)
[ -z "$ports" ] && echo "[-] No ports available. Run Full Port Scan first." && return
nmap -Pn -sS --script http-enum -p "$ports" -iL "$ALIVE" -oA "$OUTDIR/http_enum"
}
 
ssh_algos() {
ports=$(port_list)
[ -z "$ports" ] && echo "[-] No ports available. Run Full Port Scan first." && return
nmap -Pn -sS --script ssh2-enum-algos -p "$ports" -iL "$ALIVE" -oA "$OUTDIR/ssh_algos"
}
 
smb_signing() {
nmap -Pn -sS -p 445 --script smb2-security-mode -iL "$ALIVE" -oA "$OUTDIR/smb_signing"
}
 
udp_scan() {
echo "[+] UDP Scan (Slow)"
nmap -Pn -sU -T4 -iL "$ALIVE" -oA "$OUTDIR/udp_scan"
}
 
# ================= MENU =================
 
while true; do
clear
 
cat << EOF
=========== AUTO NMAP MENU ===========
1) Alive Host Discovery
2) Default TCP Scan
3) Full Port Scan + Extract Ports
4) Version Detection (-sV)
5) Default Scripts (-sC)
6) Vulnerability Scan
7) SSL Certificate
8) SSL Ciphers
9) SSL Diffie-Hellman
10) HTTP Methods
11) HTTP Security Headers
12) HTTP Enum
13) SSH Algorithms
14) SMB Signing
15) UDP Scan (Slow – Last)
16) RUN ALL (Skip Alive Scan)
0) Exit
=====================================
EOF
 
read -p "Select option: " opt
 
case $opt in
1) alive_scan ;;
2) default_tcp ;;
3) full_port_scan ;;
4) version_scan ;;
5) default_scripts ;;
6) vuln_scan ;;
7) ssl_cert ;;
8) ssl_ciphers ;;
9) ssl_dh ;;
10) http_methods ;;
11) http_headers ;;
12) http_enum ;;
13) ssh_algos ;;
14) smb_signing ;;
15) udp_scan ;;
 
16)
echo "[+] Running all scans using ip.txt (Alive scan skipped)"
default_tcp
full_port_scan
version_scan
default_scripts
vuln_scan
ssl_cert
ssl_ciphers
ssl_dh
http_methods
http_headers
http_enum
ssh_algos
smb_signing
udp_scan
;;
 
0) exit ;;
*) echo "Invalid option" ;;
esac
 
pause
done
