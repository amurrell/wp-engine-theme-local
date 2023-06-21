# WP-Engine Theme Local

**Local development** wordpress "wrapper" for wp-engine hosted site, with support for a **version-controlled theme** as a submodule.

All your plugins, uploads, and database files will be stored in the `wp-engine-downloads/` folder that you will populate from wp-engine SFTP (optionally, your theme folder as well).

Working on multiple sites? You can swap between sites by running the **run script** again.

Example:

```
./run.sh mysite
```

---

## Requirements

Docker Desktop (Docker-Compose & Docker-Engine)

*Tested on Mac Ventura 13.3 & Docker Desktop 4.20.1*

---

## Install

👉 Setup this repo & download your site files

1. Clone the repo - *(Commiting changes to this wrapper? [make private repo recommended](#private-repo-recommended))*
1. Create downloads folder: `mkdir wp-engine-downloads/<site-name>`
1. Copy files to `wp-engine-downloads/<site-name>/*` - via [wp-engine SFTP](#sftp---wp-engine) or other method (keep consistent naming) - copy: plugins, mu-plugins, mysql.sql (db backup from wp-engine), uploads, and themes (if not using submodule).
1. If you can't use latest version of wordpress, download the version you want and put manually at `html/wp`
1. Use `run.sh <site-name>` and follow prompts.

The **run script** will do the following:

- Install latest wordpress (if not already installed)
- Install DockerLocal (if not already installed) - asks [php version](#php-version) 1st time, change it as needed.
- Install your theme as a git submodule OR use your downloaded theme
- Copy site-specific folders into html/wp-content folder
- Start your DockerLocal (first time takes a while; very fast when image is cached)
- Import your database (if not already imported)

✅ If steps are done correctly, your site will be running...

---

## Contents

- [About](#wp-engine-theme-local)
- [Requirements](#requirements)
- [👉 Install & Run Site](#install)
- [Usages](#usages)
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

- local testing of PHP upgrades,
- Plugin Upgrades
- development
- using an IDE debugger to track down issues
- start using version control on a theme that was not previously version controlled
- turn this wrapper repo into a private local development repo for many themes a team is working on.

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

If you need to change PHP version (eg. between themes), you can do so by creating a file `DockerLocal/versions/override-php-version` with contents `8.1` (or whatever version you want 7.3+). Then run from `DockerLocal/commands` the up script `./site-up` and it will rebuild the container with the new version. It will take a while to install all the PHP packages again for that version.

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

[☝️ Back to Contents](#contents)

---

## Delete

Maybe you want to remove a site you are not using anymore, or perhaps to "undo" the `./run.sh site`. You can accomplish with the delete script...

✋ Be careful running this though, especially if you want to preserve the database.

- It is recommended to rename your `DockerLocal/data/dumps/<site-name>.import.sql` file eg. `<site-name>.save-yyyy-mm-dd.sql`


Delete a "site" with:

```
./delete.sh <site-name>
```

Will delete the following:

- git submodule (if exists) & updates `.gitmodules` files
- themes/<site-name>,
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
    - mu-plugins
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

If you will be commiting to this repo, it is recommended to rename the origin to something else, and add your own origin...and to make this repo private.

See this [stackoverflow answer](https://stackoverflow.com/a/30352360) on how to copy a public repo to your own private repo - but still get updates from the public one.

Why?

You may be working on these wp-engine projects with a team of people and may need to privately share the repo with specific files/themes/submodules that get version-controlled afterall (removing some from files from `.gitignore`). Hence, it should become "your" repo.

Alternatively, you can use this repo with no plans to commit. If not everyone can use the SFTP method to get your site files, try hosting them in another secure, team-accessible location - eg. google drive, dropbox, etc. Then instruct your team to follow the README and viola - you have a local development environment.

[☝️ Back to Contents](#contents)
