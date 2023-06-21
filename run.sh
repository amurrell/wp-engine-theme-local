#!/usr/bin/env bash

### Current Directory
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CONTAINER_DIR='/var/www/site'

### User will run: `./run.sh <site-name>`

### Setup Goals:
# 1. Check if wp folder is empty - if so, download wp
# 2. Check if <site-name> was passed. If not, ask for one
# 3. Check if themes/<site-name> exists. If not, ask if they
#   - ask if they will use version-controlled theme or downloaded theme?
#   - if version-controlled: ask for a git remote url so we can add as a submodule - also ask what branch to use
# 4. Check if wp-engine-downloads/<site-name> exists. If not, tell them to download from wp-engine & run again when complete.
# 5. Check if wp-engine-downloads/<site-name>/themes/<site-name> exists (and not using themes/<site-name>).
#   - If not, tell them to download from wp-engine or make sure name of theme matches & run again when complete.
# 6. Check if wp-engine-downloads/<site-name>/mysql.sql exists - if not tell them to put it there (can get from wp-engine via SFTP).
# 7. Install DockerLocal as a submodule - ask what version of PHP to use. Branch will be PHP-<version>

### Swap Site: Check folders exist, and swap.
# 1. If wp-engine-downloads/<site-name>/plugins
#  - clear and/or replace html/wp-content/plugins contents with wp-engine-downloads/<site-name>/wp-content/plugins
# 2. Repeat for: mu-plugins & uploads
# 3. If themes/<site-name> exists, replace html/themes/<site-name> with contents of themes/<site-name>
#  - check if themes/<site-name>/<site-name> exists to use that one instead (nested theme folder inside submodule repo)
# 4. else if wp-engine-downloads/<site-name>/themes exists, replace html/themes/<site-name> with contents of wp-engine-downloads/<site-name>/themes

### Database & Run:
# 1. Copy wp-engine-downloads/<site-name>/mysql.sql to DockerLocal/data/dumps/<site-name>.import.sql if not exists.
#  - if not, tell them to get it and run again. exit.
#  - If it does exist, check if the database file exists in DockerLocal/database - if not (dockerlocal has never ran) - skip
#  - If it does exist, check if the database file exists in DockerLocal/database - if so, then check if the database exists in the container via list command
#  - If it does exist, change the DockerLocal/database file to have contents <site-name> in it. and run ./site-up
#  - If it does not exist, continue...
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
  mkdir -p html/wp
  mv wordpress wp
  mv wp html/
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
    git reset .gitmodules
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

### WP-ENGINE-DOWNLOADS - Check if wp-engine-downloads/<site-name> exists. If not, tell them to download from wp-engine & run again when complete.
if [ ! -d "wp-engine-downloads/$SITE_NAME" ]; then
  echo "👉 === No wp-engine-downloads folder found for $SITE_NAME. Please download from wp-engine via SFTP and run this script again."
  exit 1
else
  echo "☑️  === wp-engine-downloads folder found for $SITE_NAME"
fi

### WP-ENGINE-DOWNLOADS/THEMES - Check if wp-engine-downloads/<site-name>/themes/<site-name does not exist AND themes/<site-name> does not exist
if [ ! -d "wp-engine-downloads/$SITE_NAME/themes/$SITE_NAME" ] && [ ! -d "themes/$SITE_NAME" ]; then
  echo "👉 === No wp-engine-downloads theme folder found for $SITE_NAME and not using theme submodule. Make sure the theme folder matches the site-name. Please download from wp-engine via SFTP and run this script again."
  exit 1
elif [ -d "wp-engine-downloads/$SITE_NAME/themes/$SITE_NAME" ]; then
  echo "☑️  === wp-engine-downloads theme folder found for $SITE_NAME"
fi

### MYSQL.SQL - Check if wp-engine-downloads/<site-name>/mysql.sql exists - if not tell them to put it there (can get from wp-engine via SFTP).
if [ ! -f "wp-engine-downloads/$SITE_NAME/mysql.sql" ]; then
  echo "👉 === No mysql.sql file found for $SITE_NAME in wp-engine-downloads/$SITE_NAME/. Please download from wp-engine via SFTP and run this script again."
  exit 1
else
  echo "☑️  === mysql.sql file found for $SITE_NAME."
fi

### DockerLocal Submodule - Check if DockerLocal submodule exists - if not, initialize it
DOCKERLOCAL_PULLED=false
if [ -z "$(git submodule status | grep DockerLocal)" ]; then
  echo "👉 === No DockerLocal submodule found. Initializing DockerLocal submodule."

  git submodule add -b master git@github.com:amurrell/DockerLocal.git DockerLocal
  echo "✅ === DockerLocal submodule initialized"
else
  # if DockerLocal/versions exists AND override-php-version exists - DOCKERLOCAL_PULLED=true
  if [ -d "DockerLocal/versions" ] && [ -f "DockerLocal/versions/override-php-version" ]; then
    DOCKERLOCAL_PULLED=true
  fi
  # pull updates to DockerLocal submodule
  echo "👉 === DockerLocal submodule found. init submodule recursively."
  git submodule update --init --recursive
  echo "☑️  === DockerLocal submodule found"
fi

