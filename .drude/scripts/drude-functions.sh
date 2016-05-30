#!/bin/bash

# Credit: https://github.com/kevva/dotfiles
# USAGE FOR SEEKING CONFIRMATION
# seek_confirmation "Ask a question"
#
# if is_confirmed; then
#   some action
# else
#   some other action
# fi

seek_confirmation() {
  printf "\n${bold}$@${reset}"
  read -p " (y/n) " -n 1
  printf "\n"
}

# underlined
seek_confirmation_head() {
  printf "\n${underline}${bold}$@${reset}"
  read -p "${underline}${bold} (y/n)${reset} " -n 1
  printf "\n"
}

# Test whether the result of an 'ask' is a confirmation
is_confirmed() {
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
  return 0
fi
return 1
}

# Yes/no confirmation dialog with an optional message
# @param $1 confirmation message
_confirm ()
{
  # Skip checks if not a tty
  if ! is_tty ; then return 0; fi

  while true; do
    read -p "$1 [y/n]: " answer
    case $answer in
      [Yy]|[Yy][Ee][Ss] )
        break
        ;;
      [Nn]|[Nn][Oo] )
        exit 1
        ;;
      * )
        echo 'Please answer yes or no.'
    esac
  done
}

# Copy a settings file from $source to $dest
# Skips if the $dest already exists.
_copy_settings_file()
{
  local source=${1}
  local dest=${2}

  if [[ ! -f $dest ]]; then
    echo -e "${green}Copying ${dest}...${NC}"
    cp $source $dest
  else
    echo -e "${yellow}${dest} already in place${NC}"
  fi
}

# Checkout sites and platform
checkout_site()
{

  cd $GIT_ROOT
  DOWNLOADED=0
  SKIP_DOWNLOAD=FALSE


  if [ -d "docroot" ]; then


    echo -e "${red}Folder docroot already exists! Make sure you have no uncommitted work in Docroot before continuing"
    seek_confirmation "Keep Existing Docroot but continue with setup? (CAREFUL: choosing no will delete docroot!)"
    if is_confirmed; then
      echo -e "${yellow}keeping existing docroot...${NC}"
      SKIP_DOWNLOAD=TRUE
    else
      # Docroot exists and shouldnt be kept
      _confirm "Delete docroot and checkout again? (sudo required)"
      sudo rm -rf docroot
      SKIP_DOWNLOAD=FALSE
    fi

  fi


  if [[ -n "$PLATFORM_REPO" && ! "$SKIP_DOWNLOAD" == TRUE ]]; then
    echo -e "${yellow}Checking out platform to docroot...${NC}"
    git clone $PLATFORM_REPO -b $PLATFORM_BRANCH docroot
    # Checkout specific tag.
    if [ -n "$PLATFORM_TAG" ]; then
      cd docroot
      git checkout tags/$PLATFORM_TAG -b $PLATFORM_TAG
      cd ..
    fi
  elif [[ -n "$PLATFORM_DOWNLOAD"&& ! "$SKIP_DOWNLOAD" = TRUE ]]; then
    # Not working right now.
    echo -e "${yellow}Downloading platform $PLATFORM_DOWNLOAD to docroot...${NC}"
    curl $PLATFORM_DOWNLOAD > docroot.tar.gz
    tar xvz docroot.tar.gz --directory $GIT_ROOT/docroot
  fi
  # now we have a docroot in any case


  cd docroot/sites

  # if we configured a site repo then get it into sites folder
  if [ -n "$SITE_REPO" ]; then

    echo -e "${yellow}backing up site folder to docroot/sites/${SITE_DIRECTORY}.bak ${NC}"
    # move old default site directory

    if [ -d "default" ]; then
      mv default default.old
    fi
    # move existing site directory and clone it fresh
    if [ -d "${SITE_DIRECTORY}" ]; then
      mv $SITE_DIRECTORY $SITE_DIRECTORY.old
    fi
    echo -e "${yellow}Checking out site to docroot/sites/${SITE_DIRECTORY}...${NC}"
    git clone $SITE_REPO -b $SITE_BRANCH $SITE_DIRECTORY
  else
    echo -e "${yellow}backing up site folder to docroot/sites/${SITE_DIRECTORY}.bak${NC}"
    if [ -d "${SITE_DIRECTORY}" ]; then
      mv $SITE_DIRECTORY $SITE_DIRECTORY.old
    fi
    echo -e "${yellow}creating site dir in docroot/sites/${SITE_DIRECTORY}...${NC}"

    mkdir $SITE_DIRECTORY
  fi
  cd $GIT_ROOT
}

