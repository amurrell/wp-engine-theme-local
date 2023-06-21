#!/usr/bin/env bash

### User will run: `./run.sh <site-name>`

### Setup Goals:
# 1. Check if wp folder is empty - if so, download wp
# 2. Check if <site-name> was passed. If not, ask for one
# 3. Check if themes/<site-name> exists. If not, ask if they
#   - ask if they will use version-controlled theme or downloaded theme?
#   - if version-controlled: ask for a git remote url so we can add as a submodule - also ask what branch to use
# 4. Check if wp-engine-downloads/<site-name> exists. If not, tell them to download from wp-engine & run again when complete.
# 5. Check if wp-engine-downloads/<site-name>/themes/<site-name> exists. If not, tell them to download from wp-engine or make sure name of theme matches & run again when complete.

### Swap Site: Check folders exist, and swap.
# 1. If wp-engine-downloads/<site-name>/plugins
#  - clear and/or replace html/wp-content/plugins contents with wp-engine-downloads/<site-name>/wp-content/plugins
# 2. Repeat for: mu-plugins & uploads
# 3. If themes/<site-name> exists, replace html/themes/<site-name> with contents of themes/<site-name>
# 4. else if wp-engine-downloads/<site-name>/themes exists, replace html/themes/<site-name> with contents of wp-engine-downloads/<site-name>/themes

### Database & Run:
# 1. See if DockerLocal/data/dumps/<site-name>.import.sql exists
#  - if not, tell them to do and run again. exit.
#  - If it does exist, continue...
# 2. cd DockerLocal/commands and run ./site-up -c=<site-name>
# 3. cd DockerLocal/commands and run ./site-db -i=<site-name> -f=<site-name>import.sql

### Capture user input
SITE_NAME=$1

### WORDPRESS - Check if wp folder is empty - if so, download wp
if [ -z "$(ls -A html/wp)" ]; then
  echo "👉 === wp folder is empty - downloading WordPress"
  curl -O https://wordpress.org/latest.tar.gz
  tar -xzf latest.tar.gz
  rm latest.tar.gz
  mv wordpress/* html/wp
  echo "✅ === WordPress downloaded"
else
  echo "☑️  === wp folder is already installed"
fi

### SITE NAME - Check if <site-name> was passed. If not, ask for one
if [ -z "$SITE_NAME" ]; then
  echo "👉 === No site name passed. Please enter a site name:"
  read SITE_NAME
fi

### THEMES - Check if themes/<site-name> exists. If not, ask if they will use version-controlled theme or downloaded theme?
if [ ! -d "themes/$SITE_NAME" ]; then
  echo "👉 === No theme found for $SITE_NAME. Would you like to use a version-controlled theme or a downloaded theme?"
  echo "👉 === Enter 'v' for version-controlled or 'd' for downloaded:"
  read THEME_TYPE
  if [ "$THEME_TYPE" == "v" ]; then
    echo "👉 === Please enter the git remote url for the theme:"
    read THEME_GIT_URL
    ## if empty, error & run again
    if [ -z "$THEME_GIT_URL" ]; then
      echo "👉 === No git remote url entered. Please run this script again."
      exit 1
    fi
    echo "👉 === Please enter the git branch for the theme:"
    read THEME_GIT_BRANCH
    ## if empty, error & run again
    if [ -z "$THEME_GIT_BRANCH" ]; then
      echo "👉 === No git branch entered. Please run this script again."
      exit 1
    fi
    echo "👉 === Adding theme as a submodule"
    git submodule add -b $THEME_GIT_BRANCH $THEME_GIT_URL themes/$SITE_NAME
    echo "✅ === Theme added as a submodule"
  elif [ "$THEME_TYPE" == "d" ]; then
    echo "👉 === Please put a theme folder named $SITE_NAME in the wp-engine-downloads folder (eg. download from wp-engine via SFTP) and run this script again."
    exit 1
  else
    echo "👉 === Invalid option. Please run this script again."
    exit 1
  fi
else
  echo "☑️  === Theme found for $SITE_NAME"
fi

