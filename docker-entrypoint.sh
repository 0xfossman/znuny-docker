#!/usr/bin/env bash
set -euo pipefail

OTRS_HOME="/opt/otrs"
MARKER_FILE="${OTRS_HOME}/var/.db_initialized"

: "${ZNUNY_DB_HOST:=db}"
: "${ZNUNY_DB_PORT:=3306}"
: "${ZNUNY_DB_NAME:=znuny}"
: "${ZNUNY_DB_USER:=znuny}"
: "${ZNUNY_DB_PASSWORD:=znuny}"

wait_for_db() {
  echo "Waiting for database ${ZNUNY_DB_HOST}:${ZNUNY_DB_PORT} ..."
  until mariadb-admin ping \
    -h "${ZNUNY_DB_HOST}" \
    -P "${ZNUNY_DB_PORT}" \
    -u "${ZNUNY_DB_USER}" \
    -p"${ZNUNY_DB_PASSWORD}" \
    --silent; do
    sleep 2
  done
}

configure_znuny_db() {
  local config_file="${OTRS_HOME}/Kernel/Config.pm"

  if [[ ! -f "${config_file}" ]]; then
    cp "${OTRS_HOME}/Kernel/Config.pm.dist" "${config_file}"
  fi

  perl -0777 -i -pe "s/\\$Self->\{DatabaseHost\} = '.*?';/\\$Self->{DatabaseHost} = '${ZNUNY_DB_HOST}';/g" "${config_file}"
  perl -0777 -i -pe "s/\\$Self->\{Database\} = '.*?';/\\$Self->{Database} = '${ZNUNY_DB_NAME}';/g" "${config_file}"
  perl -0777 -i -pe "s/\\$Self->\{DatabaseUser\} = '.*?';/\\$Self->{DatabaseUser} = '${ZNUNY_DB_USER}';/g" "${config_file}"
  perl -0777 -i -pe "s/\\$Self->\{DatabasePw\} = '.*?';/\\$Self->{DatabasePw} = '${ZNUNY_DB_PASSWORD}';/g" "${config_file}"

  chown otrs:www-data "${config_file}"
}

bootstrap_znuny() {
  if [[ -f "${MARKER_FILE}" ]]; then
    echo "Database is already initialized."
    return
  fi

  echo "Initializing Znuny database ..."
  if ! su -s /bin/bash otrs -c "${OTRS_HOME}/bin/otrs.Console.pl Maint::Database::Install --db-host '${ZNUNY_DB_HOST}' --db-port '${ZNUNY_DB_PORT}' --db-name '${ZNUNY_DB_NAME}' --db-user '${ZNUNY_DB_USER}' --db-password '${ZNUNY_DB_PASSWORD}'"; then
    echo "Database::Install was skipped or already executed."
  fi

  su -s /bin/bash otrs -c "${OTRS_HOME}/bin/otrs.SetPermissions.pl"
  touch "${MARKER_FILE}"
  chown otrs:www-data "${MARKER_FILE}"
}

main() {
  wait_for_db
  configure_znuny_db
  bootstrap_znuny

  service cron start
  exec apache2ctl -D FOREGROUND
}

main "$@"