checkout_profile()
{
  cd $GIT_ROOT

  if [ -n "$PROFILE_REPO" ]; then
    if [ -d "profile" ]; then
      echo -e "${red}Folder profile already exists!"

      seek_confirmation "Delete profile and checkout again?"
      if is_confirmed; then
        rm -rf profile
    fi


    if [ -d "docroot/profiles/${INSTALL_PROFILE}" ]; then
      echo -e "${red}Folder docroot/profiles/${INSTALL_PROFILE} already exists!"
      seek_confirmation "Delete profile and checkout again?"
      if is_confirmed; then
        rm -rf docroot/profiles/$INSTALL_PROFILE
        else
      SKIP_DOWNLOAD=TRUE
    fi
      fi
    fi

    if [[ ! "$SKIP_DOWNLOAD" = TRUE  ]]; then

      echo -e "${yellow}Checking out $PROFILE_REPO to profile ...${NC}"
      git clone $PROFILE_REPO -b $PROFILE_BRANCH docroot/profiles/$INSTALL_PROFILE
    fi
    seek_confirmation "Run Drush make for profile? (you probably want this)"

    # if we are using a profile, run its makefile
    if is_confirmed; then
      echo -e "${yellow}will looking for drupal-org.make in profile...${NC}"
      dsh exec drush8 make docroot/profiles/$INSTALL_PROFILE/drupal-org.make docroot --no-core
    fi




fi
}

# Copy settings files
init_settings()
{
  cd $GIT_ROOT
  _copy_settings_file 'docker-compose.yml.dist' 'docker-compose.yml'
  # Replace the VIRTUAL_HOST setting if needed. Sed works different on mac/bsd and linux systems
  # so we need to create a .bak file and delete it right afterwards: http://stackoverflow.com/questions/5694228
  sed -i.bak "s/%SITE_DOMAIN%/${SITE_DOMAIN}/g" docker-compose.yml
  rm docker-compose.yml.bak
  # todo if settings exists get rid of it

  [[ -f "docroot/sites/default/settings.php" ]] && mv docroot/sites/default/settings.php docroot/sites/default/old.settings.php && echo -e "${red}found settings.php which shouldnt exist. remove this from your repo and its history..."

  [[ -f "docroot/sites/${SITE_DIRECTORY}/settings.php" ]] && mv docroot/sites/${SITE_DIRECTORY}/settings.php docroot/sites/${SITE_DIRECTORY}/old.settings.php && echo -e "${red}found settings.php which shouldnt exist. remove this from your repo and its history ${1}...${NC}"

  _copy_settings_file ".drude/config/settings.php" "docroot/sites/${SITE_DIRECTORY}/settings.php"
  _copy_settings_file ".drude/config/settings.local.php" "docroot/sites/${SITE_DIRECTORY}/settings.local.php"

  # Generating local hash salt

  local HASH_SALT="$(base64 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 75 | head -n 1)"

  local HASH_SALT_STRING="\$settings['hash_salt']='${HASH_SALT}';"

  echo $HASH_SALT_STRING > 'salt.txt'
  echo "Hash_salt is $HASH_SALT writtent to salt.txt"



  _copy_settings_file ".drude/config/default.settings.php" "docroot/sites/${SITE_DIRECTORY}/default.settings.php"
  _copy_settings_file ".drude/config/default.services.yml" "docroot/sites/${SITE_DIRECTORY}/default.services.yml"
}

