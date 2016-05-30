<?php

$databases = array (
  'default' =>
  array (
    'default' =>
    array (
      //            https://www.drupal.org/node/2443839
      'database' => 'drupal',
//            'database' => getenv('DB_1_ENV_MYSQL_DATABASE'),
      'username' => getenv('DB_1_ENV_MYSQL_USER'),
      'password' => getenv('DB_1_ENV_MYSQL_PASSWORD'),
      'host' => getenv('DB_1_PORT_3306_TCP_ADDR'),
      'port' => '',
      'driver' => 'mysql',
      'prefix' => '',
    ),
  ),
);

$settings['hash_salt'] = file_get_contents('/var/www/salt.txt');

$settings['container_yamls'][] = DRUPAL_ROOT . '/sites/development.services.yml';