#!/usr/bin/env bash

### Current Directory
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CONTAINER_DIR='/var/www/site'

### User will run: `./delete.sh <site-name>`

### Goals:
# 1. Check if <site-name> was passed. If not, ask for one
# 2. Delete submodule <site-name> if exists
# 3. Delete theme folder themes/<site-name> if exists
# 4. Delete wp-engine-downloads/<site-name> if exists
# 5. Delete DockerLocal/data/dumps/<site-name>.import.sql if exists
# 6. Delete the db inside the container for <site-name> if exists
#  - `./site-ssh -h=mysql -c="echo 'drop database if exists <site-name>' | mysql -u root -p1234"`

### Capture user input
SITE_NAME=$1

### SITE NAME - Check if <site-name> was passed. If not, ask for one
if [ -z "$SITE_NAME" ]; then
  echo "👉 === No site name passed. Please enter a site name:"
  read SITE_NAME
  ## if empty, error & run again
  if [ -z "$SITE_NAME" ]; then
    echo "👉 === No site name entered. Please run this script again."
    exit 1
  fi
fi

### SUBMODULE - Delete submodule <site-name> if exists
if [ -d "themes/$SITE_NAME" ]; then
  echo "👉 === Deleting theme submodule $SITE_NAME"

  git reset .gitmodules
  git submodule deinit -f -- themes/$SITE_NAME
  rm -rf .git/modules/themes/$SITE_NAME
  git rm -f themes/$SITE_NAME

  # put a .gitkeep into themes
  touch themes/.gitkeep
  echo "✅ === Theme submodule $SITE_NAME deleted"
else
  echo "☑️  === No theme submodule $SITE_NAME found"
fi

### WP-ENGINE-DOWNLOADS - Delete wp-engine-downloads/<site-name> if exists
if [ -d "wp-engine-downloads/$SITE_NAME" ]; then
  echo "👉 === Deleting wp-engine-downloads folder $SITE_NAME"
  rm -rf wp-engine-downloads/$SITE_NAME
  echo "✅ === wp-engine-downloads folder $SITE_NAME deleted"
else
  echo "☑️  === No wp-engine-downloads folder $SITE_NAME found"
fi

### Update html/wp-content/ - loop through every folder
echo "👉 === Clearing out html/wp-content/<folders>"
for folder in html/wp-content/*; do
    # if the file is a directory
    if [ -d "$folder" ]; then
      # delete the folder, make a new folder - cp wp-content/index.php into it
      rm -rf $folder
      mkdir -p $folder
      cp html/wp-content/index.php $folder/index.php
      echo "✅ === Folder $folder cleared & replaced"
    fi
done


### DUMPS - Delete DockerLocal/data/dumps/<site-name>.import.sql if exists
if [ -f "DockerLocal/data/dumps/$SITE_NAME.import.sql" ]; then
  echo "👉 === Deleting dump file $SITE_NAME.import.sql"
  rm -rf DockerLocal/data/dumps/$SITE_NAME.import.sql
  echo "✅ === Dump file $SITE_NAME.import.sql deleted"
else
  echo "☑️  === No dump file $SITE_NAME.import.sql found"
fi

COMMANDS_DIR=$CURRENT_DIR/DockerLocal/commands

cd $COMMANDS_DIR

## DB - Delete the db inside the container for <site-name> if exists
### See if <site-name> is in the list of databases
./site-ssh -h=mysql -c="echo 'show databases;' | mysql -u root -p1234" | grep -qw $SITE_NAME
if [ $? -eq 0 ]; then
  echo "👉 === Deleting database $SITE_NAME"
  ./site-ssh -h=mysql -c="echo 'drop database if exists $SITE_NAME' | mysql -u root -p1234"
  echo "✅ === Database $SITE_NAME deleted"
else
  echo "☑️  === No database $SITE_NAME found"
fi