# Install the site
# @param $1 site-name (domain)
site_install()
{
  cd $GIT_ROOT/docroot

  echo -e "${yellow}Installing site ${1}...${NC}"

  local site_name=''
  if [[ $1 != '' ]]; then
    # Append site name to the arguments list if provided
    site_name="-l $1 --site-name=$1"
  fi

    echo-green "Installing site..."
    dsh exec drush8 si ${INSTALL_PROFILE} -y



}

# Create a new DB
# @param $1 DB name
db_create()
{
  echo -e "${yellow}Creating DB ${1}...${NC}"
  cd $GIT_ROOT/docroot
  local database=${1}
#  local mysql_exec='mysql -h $DB_1_PORT_3306_TCP_ADDR --user=root --password=$DB_1_ENV_MYSQL_ROOT_PASSWORD -e ';
#  local query="DROP DATABASE IF EXISTS ${database}; CREATE DATABASE ${database}; GRANT ALL ON ${database}.* TO "'$DB_1_ENV_MYSQL_USER'"@'%'"


  dsh exec drush sql-create --db-su=root --db-su-pw=$DB_1_ENV_MYSQL_ROOT_PASSWORD

#  dsh exec "${mysql_exec} \"${query}\""
}

# install devtools if makefile is present
devtools_makefile()
{
  cd $GIT_ROOT/docroot


  if [ -s "dumps/devtools.make" ]
  then
    read -p "Found file dumps/devtools.make. Do you want to run this makefile? [y/n]:" -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      echo -e "${green}running devtools make ${NC}";
      cd $GIT_ROOT/docroot
      dsh exec drush make ../devtools.make .
      cd $GIT_ROOT
    fi
  fi
}

# Import database from the source site alias
db_import()
{
  local IMPORTED=0
  cd $GIT_ROOT


  if [ -s "dumps/initial.sql" ]
  then
    read -p "Found file dumps/initial.sql. Do you want to import this dump? [y/n]:" -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      echo -e "${green}Starting import of initial.sql${NC}";
      cd $GIT_ROOT/docroot
      dsh drush -l ${SITE_DOMAIN} sqlc < ../dumps/initial.sql
      echo -e "${green}Rebuilding registry ...${NC}";
      dsh drush rr
      IMPORTED=true
      cd $GIT_ROOT
    fi
  fi

  if [ $IMPORTED = true ]; then
    if [[ -n "$STAGE_ALIAS" ]]; then
        read -p "Do you want to import DB from $STAGE_ALIAS? If not a Drupal install (profile: $INSTALL_PROFILE) will be started. [y/n]:" -n 1 -r
    fi
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      echo -e ""
      echo -e "${green}Starting import of stage database ...${NC}";
      cd $GIT_ROOT
      # TODO: check if this works with pantheon and inform how to use sql-sync command for subsequent db imports
      ssh $STAGE_LOGIN drush @$STAGE_ALIAS sql-dump > dumps/initial.sql
      cd docroot
      dsh mysql-import ../dumps/initial.sql
      echo -e "${green}Rebuilding registry ...${NC}";
      dsh drush8 rr
      IMPORTED=true
      # todo: inform about files not yet being synced for filesize reasons and how to do it with drush rsync command
      cd $GIT_ROOT
    fi
  fi

  if [ $IMPORTED -eq 0 ]; then

    echo -e ""
    echo -e "waiting for installer to start ...";
  # There already is a function for this
    cd $GIT_ROOT/docroot/sites/$SITE_DIRECTORY
    db_create drupal
    # echo -e "created db, running install ...";
    time site_install ${SITE_DOMAIN}
    #dsh drush -l ${SITE_DOMAIN} si $INSTALL_PROFILE -y

    # Run composer installs https://www.drupal.org/node/2405811 if composer manager exists
    if [ -x modules/contrib/composer_manager/scripts/init.php ]; then

      echo -e "${green}running composer manager setup ...";
      php modules/contrib/composer_manager/scripts/init.php
      composer drupal-rebuild
      composer update -n --lock --verbose
      cd $GIT_ROOT
    fi
  fi
}

