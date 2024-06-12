#!/bin/bash -x
set -euo pipefail

PGB_DIR="/home/pgbouncer"
INI="${PGB_DIR}/pgbouncer.ini"
USERLIST="${PGB_DIR}/userlist.txt"

ROUTING_RULES_FILE="${PGB_DIR}/routing_rules.py"
REWRITE_QUERY_FILE="${PGB_DIR}/rewrite_query.py.py"
LOG_FILE="${PGB_DIR}/pgbouncer.log"


if [ -z ${PGB_ADMIN_USERS+x} ]; then
  PGB_ADMIN_USERS="admin"
  PGB_ADMIN_PASSWORDS="pw"
fi

# Auto-generate conf if it doesn't exist
if [ ! -f ${INI} ]; then
  if [[ -z "${PGB_DATABASES:-}" ]]; then
    echo "Error: no databases specified in \$PGB_DATABASES"
    exit 1
  fi

if [ ! -f ${LOG_FILE} ]; then
    touch ${LOG_FILE}
fi

cat <<- END > $INI
[databases]
    * = $PGB_DATABASES
[pgbouncer]
    listen_port = ${PGB_LISTEN_PORT:-5432}
    listen_addr = ${PGB_LISTEN_ADDR:-0.0.0.0}
    auth_type = ${AUTH_TYPE:-md5}
    default_pool_size = ${DEFAULT_POOL_SIZE:-20}
    log_connections = ${LOG_CONNECTIONS:-1}
    log_disconnections = ${LOG_DISCONNECTIONS:-1}
    log_pooler_errors = ${LOG_POOLER_ERRORS:-1}
    routing_rules_py_module_file = $ROUTING_RULES_FILE
    rewrite_query_py_module_file = $REWRITE_QUERY_FILE
    log_stats = ${LOG_STATS:-1}
    auth_file = $USERLIST
    logfile = $LOG_FILE
    pidfile = $PGB_DIR/pgbouncer.pid
    admin_users = ${PGB_ADMIN_USERS:-admin}
END
  cat $INI
fi

# Auto-generate conf if it doesn't exist
if [ ! -f ${USERLIST} ]; then
  # convert comma-separated string variables to arrays.
  IFS=',' read -ra admin_array <<< "$PGB_ADMIN_USERS"
  IFS=',' read -ra password_array <<< "$PGB_ADMIN_PASSWORDS"

  # check every admin account has a corresponding password, and vice versa
  if (( ${#admin_array[@]} != ${#password_array[@]} )); then
      exit 1
  fi

  # Zip admin arrays together and write them to userlist.
  for (( i=0; i < ${#admin_array[*]}; ++i )); do
      echo "\"${admin_array[$i]}\" \"${password_array[$i]}\"" >> $USERLIST
  done
fi

chmod 0600 $INI
chmod 0600 $USERLIST
#/pub_metrics.sh &
#/adaptivepgbouncer.sh &
pgbouncer $INI ${VERBOSE:-}
