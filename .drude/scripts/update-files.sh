#!/bin/bash
set -e

# Load configuration from ./config
source config
. .drude/scripts/drude-functions.sh

# Get project root directory
GIT_ROOT=$(git rev-parse --show-toplevel)
if [[ -z $GIT_ROOT  ]]; then exit -1; fi
#
#cd $GIT_ROOT
#REMOTE_FILES=$(ssh $STAGE_LOGIN drush @$STAGE_ALIAS dd files)
#rsync -rpv $STAGE_LOGIN:$REMOTE_FILES/ docroot/sites/$SITE_DIRECTORY/files --exclude css/* --exclude js/* --exclude styles/*
#set_default_file_config


# Sync files from local to Pantheon site environment.
#drush -r . rsync @self:sites/default/files/ @pantheon.SITENAME.ENV:%files
# Sync files from Pantheon site environment to local.
#drush -r . rsync @pantheon.SITENAME.ENV:%files @self:sites/default/
