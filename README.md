# Setup a new drude profile (initial setup only done once)

- Fork this repo into a new namespace (myproject_drude)
- Checkout the repo to your new working directory (e.g. ~/projects/myproject)
- branch out your project

- Adjust paths and config in the file config.
- If you want to compile a theme automatically at the end of the installation set a
  POST_PROCESS variable in config, e.g.
    - POST_PROCESS='init_compass yourtheme'
    - POST_PROCESS='init_nodesass yourtheme'
- Replace this first setup part of the README for your project (initial setup only done once)
- If you want to add an initial sql dump you can copy it to dumps/initial.sql
- Push config to your project branch in your project fork. so others can use it.



# Prerequisites


## Drude is installed
- Setup drude as stated here: https://github.com/blinkreaction/drude/blob/develop/docs/drude-env-setup.md

# Use a drude profile

- Checkout this repository in your newly created Projects folder (e.g. ~/projects/my_project), change to the project folder.


run the following commands and confirm setup steps:

```
    cd ~/Projects
    git clone git@server:my_project_drude.git my_project
    cd my_project
    dsh up
    dsh init
```   

# explanation of init

take a look at config
according to the settings there the script will do a couple of things:

1. clone platform to docroot
2. clone profile to drude folder
3. copy profile to docroot/profiles
4. optionally runs drush make for the profile
5. clone a site repo to docroot/sites or create directory for local site
6. db_import or drush site install
7. add_hosts_entry
8. configure_drush with aliases and optional extensions
9. optionally initialize behat

# Useful references:

## drude documentation
- https://github.com/blinkreaction/drude#instructions-and-tutorials

## Drush general

- http://drushcommands.com/drush-8x

## Pantheon
- https://github.com/pantheon-systems/terminus/wiki/Usage
- https://pantheon.io/docs/drush/
- TODO investigate https://hub.docker.com/r/kalabox/terminus/
## Phpstorm

- https://github.com/blinkreaction/drude/blob/develop/docs/xdebug.md

## Notable Alternatives

- https://github.com/kalabox/kalabox (never got past the https://github.com/kalabox/kalabox#1-get-a-keycode-during-alpha)
- https://www.drupal.org/project/vdd (used this before)
- https://github.com/geerlingguy/drupal-vm
- https://github.com/mglaman/platform-docker (like platform.sh better than pantheon?)
- https://github.com/meosch/localdevsetup --> create environments like this drude