# if dockerlocal is not pulled - we want to ask for PHP version and port to run dockerlocal on
if [ "$DOCKERLOCAL_PULLED" = false ]; then
  ## prompt for PHP version
  echo "👉 === Please enter the PHP version you would like to use (eg. 8.0):"
  read PHP_VERSION
  ## if empty, error & run again
  if [ -z "$PHP_VERSION" ]; then
    echo "👉 === No PHP version entered. Please run this script again."
    exit 1
  fi
  echo "$PHP_VERSION" > DockerLocal/versions/override-php-version

  # ask for a port to run dockerlocal on - eg. suggest 3028
  echo "👉 === Please enter a port to run DockerLocal on (eg. 3028):"
  read DOCKERLOCAL_PORT
  ## if empty, error & run again
  if [ -z "$DOCKERLOCAL_PORT" ]; then
    echo "👉 === No port entered. Please run this script again."
    exit 1
  fi
  # if port does not start with 30 and is not 4 chars long, then error
  if [[ ! "$DOCKERLOCAL_PORT" =~ ^30[0-9]{2}$ ]]; then
    echo "👉 === Port must start with 30 and be 4 characters long. Please run this script again."
    exit 1
  fi
  echo "$DOCKERLOCAL_PORT" > DockerLocal/port
  echo "✅ === DockerLocal PHP-version & port set"
fi

### Swap Site: Check folders exist, and swap.
printf "\n\n🏁 === Starting Swap - site $SITE_NAME ...\n\n"

### use a loop for plugins, mu-plugins, uploads, themes (if themes/$SITE_NAME does not exist), etc.
for folder in "mu-plugins" "plugins" "uploads" "themes"; do

  # if folder == themes and  themes/$SITE_NAME exists then skip
  if [ "$folder" == "themes" ] && [ -d "themes/$SITE_NAME" ]; then
    echo "☑️  === themes/$SITE_NAME exists"

    # make symbolic links out the theme - remember to check for nested theme folder
    if [ -d "themes/$SITE_NAME/$SITE_NAME" ]; then
      echo "🔄 === Replacing html/wp-content/themes/$SITE_NAME with themes/$SITE_NAME/$SITE_NAME"

      rm html/wp-content/themes/$SITE_NAME
      ln -s $CONTAINER_DIR/themes/$SITE_NAME/$SITE_NAME html/wp-content/themes/
      echo "✅ === html/wp-content/themes/$SITE_NAME symlinked"
    else
      echo "🔄 === Replacing html/wp-content/themes/$SITE_NAME with themes/$SITE_NAME"

      rm html/wp-content/themes/$SITE_NAME
      ln -s $CONTAINER_DIR/themes/$SITE_NAME html/wp-content/themes/
      echo "✅ === html/wp-content/themes/$SITE_NAME symlinked"
    fi
    continue
  fi

  # remove old symlink so we dont get old site residue.
  rm -rf html/wp-content/$folder

  if [ -d "wp-engine-downloads/$SITE_NAME/$folder" ]; then
    echo "🔄 === Replacing html/wp-content/$folder with wp-engine-downloads/$SITE_NAME/$folder"
    ln -s $CONTAINER_DIR/wp-engine-downloads/$SITE_NAME/$folder html/wp-content/
    echo "✅ === html/wp-content/$folder replaced"
  else
    # make blank state of the folder, even if missing.
    mkdir -p wp-engine-downloads/$SITE_NAME/$folder
    cp html/wp-content/index.php wp-engine-downloads/$SITE_NAME/$folder/
    ln -s $CONTAINER_DIR/wp-engine-downloads/$SITE_NAME/$folder html/wp-content/
    echo "💁 === No wp-engine-downloads $folder folder found for $SITE_NAME. Copying one there and symlinking"
  fi
done
echo "✅ === Finished swapping plugins, mu-plugins, uploads, themes"

### mysql.sql - Copy wp-engine-downloads/<site-name>/mysql.sql to DockerLocal/data/dumps/<site-name>.import.sql if not exists.
printf "\n\n🏁 === Starting Database Swap/Import - site $SITE_NAME ...\n\n"
if [ ! -f "DockerLocal/data/dumps/$SITE_NAME.import.sql" ]; then
  echo "👉 === Copying mysql.sql to DockerLocal/data/dumps/$SITE_NAME.import.sql"
  cp wp-engine-downloads/$SITE_NAME/mysql.sql DockerLocal/data/dumps/$SITE_NAME.import.sql
  echo "✅ === Copied mysql.sql to DockerLocal/data/dumps/$SITE_NAME.import.sql"
else
  echo "☑️  === DockerLocal/data/dumps/$SITE_NAME.import.sql already exists"
fi

COMMANDS_DIR=$CURRENT_DIR/DockerLocal/commands

cd $COMMANDS_DIR

### DockerLocal/database - Check if the database file exists in DockerLocal/database - if not (dockerlocal has never ran) - skip
if [ ! -f "$CURRENT_DIR/DockerLocal/database" ]; then
  echo "👉 === Initialize DockerLocal with this db & import"
  ./site-up -c=$SITE_NAME
  ./site-db -i=$SITE_NAME -f=$SITE_NAME.import.sql
else
  ### DockerLocal/database - Check if the database file exists in DockerLocal/database - if so, then check if the database exists in the container via list command
  echo "👉 === Checking if database exists in container"
  ./site-ssh -h=mysql -c="echo 'show databases'|mysql -u root -p1234" | grep -qw $SITE_NAME
  if [ $? -eq 0 ]; then
    echo "☑️  === Database exists in container - DockerLocal has ran before & db was imported before"
    echo "👉 === Changing DockerLocal/database file to have contents $SITE_NAME"
    echo "$SITE_NAME" > $CURRENT_DIR/DockerLocal/database
    ./site-up
  else
    ### DockerLocal/database - Check if the database file exists in DockerLocal/database - if so, then check if the database exists in the container via list command
    echo "👉 === Database does NOT exist in container - initialize DockerLocal with this db & import"
    ./site-up -c=$SITE_NAME
    ./site-db -i=$SITE_NAME -f=$SITE_NAME.import.sql
    echo "✅ === DockerLocal Up & Database Imported"
  fi
fi

cd $CURRENT_DIR

echo "🏃‍♂️ === Your site should be running..."
