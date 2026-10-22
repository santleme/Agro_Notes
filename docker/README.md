# Running farmOS with Docker

This directory contains files necessary to build the farmOS Docker image, along
with example `docker-compose.yml` files that can be used for running farmOS in
Docker containers.

## Local mixed-farm preview

To start a local farmOS instance with a basic mixed crop and livestock setup,
run this from the repository root:

    mkdir -p docker/local/www docker/local/db
    docker compose -p farmos-local -f docker/docker-compose.local.yml up -d

On first start, the installer creates a local farmOS site and enables the
modules for land, plants, animals, crop seeding and transplanting, harvests,
animal births and medical records, and activity and movement records. It opens
the dashboard without a login prompt for a single user on the same machine.
The administrator account is created with a random password that is not
printed; reset it with Drush if an administrator login is later needed.

This mode grants anonymous users local access to create and manage asset and
log records; changes are recorded as anonymous. The login and password reset
pages redirect to the dashboard. The web port is bound to `127.0.0.1`, and
this configuration is for a local single-user preview only. Do not expose it
to a network or use it for production. Production installations keep normal
authentication and should select modules through the farmOS setup wizard.

The database and uploaded files are stored in `docker/local/`, which is
ignored by Git. Stop the local instance with:

    docker compose -p farmos-local -f docker/docker-compose.local.yml down

The initial profile intentionally leaves input/material inventory, grouped or
counted animal inventory, soil and water testing, structures, equipment,
products, and API integrations optional. Enable those modules when the
operation needs them, using the farmOS modules form or Drush.

To validate the local setup, wait for the installer to exit successfully, then
check the enabled modules and open `http://localhost`:

    docker compose -p farmos-local -f docker/docker-compose.local.yml logs install
    docker compose -p farmos-local -f docker/docker-compose.local.yml exec www /opt/drupal/vendor/bin/drush pm:list --status=enabled

For more information, refer to the Docker hosting documentation in
docs/hosting/docker.md (for production) or docs/development/environment.md
(for development), also available on farmOS.org:

- Production: https://farmOS.org/hosting/docker
- Development: https://farmOS.org/development/environment
