#!/bin/sh
set -eu

drupal_path=/opt/drupal
drush="$drupal_path/vendor/bin/drush"
settings_file="$drupal_path/web/sites/default/settings.php"
ready_file=${FARMOS_FS_READY_SENTINEL_FILENAME:-$drupal_path/.farmos-ready}

echo 'Waiting for the farmOS codebase...'
attempt=0
until [ -f "$ready_file" ]; do
  if [ "$attempt" -ge 90 ]; then
    echo 'Timed out waiting for the farmOS codebase to finish initializing.' >&2
    exit 1
  fi
  attempt=$((attempt + 1))
  sleep 2
done

if [ ! -x "$drush" ]; then
  echo 'The farmOS codebase is incomplete; Drush was not found.' >&2
  exit 1
fi

if [ ! -f "$settings_file" ]; then
  echo 'Checking whether the database is empty...'
  psql_url=$(printf '%s\n' "$FARMOS_DB_URL" | sed 's|^pgsql://|postgresql://|')
  if [ "$psql_url" = "$FARMOS_DB_URL" ]; then
    echo 'The database URL must use the pgsql:// scheme expected by Drush.' >&2
    exit 1
  fi
  if ! tables=$(psql "$psql_url" -tAc "SELECT to_regclass('public.key_value')"); then
    echo 'Could not check the database before installation; refusing to continue.' >&2
    exit 1
  fi
  if [ -n "$tables" ]; then
    echo 'The database already contains Drupal tables, but settings.php is missing. Refusing to overwrite it.' >&2
    exit 1
  fi

  admin_password=$(php -r 'echo bin2hex(random_bytes(16));')

  cd "$drupal_path"
  "$drush" site:install farm \
    --db-url="$FARMOS_DB_URL" \
    --account-name="$FARMOS_ADMIN_NAME" \
    --account-pass="$admin_password" \
    --site-name="$FARMOS_SITE_NAME" \
    -y
else
  echo 'farmOS is already installed; ensuring local modules and permissions.'
  cd "$drupal_path"
fi

"$drush" pm:install \
  farm_activity \
  farm_animal \
  farm_birth \
  farm_harvest \
  farm_land \
  farm_land_types \
  farm_medical \
  farm_plant \
  farm_quantity_standard \
  farm_quick_birth \
  farm_quick_movement \
  farm_quick_planting \
  farm_seeding \
  farm_transplanting \
  -y

# This anonymous access is restricted to the loopback-only local preview.
# It is not part of the farmOS profile or a production installation.
"$drush" role:perm:add anonymous \
  'access content,access farm dashboard,access asset overview,access asset collection,administer assets,view any asset,access log overview,access log collection,administer log,view any log,access quantity collection,administer quantity,access locations overview' \
  -y
"$drush" cr

printf '\n%s\n\n' 'farmOS local mixed-farm mode is ready. Open the dashboard at http://localhost.'
