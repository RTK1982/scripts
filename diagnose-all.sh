# diagnose-all.sh
#!/usr/bin/env bash
set -euo pipefail

# Usage-Funktion
tf_usage() {
  cat <<EOF
Usage: $0 <HOST> <URL> [EXPORT_FILE] [FTP_HOST FTP_USER FTP_PASS [FTP_PATH]]
  HOST         Zielhost/IP für Netzwerk-Checks
  URL          Ziel-URL für HTTP/TLS-Tests
  EXPORT_FILE  (optional) Pfad zur Datei, in die alle Ausgaben geschrieben werden
  FTP_HOST     (optional) FTP-Server für Report-Upload
  FTP_USER     (optional) FTP-Benutzer
  FTP_PASS     (optional) FTP-Passwort
  FTP_PATH     (optional) Remote-Pfad auf FTP-Server (Standard: reports)
EOF
  exit 1
}

# Argumente prüfen
if [[ $# -lt 2 ]]; then
  tf_usage
fi
HOST=$1
TARGET=$2
EXPORT=${3:-""}
FTP_HOST=${4:-""}
FTP_USER=${5:-""}
FTP_PASS=${6:-""}
FTP_PATH=${7:-"reports"}

# Fehler-Keywords – unverändert
KEYWORDS="failed\|error\|denied\|invalid\|disconnect\|unauthorized\|expired\|timeout\|unknown user\|authentication\|refused\|login\|unreachable\|no route\|icmp\|destination host\|network is down\|service failed\|not found\|crash\|panic\|core dumped\|restart\|trap\|oid\|agentx\|snmpd\|malformed\|warning\|critical\|alert\|emerg"

# Logger-Funktion mit Zeitstempel
tf_log() {
  local ts msg
  ts=$(date +"%Y-%m-%d %H:%M:%S")
  msg=$1
  printf "[%s] %s\n" "$ts" "$msg"
  if [[ -n "$EXPORT" ]]; then
    printf "[%s] %s\n" "$ts" "$msg" >> "$EXPORT"
  fi
}

# Dependencies-Check
for cmd in ip dig curl openssl grep tail date uptime hostname uname journalctl; do
  if ! command -v $cmd &>/dev/null; then
    printf "Fehlendes Kommando: %s\n" "$cmd" >&2
    exit 1
  fi
done

# Optional: timeout, netstat prüfen
if ! command -v timeout &>/dev/null; then
  printf "Warnung: 'timeout' nicht gefunden, Port-Checks könnten hängen\n" >&2
fi
if ! command -v netstat &>/dev/null && ! command -v ss &>/dev/null; then
  printf "Warnung: weder 'netstat' noch 'ss' gefunden, aktive Verbindungen werden nicht angezeigt\n" >&2
fi

# Abschnitte mit Leerzeile und Überschrift
tf_log "===== SYSTEMSTATUS ====="
tf_log "Hostname: $(hostname)"
tf_log "Datum/Zeit: $(date)"
tf_log "Uptime: $(uptime)"
tf_log "Distribution: $(lsb_release -d 2>/dev/null || grep PRETTY_NAME /etc/os-release | cut -d '"' -f2)"
tf_log "Kernel: $(uname -r)"

# Netzwerk
tf_log ""
tf_log "===== NETZWERK ====="
tf_log "IP-Konfiguration: $(ip a | grep inet | tr '\n' ';')"
tf_log "Standardroute: $(ip route | grep default)"
tf_log "DNS Resolver: $(grep nameserver /etc/resolv.conf | tr '\n' ';')"

# Netstat/ss
tf_log ""
tf_log "===== NETSTAT / SS STATUS ====="
if command -v netstat &>/dev/null; then
  tf_log "Aktive Verbindungen (netstat -tuln):"
  tf_log "$(netstat -tuln)"
elif command -v ss &>/dev/null; then
  tf_log "Aktive Verbindungen (ss -tuln):"
  tf_log "$(ss -tuln)"
fi

# NTP
tf_log ""
tf_log "===== NTP STATUS ====="
if command -v timedatectl &>/dev/null; then
  tf_log "$(timedatectl status | grep -iE '(ntp|synchronized)')"
else
  tf_log "timedatectl nicht verfügbar"
fi

# DNS Check
tf_log ""
tf_log "===== DNS CHECK ($HOST) ====="
tf_log "A-Record: $(dig +short $HOST)"
tf_log "Trace-Ende: $(dig +trace $HOST | tail -n 5 | tr '\n' ';')"

# Portscan
tf_log ""
tf_log "===== PORTSCAN ($HOST) ====="
PORTS=(22 23 80 443 3389 8080)
for port in "${PORTS[@]}"; do
  if timeout 1 bash -c ">/dev/tcp/$HOST/$port" &>/dev/null; then
    tf_log "Port $port: offen"
  else
    tf_log "Port $port: geschlossen"
  fi
done

# CURL Test
tf_log ""
tf_log "===== CURL TEST ($TARGET) ====="
tf_log "CURL HEAD:"
tf_log "$(curl -sfI --max-time 10 $TARGET)"
tf_log "TLS Details: $(curl -sv --connect-timeout 5 $TARGET 2>&1 | grep -E '^\*  SSL|^\*  TLS|^\*  ALPN')"

DOMAIN=$(echo $TARGET | awk -F[/:] '{print $4}')
tf_log "Zertifikat:"
tf_log "$(echo | openssl s_client -connect $DOMAIN:443 -brief 2>/dev/null | openssl x509 -noout -dates -subject)"

# Log Analyse
tf_log ""
tf_log "===== LOG ANALYSE ====="
if command -v journalctl &>/dev/null; then
  LOG_DATA=$(journalctl -n 50 2>/dev/null)
else
  LOG_DATA="$(tail -n 50 /var/log/auth.log; tail -n 50 /var/log/syslog)"
fi
RFC_5424=$(echo "$LOG_DATA" | grep -P '^<\d+>\d+ ' | wc -l)
RFC_3164=$(echo "$LOG_DATA" | grep -P '^<\d+>\w{3} ' | wc -l)
tf_log "Syslog RFC5424-Nachrichten: $RFC_5424"
tf_log "Syslog RFC3164-Nachrichten: $RFC_3164"

echo "$LOG_DATA" | grep -iE "$KEYWORDS" | while read -r line; do
  tf_log "$line"
done

# SNMPD Log
tf_log ""
tf_log "===== SNMPD LOG ====="
if [[ -f /var/log/snmpd.log ]]; then
  SNMP_LOG=$(tail -n 50 /var/log/snmpd.log)
  echo "$SNMP_LOG" | grep -iE "$KEYWORDS" | while read -r line; do tf_log "$line"; done
else
  tf_log "SNMPD-Log nicht gefunden, prüfe syslog..."
  grep -i snmpd <(echo "$LOG_DATA") | while read -r line; do tf_log "$line"; done
fi

# Webserver Logs
tf_log ""
tf_log "===== WEBSERVER-LOGS ====="
if systemctl list-units --type=service | grep -qE 'apache2|httpd'; then
  for f in error access; do
    [[ -f /var/log/apache2/$f.log ]] && tail -n 50 /var/log/apache2/$f.log | grep -iE "$KEYWORDS" | while read -r line; do tf_log "Apache $f: $line"; done
  done
fi
if systemctl list-units --type=service | grep -q nginx; then
  for f in error access; do
    [[ -f /var/log/nginx/$f.log ]] && tail -n 50 /var/log/nginx/$f.log | grep -iE "$KEYWORDS" | while read -r line; do tf_log "NGINX $f: $line"; done
  done
fi

# Docker & Compose
tf_log ""
tf_log "===== DOCKER & COMPOSE ====="
if command -v docker &>/dev/null; then
  docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | while read -r line; do tf_log "Docker: $line"; done
  for c in $(docker ps -q); do
    docker logs --tail 50 $c 2>&1 | grep -iE "$KEYWORDS" | while read -r line; do tf_log "Docker $c: $line"; done
  done
fi
if command -v podman &>/dev/null; then
  podman ps -a --format 'table {{.Names}}\t{{.Status}}' | while read -r line; do tf_log "Podman: $line"; done
fi
if [[ -f docker-compose.yml || -f docker-compose.yaml ]]; then
  COMPOSE_CMD=$(command -v docker-compose || echo "docker compose")
  $COMPOSE_CMD ps | while read -r line; do tf_log "Compose: $line"; done
  $COMPOSE_CMD logs --tail=50 2>&1 | grep -iE "$KEYWORDS" | while read -r line; do tf_log "Compose log: $line"; done
fi

# FTP Upload (optional)
tf_log ""
tf_log "===== FTP UPLOAD ====="
if [[ -n "$EXPORT" && -n "$FTP_HOST" && -n "$FTP_USER" && -n "$FTP_PASS" ]]; then
  tf_log "Uploading report to ftp://$FTP_HOST/$FTP_PATH/$EXPORT"
  curl -T "$EXPORT" --ftp-create-dirs ftp://"$FTP_USER":"$FTP_PASS"@"$FTP_HOST"/"$FTP_PATH"/"$EXPORT" && tf_log "FTP upload successful" || tf_log "FTP upload failed"
else
  tf_log "FTP upload skipped: fehlende FTP-Parameter"
fi
