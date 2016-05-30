#!/bin/bash
set -e
# Get project root directory
GIT_ROOT=$(git rev-parse --show-toplevel)
if [[ -z $GIT_ROOT  ]]; then exit -1; fi
cd $GIT_ROOT

# Load configuration from ./config
source config
. .drude/scripts/drude-functions.sh
# load environ ment vars
# http://behat-drupal-extension.readthedocs.org/en/3.1/environment.html
# https://github.com/pfrenssen/drush-bde-env


run_behat
