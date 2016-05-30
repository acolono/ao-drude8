#!/bin/bash
set -e
# Get project root directory
GIT_ROOT=$(git rev-parse --show-toplevel)
if [[ -z $GIT_ROOT  ]]; then exit -1; fi
cd $GIT_ROOT

# Load configuration from ./config
source config
. .drude/scripts/drude-functions.sh

#cd $GIT_ROOT
#ssh $STAGE_LOGIN drush @$STAGE_ALIAS sql-dump > dumps/stage.sql
#cd docroot
#dsh mysql-import ../dumps/stage.sql
#echo -e "Rebuilding registry ...";
#dsh drush rr
#set_default_file_config
#cd $GIT_ROOT


# Update DB from pantheon live site: https://pantheon.io/docs/drush/
# drush sql sync works on Pantheon as of Drush version 8.0.4
# http://drushcommands.com/drush-8x/sql/sql-sync/
echo -e "${yellow}drush sql-sync should work as expected, use it directly instead of this script...${NC}"
drush sql-sync
dsh drush -l ${SITE_DOMAIN} sql-sync @$STAGE_ALIAS @self