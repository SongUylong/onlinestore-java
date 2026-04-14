# Start MySQL (order-service) and MongoDB (product-service) for local development.
# Data lives under LOCAL_DATABASE_ROOT (default: ./.local/databases).
set -euo pipefail

# Default outside the repo so `nix develop` / flakes are not tripped by socket files under the project tree.
ROOT="${LOCAL_DATABASE_ROOT:-${TMPDIR:-/tmp}/onlinestore-databases}"
MYSQL_DATA="$ROOT/mysql"
MONGO_DATA="$ROOT/mongo"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MONGO_PORT="${MONGO_PORT:-27017}"
SOCKET="$MYSQL_DATA/mysql.sock"

mkdir -p "$MYSQL_DATA" "$MONGO_DATA"

port_busy() {
  local p="$1"
  if command -v ss >/dev/null 2>&1; then
    ss -tln | grep -q ":$p " && return 0
  fi
  return 1
}

if port_busy "$MYSQL_PORT"; then
  echo "Port $MYSQL_PORT is already in use (MySQL?). Skip starting mysqld or free the port." >&2
  exit 1
fi
if port_busy "$MONGO_PORT"; then
  echo "Port $MONGO_PORT is already in use (MongoDB?). Skip starting mongod or free the port." >&2
  exit 1
fi

if [[ ! -d "$MYSQL_DATA/mysql" ]]; then
  echo "Initializing MySQL data directory at $MYSQL_DATA"
  mysqld --no-defaults --datadir="$MYSQL_DATA" --initialize-insecure
fi

echo "Starting MySQL on 127.0.0.1:$MYSQL_PORT (datadir=$MYSQL_DATA)"
mysqld --no-defaults \
  --datadir="$MYSQL_DATA" \
  --socket="$SOCKET" \
  --port="$MYSQL_PORT" \
  --bind-address=127.0.0.1 \
  --mysqlx=OFF &
MYSQL_PID=$!

for _ in $(seq 1 60); do
  if mysql --protocol=socket --socket="$SOCKET" -uroot -e "SELECT 1" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! mysql --protocol=socket --socket="$SOCKET" -uroot -e "SELECT 1" >/dev/null 2>&1; then
  echo "MySQL did not become ready in time." >&2
  kill "$MYSQL_PID" 2>/dev/null || true
  exit 1
fi

echo "Configuring MySQL user and database (order-service / password from application.properties)"
mysql --protocol=socket --socket="$SOCKET" -uroot <<'EOSQL'
CREATE DATABASE IF NOT EXISTS `order-service`;
ALTER USER 'root'@'localhost' IDENTIFIED BY 'mysql';
CREATE USER IF NOT EXISTS 'root'@'127.0.0.1' IDENTIFIED BY 'mysql';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOSQL

echo "Starting MongoDB on 127.0.0.1:$MONGO_PORT (dbpath=$MONGO_DATA)"
mongod --dbpath "$MONGO_DATA" --bind_ip 127.0.0.1 --port "$MONGO_PORT" &
MONGO_PID=$!

for _ in $(seq 1 60); do
  if mongosh --quiet --port "$MONGO_PORT" --eval "db.runCommand({ ping: 1 })" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! mongosh --quiet --port "$MONGO_PORT" --eval "db.runCommand({ ping: 1 })" >/dev/null 2>&1; then
  echo "MongoDB did not become ready in time." >&2
  kill "$MONGO_PID" "$MYSQL_PID" 2>/dev/null || true
  exit 1
fi

echo "MySQL PID=$MYSQL_PID  MongoDB PID=$MONGO_PID"
echo "Press Ctrl+C to stop both servers."

cleanup() {
  echo "Stopping databases..."
  kill "$MONGO_PID" "$MYSQL_PID" 2>/dev/null || true
  wait "$MONGO_PID" "$MYSQL_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

wait "$MYSQL_PID" "$MONGO_PID"