# Add the hosts entry, if desired
add_hosts_entry()
{
  HOSTENTRY="192.168.10.10 ${SITE_DOMAIN}"
  if grep -Fxq "$HOSTENTRY" /etc/hosts
  then
    echo -e "${yellow}${SITE_DOMAIN} already exists in /etc/hosts, skipping.${NC}"
  else
      echo -e "${green}Add ${SITE_DOMAIN} to your hosts file (/etc/hosts), e.g.:${NC}"
      echo -e "192.168.10.10 ${SITE_DOMAIN}"
      read -p "Should the entry be created for you (local sudo password required)?. [y/n]:" -n 1 -r
      echo -e "${yellow}for tests to work as expected you will also need to have setup dns according to drude setup instructions${NC}"
      echo -e ""
      if [[ $REPLY =~ ^[Yy]$ ]]
      then
        echo "192.168.10.10 ${SITE_DOMAIN}" | sudo tee -a /etc/hosts
      fi
  fi
}

generate_uli()
{
  cd $GIT_ROOT/docroot
  dsh drush uli --uri="${SITE_DOMAIN}"
  cd $GIT_ROOT
}

# Misc drush commands to bring DB up-to-date
db_updates()
{
  cd $GIT_ROOT
  echo -e "${green}Applying DB updates...${NC}"
  cd docroot
  set -x

  dsh drush -l ${SITE_DOMAIN} status
  dsh drush -l ${SITE_DOMAIN} updb -y
  dsh drush -l ${SITE_DOMAIN} fr-all -y
  dsh drush -l ${SITE_DOMAIN} cc all
  dsh drush -l ${SITE_DOMAIN} cron -v

  set +x
}

# Local adjustments
local_settings()
{
  cd $GIT_ROOT
  echo -e "${green}Applying local settings...${NC}"
  cd docroot
  set -x

  dsh drush -l ${SITE_DOMAIN} en stage_file_proxy -y

  set +xc
}

# Compile nodesass
init_nodesass()
{
  _confirm "One more thing: Should I try to compile $1 with nodesass? This involves running npm install and bower install."
  cd $GIT_ROOT
  echo -e "${green}Installing nodesass and do initial compile...${NC}"
  set -x

  cd "docroot/sites/${SITE_DIRECTORY}/themes/$1"
  #npm cache clean

  echo "Executing npm install"
  npm install

  echo "Installing gulp";
  npm install gulp

  echo "Installing bower";
  npm install bower

  echo "Executing bower install"
  bower install

  echo "executing gulp sass-prod"
  gulp sass-prod

  set +x
}

# Install drush extensions
configure_drush() {

  # pantheon terminus
  # https://github.com/pantheon-systems/terminus#installing-with-composer
  seek_confirmation "Install terminus from https://github.com/pantheon-systems/terminus (choose yes if you are planning to integrate this drude with a site on pantheon.io)?"

  if is_confirmed; then
    composer require pantheon-systems/terminus

    # TODO; completions https://github.com/pantheon-systems/terminus/issues/1012

    terminus auth login && terminus sites aliases
  else
    echo -e "${yellow}not installing terminus...${NC}"
  fi

  echo -e "${green}generating local drush alias so you can sql sync...${NC}"
  cd $GIT_ROOT/docroot
  echo "<?php" > $GIT_ROOT/drush/drude.aliases.drushrc.php
  dsh exec drush -l ${SITE_DOMAIN} site-alias --with-db --show-passwords >> $GIT_ROOT/drush/drude.aliases.drushrc.php
  # verify alias creation worked
#  dsh exec drush8 -l ${SITE_DOMAIN} sa
#  dsh exec drush8 cr
}

# Compile legacy compass
init_compass()
{
  _confirm "One more thing: Should I try to compile $1 with compass?"
  cd $GIT_ROOT
  cd "docroot/sites/${SITE_DIRECTORY}/themes/$1"

  echo -e "${green}Installing bundle and do initial compile...${NC}"

  bundle install

  bundle exec compass compile --boring --output-style compressed --force -e production

  # Compile the panels folder as well, if we deal with an ao_theme variant
  echo "Checking if sass/panels exist in $i"
  if [ -d "sass/panels" ]; then
    echo "Found sass/panels, compiling panel styles now..."
    bundle exec compass compile --boring --output-style compressed --sass-dir sass/panels --force -e production
  fi
  echo "Checking if sass/fallback exist in $i"
  if [ -d "sass/fallback" ]; then
    echo "Found sass/fallback, compiling fallback styles now..."
    bundle exec compass compile --boring --output-style compressed --sass-dir sass/fallback --force -e production
  fi
}

