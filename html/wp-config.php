<?php

/**
 * This is the file where you could put wp-config stuff
 * that should not be in version control.
 **/

$protocol = 'http';
$my_wp_config_file = __DIR__ . '/../conf/wp-config.php';
if (file_exists($my_wp_config_file))
  require $my_wp_config_file;

$table_prefix  = 'wp_';

define('WP_DEFAULT_THEME', 'devwp');

if (!defined('WP_DEBUG'))
  define('WP_DEBUG', false);

if (!defined('AUTOMATIC_UPDATER_DISABLED'))
  define('AUTOMATIC_UPDATER_DISABLED', true);

if (!defined('WP_DISABLE_CRON'))
  define('WP_DISABLE_CRON', true);

if (!defined('WP_POST_REVISIONS'))
  define('WP_POST_REVISIONS', 3);

if (!defined('DISALLOW_FILE_MODS'))
  define('DISALLOW_FILE_MODS', true);

if (!defined('DISALLOW_FILE_EDIT'))
  define('DISALLOW_FILE_EDIT', true);

$host = !empty($_SERVER['HTTP_HOST']) ? $_SERVER['HTTP_HOST'] : '127.0.0.1';

define('WP_HOME', $protocol . '://' . $host);
define('WP_SITEURL', $protocol . '://' . $host . '/wp');

define('WP_CONTENT_DIR', __DIR__ . '/wp-content');
define('WP_CONTENT_URL', $protocol . '://' . $host . '/wp-content');
define('WPMU_PLUGIN_DIR', __DIR__ . '/wp-content/mu-plugins');
define('WPMU_PLUGIN_URL', $protocol . '://' . $host . '/wp-content/mu-plugins');

// if not defined in $my_wp_config, then load from php environmental vars.

// WP-Engine logins may be different in their hash method than when running locally here 
// - so you can update any user using wp-cli.
// For more information, check the readme.
if ( !defined('DB_NAME') && defined( 'WP_CLI' ) && WP_CLI ) {
  // eg. ./site-ssh -h=web; cd /var/www/site/html && wp user update <username> --user_pass=<new-password>

  // Path to the file relative to wp-config.php
  $databaseFilePath = __DIR__ . '/../DockerLocal/database';

  // Check if the file exists to avoid errors
  if (file_exists($databaseFilePath)) {
    // Read the database name from the file
    $databaseName = trim(file_get_contents($databaseFilePath));
  } else {
    // Handle the error case, maybe set a default or throw an error
    $databaseName = 'default_database_name'; // Set your default database name or handle this situation as needed
    // Optionally, you can throw an error or warning if the file doesn't exist
    // error_log('Database configuration file not found.');
  }

  define('DB_NAME', $databaseName);
  define('DB_USER', 'root');
  define('DB_PASSWORD', '1234');
  define('DB_HOST', 'mysql');
}

if (!defined('DB_NAME')) {
  define('DB_NAME', getenv('APP_WP_DB_NAME'));
  define('DB_USER', getenv('APP_WP_DB_USER'));
  define('DB_PASSWORD', getenv('APP_WP_DB_PASSWORD'));
  define('DB_HOST', getenv('APP_WP_DB_HOST'));
}

if (!defined('DB_CHARSET'))
  define('DB_CHARSET', 'utf8');

if (!defined('DB_COLLATE'))
  define('DB_COLLATE', '');

define('AUTH_KEY',         'put your unique phrase here');
define('SECURE_AUTH_KEY',  'put your unique phrase here');
define('LOGGED_IN_KEY',    'put your unique phrase here');
define('NONCE_KEY',        'put your unique phrase here');
define('AUTH_SALT',        'put your unique phrase here');
define('SECURE_AUTH_SALT', 'put your unique phrase here');
define('LOGGED_IN_SALT',   'put your unique phrase here');
define('NONCE_SALT',       'put your unique phrase here');

/** Sets up WordPress vars and included files. */
require_once(__DIR__ . '/wp/wp-settings.php');
