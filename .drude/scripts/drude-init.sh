#!/bin/bash
set -e

# Load configuration from ./config
source drude_settings

# Console colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
NC='\033[0m'

echo-red () { echo -e "${red}$1${NC}"; }
echo-green () { echo -e "${green}$1${NC}"; }
echo-yellow () { echo -e "${yellow}$1${NC}"; }

# Get project root directory
GIT_ROOT=$(git rev-parse --show-toplevel)
if [[ -z $GIT_ROOT  ]]; then exit -1; fi

# Set repo root as working directory.
cd $GIT_ROOT

. .drude/scripts/drude-functions.sh

# Check whether shell is interactive (otherwise we are running in a non-interactive script environment)
is_tty ()
{
	[[ "$(/usr/bin/tty || true)" != "not a tty" ]]
}

# Project initialization steps
checkout_site

init_settings
set_default_file_permissions
echo -e "${yellow}We need to reset (or create) the docker containers for this site.${NC}"
dsh reset

echo -e "${yellow}Waiting 15 seconds for mysql...${NC}"
sleep 15
#can we move it here so drush make can execute?
checkout_profile

db_import
# i think this is obsolete in d8?
#set_default_file_config

add_hosts_entry

echo -e "${green}Open http://${SITE_DOMAIN} in your browser to verify the setup, generating one-time-login..${NC}"
generate_uli


init_behat
configure_drush

echo -e "${green}All done!${NC}"


# Execute post_process functions see config file.
if [ -n "$POST_PROCESS" ]; then
    $POST_PROCESS
fi