# Initialize local Behat settings
init_behat()
{
  seek_confirmation "Install Behat testing framework and verify setup (reccomended)?"

  if is_confirmed; then

    # Installing drush extension for environment vars
    # http://behat-drupal-extension.readthedocs.org/en/3.1/environment.html
    # https://github.com/pfrenssen/drush-bde-env
    if [ ! -d drush/drush-bde-env ];
    then
      echo -e "${green}Installing drush extension for environment vars...${NC}"
      dsh exec git clone https://github.com/pfrenssen/drush-bde-env.git drush/drush-bde-env

    fi



    cd $GIT_ROOT
    echo -e "${green}write environment vars to file...${NC}"
    # write environment vars to file so we can source them later (instead of eval)
    # https://github.com/pfrenssen/drush-bde-env#save-export-command-to-a-file
    dsh exec drush -l ${SITE_DOMAIN} cr && dsh drush -l ${SITE_DOMAIN} bde-env-gen --site-root=/var/www/docroot --base-url=http://${SITE_DOMAIN} --subcontexts="profiles/${INSTALL_PROFILE}/modules" mybehatvars.sh
    echo -e "${green}environment vars written to mybehatvars.sh ...${NC}"
    cd $GIT_ROOT
    echo -e "${green}create behat.yml file...${NC}"

    _copy_settings_file 'tests/behat/behat.yml.dist' 'tests/behat/behat.yml'
    # replace vars in behat.yml

    sed -i.bak "s/%SITE_DOMAIN%/${SITE_DOMAIN}/g" tests/behat/behat.yml
    sed -i.bak "s/%SITE_DIRECTORY%/${SITE_DIRECTORY}/g" tests/behat/behat.yml
    sed -i.bak "s/%INSTALL_PROFILE%/${INSTALL_PROFILE}/g" tests/behat/behat.yml
    rm tests/behat/behat.yml.bak

    # lets run the tests once from here after setup
    echo -e "${green}run the tests unce to prove our environment setup was successful...${NC}"
    run_behat
  fi
}

# Run basic Behat validation tests
run_behat()
{
  cd $GIT_ROOT

  echo -e "${yellow}Launching Behat validation tests...${NC}"
  cd tests/behat
  #  dsh behat --format=pretty --out=std --format=junit --out=junit features/drush-si-validation.feature
  dsh behat --format=pretty --out=std
}

# Create public and private file folders if not existing, set proper permissions
set_default_file_permissions()
{
  cd $GIT_ROOT/docroot
  FOLDERS=( "files" "private" "private/temp" "private/files" "config" )
  BASE_FOLDER="sites/$SITE_DIRECTORY"
  chmod 775 $BASE_FOLDER

  for FOLDER in "${FOLDERS[@]}"
  do
    if [ ! -d $BASE_FOLDER/$FOLDER ]; then
      echo "Creating folder $BASE_FOLDER/$FOLDER"
      mkdir $BASE_FOLDER/$FOLDER
    fi
    chmod 777 $BASE_FOLDER/$FOLDER
  done
  echo "Setting permissions for files and private to 775."
  find $BASE_FOLDER/files -type d -exec chmod 777 {} +
  find $BASE_FOLDER/private -type d -exec chmod 777 {} +
  cd $GIT_ROOT
}

# Update the file folder settings in db.
set_default_file_config()
{
  cd $GIT_ROOT/docroot

  echo "Setting paths for files/private/tmp path in db."
  BASE_FOLDER="sites/$SITE_DIRECTORY"
  dsh drush vset file_public_path $BASE_FOLDER/files
  dsh drush vset file_private_path $BASE_FOLDER/private/files
  dsh drush vset file_temporary_path $BASE_FOLDER/private/temp
}
