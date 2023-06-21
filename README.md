# WP-Engine Theme Local

**Local development** (via docker) wordpress "wrapper" for wp-engine hosted site, with support for a **version-controlled theme** as a submodule.

All your plugins, uploads, and database files will be stored in the `wp-engine-downloads/` folder that you will populate from wp-engine SFTP.

Working on multiple sites? You can swap between sites by running the **run script** again.

Example:

```
./run.sh mysite
```

Theme Development:

All done inside theme folders: eg. `themes/mysite` submodule folder or static files: `wp-engine-downloads/mysite/<plugins|uploads|themes>` folders

---

## Requirements

Docker Desktop (Docker-Compose & Docker-Engine)

*Tested on Mac Ventura 13.3 & Docker Desktop 4.20.1*

---

## Install

👉 Setup this repo & download your site files

1. Clone the repo - *(Commiting changes to this wrapper? [make private repo recommended](#private-repo-recommended))*
1. Create downloads folder: `mkdir wp-engine-downloads/<site-name>`
1. Copy files to `wp-engine-downloads/<site-name>/*` - via [wp-engine SFTP](#sftp---wp-engine) or other method (keep consistent naming) - copy: plugins, mu-plugins (may cause issues, so can leave out), mysql.sql (db backup from wp-engine), uploads, and themes (if not using submodule).
1. If you can't use latest version of wordpress, download the version you want and put manually at `html/wp`
1. Use `run.sh <site-name>` and follow prompts.

The **run script** will do the following:

- Install latest wordpress (if not already installed)
- Install DockerLocal (if not already installed) - asks [php version](#php-version) 1st time, change it as needed.
- Install your theme as a git submodule OR use your downloaded theme
- Create symbolic links relative to docker containers for: site-specific folders into html/wp-content folder
- Start your DockerLocal (first time takes a while; very fast when image is cached)
- Import your database (if not already imported)

✅ If steps are done correctly, your site will be running... perhaps at: http://localhost:3028

📓 Read about [local development - theme files, wp-admin, npm, etc](#development--persistence) next!

---

## Contents

- [About](#wp-engine-theme-local)
- [Requirements](#requirements)
- [👉 Install & Run Site](#install)
- [Usages](#usages)
- [Development & Persistence](#development--persistence)

- [Delete Site](#delete)
- [DockerLocal](#dockerlocal)
    - [PHP version](#php-version)
    - [Database](#database)
    - [Read more about DockerLocal](#read-more-about-dockerlocal)
- [SFTP - WP-Engine](#sftp---wp-engine)
    - [Generate SFTP credentials](#generate-sftp-credentials)
    - [SFTP Client Download](#sftp-client-tested-w-filezilla)
- [WP Overrides](#wp-overrides)
- [Private Repo Recommended](#private-repo-recommended)

---

## Usages

Very useful for developers to do:

- local testing of PHP upgrades
- plugin upgrades
- development
- using an IDE debugger to track down issues
- start using version control on a theme that was not previously version controlled
- turn this wrapper repo into a private local development repo for however many themes a team is working on.

[☝️ Back to Contents](#contents)

---

## Development & Persistence

### Edit Files
Make all changes to the files in the paths: `wp-engine-downloads/<site-name>` and `themes/<site-name>` - not the symbolic links in `html/wp-content`. The symbolic links are created by the **run script** and are relative to the docker container, so the `html` paths will not exist in your local file system.

### Theme - Version Controlled Submodule
If you are using a submodule for your theme, you can develop it in the `themes/<site-name>` folder. You can `cd` into the folder on your local file system and use git commands to commit and push to the submodule's repo!

Example: Git commands to commit and push to the submodule's repo:

```
cd themes/mysite
git status
git add .
git commit -m "my commit"
git push origin dev
```

### NPM
DockerLocal is very nice in that you don't need to install npm or nvm locally - you can rely on the containers. Make sure your theme folder has an `.nvmrc` file in it for `nvm use`.

```
# just do it:
cd DockerLocal/commands
./site-npm -n="npm install && npm run dev" -p=html/wp-content/themes/<site-name>

# or, set app-path config file to avoid typing it all the time (until you change themes again)
echo "html/wp-content/themes/<site-name>" > DockerLocal/app-path
cd DockerLocal/commands
./site-npm -n="npm install && npm run dev"

# or use it directly - ssh first
cd DockerLocal/commands
./site-ssh -h=web
cd html/wp-content/themes/<site-name>
nvm use
npm install
npm run dev
```

### Persistence

While you are swapping your "themes" out via **run script** your files are safe in the `wp-engine-downloads/<site-name>` folder (unless you run the **delete script**). Changes to your wp-content files will be preserved in these folders even though the symbolic links are being swapped out in the `html/*` paths.

Take a look **inside the docker container** to see the symbolic links.

```
cd DockerLocal/commands
./site-ssh -h=web
ls -al /var/www/site/html/wp-content/
ls -al /var/www/site/html/wp-content/themes/
```

### WP-ADMIN

You will go to a different URL than you are used to: http://localhost:3028/wp/wp-admin *(or if using proxylocal, your docker.site.com url.)*

You may have issues if you copied over mu-plugins from wp-engine SFTP - you can just delete it from `wp-engine-downloads/<your-site>` and refresh - should remove issues.

### XDebug

This project includes `.vscode` folder with extension recommendation (PHP debug) and a launch.json file with settings that work with Dockerlocal (exposed port 9003).

This means that you are just seconds away from debugging! 

1. Make sure you have the xdebug extension installed / enabled. - can also type `@recommended` in extensions panel.
2. Make sure DockerLocal is running (you can see your site running in browser)
3. Add a breakpoint to debug at: Go into a file, eg. your themes footer and on the left side of a line, click till red circle comes up
4. Enter debug panel (left menu "bug" + play button) & select from dropdown Run and Debug "WP-Theme-Local: Xdebug" & press play in command palette.
5. Now, trigger your site - go to the page and refresh it. 
6. Enjoy debugging - vscode should popup at breakpoint and you can inspect values
7. Press stop to exit debug session.

[☝️ Back to Contents](#contents)

---

## DockerLocal

Using [DockerLocal](https://github.com/amurrell/DockerLocal) to run your site locally means you get access to full LEMP stack with PHP-X.X, Nginx, MariaDB/MySQL, Redis, and Xdebug. It also comes with nvm & pm2. First time you install, the whole container will be downloading and installing. Will be very fast after Docker caches the image.

You can do the following to control your machine...

Run all commands from:

`cd DockerLocal/commands`

```
### Start/Stop
./site-up # start the containers
./site-down # stop the containers

### SSH
./site-ssh -h=web # ssh into the web container
./site-ssh -h=mysql # ssh into the db container
./site-ssh -h=webroot # ssh into the web container, as root
./site-ssh -h=mysqlroot # ssh into the db container, as root

### DB import/export
./site-db -i=mysite -f=<name-of-import-sql-file> # import the database, relative to DockerLocal/data/dumps/
./site-db -d=mysite # export the database, into DockerLocal/data/dumps/

### Logs and helpers
./site-logs # tail the logs - access, php, error logs
./site-npm -p=<path-to-package.json> -n="npm install && npm run dev" # relative to html/, relies on nvmrc file
```

[☝️ Back to Contents](#contents)

---

### PHP version

If you need to change PHP version (eg. between themes), you can do so by updates the file `DockerLocal/versions/override-php-version` with contents `8.0` (or whatever version you want 7.3+). Then run from `DockerLocal/commands` the up script `./site-up` and it will rebuild the container with the new version. It will take a while to install all the PHP packages again for that version.

[☝️ Back to Contents](#contents)

---

### Database

The `./run` script will copy `wp-engine-downloads/<site-name>/mysql.sql` to `DockerLocal/data/dumps/<site-name>.import.sql` for you. If you want to preserve this file and avoid deletion from the [**delete script**](#delete), rename it to something like `DockerLocal/data/dumps/<site-name>.save-yyyy-mm-dd.sql`.

If you need to re-upload this file, use docker local command: `./site-db -i=mysite -f=<name-of-import-sql-file>` relative to `DockerLocal/data/dumps/`

[☝️ Back to Contents](#contents)

---

### Read more about DockerLocal

https://github.com/amurrell/DockerLocal

There are a lot of customizations you can make to your DockerLocal install. For example:

- find out how to use mysql vs mariadb (default)
- how to make customizations to your nginx.site.conf file
- how to download specific PHP packages into your DockerFile
- how to use the debugger

[☝️ Back to Contents](#contents)

---

## Delete

Maybe you want to remove a site you are not using anymore, or perhaps to "undo" the `./run.sh site`. You can accomplish with the delete script...

✋ Be careful running this though, especially if you want to preserve the database, the downloaded wp files or your changes to them. It will delete everything!

- It is recommended to rename your `DockerLocal/data/dumps/<site-name>.import.sql` file eg. `<site-name>.save-yyyy-mm-dd.sql`


Delete a "site" with:

```
./delete.sh <site-name>
```

Will delete the following:

- git submodule (if exists) & updates `.gitmodules` files
- themes/<site-name>
- wp-engine-downloads/<site-name>/*
- DockerLocal/data/dumps/<site-name>.import.sql
- DockerLocal DB container's database

[☝️ Back to Contents](#contents)

---

## SFTP - WP-Engine

Skip to "SFTP Client" below if you have already been given SFTP creds to download files

### Generate SFTP credentials:

1. Login to wp-engine portal
1. Click on your site -> specific environment
1. Click on SFTP in menu
1. Setup a new SFTP user - save the password in a manager
1. Use SFTP client (eg. filezilla) to download the files into `wp-engine-downloads/<site-name>` folder

### SFTP Client (tested w/ filezilla):

Don't have a client? Download one - eg. [filezilla](https://filezilla-project.org/download.php?type=client)

- **Host:** Make sure you put `sftp://` in front of the host name
    - eg. `sftp://mysite.wpengine.com`
- **Port:** 2222
- **User:** The user you created / were told to use
- **Password:** The password you created / were told to use

In left pane, navigate to `wp-engine-downloads/<site-name>` folder (create it if does not exist). In right pane, navigate to the root of your site.

To copy:

- double click the wp-content folder
- then click + cmd to multi select on:
    - mu-plugins (may cause issues - wp-engine plugins are not needed locally! - just skip this folder to be safe.)
    - plugins
    - uploads
    - mysql.sql (the most recent db backup, how useful)
    - (and themes if not using submodule)
- right click on any of the selected files/folders and click download
    - it may take a while bc plugins usually have a lot of files in them or the DB file is large

[☝️ Back to Contents](#contents)

---

## WP Overrides

- The **latest version of wordpress** will be downloaded and installed and put into `html/wp` - override by downloading manually and replacing this folder.
- A `wp-config.php` file exists and works with DockerLocal to connect to the DB using on environmental varaibles `html/wp-config.php`. You probably do not need to edit this, but you *can*.

[☝️ Back to Contents](#contents)

---

## Private Repo Recommended

If you or your team will be commiting to this repo, it is recommended to rename the origin to something else, and add your own origin...and to make this repo private.

See this [stackoverflow answer](https://stackoverflow.com/a/30352360) on how to copy a public repo to your own private repo - but still get updates from the public one.

Why?

You may be working on these wp-engine projects with a team of people and may need to privately share the repo with specific files/themes/submodules that get version-controlled afterall (removing some from files from `.gitignore`). Hence, it should become "your" repo.

**Alternatively, you can use this repo with no plans to commit.** If not everyone can use the SFTP method to get your site files, try hosting them in another secure, team-accessible location - eg. google drive, dropbox, etc. Then instruct your team to follow the README and viola - you have a local development environment for the team to use.

[☝️ Back to Contents](#contents)
