#!/bin/bash

#### Required variables
# WWW_HOME: Web app home directory
# WWW_USER: Web app execution user

export HOME=/root

cd $WWW_HOME/current/
. .env

yes | sudo COMPOSER_ALLOW_SUPERUSER=1 /bin/composer install
sudo /bin/php artisan livewire:publish --assets
yes | sudo /bin/php artisan migrate
sudo /bin/php artisan storage:link
sudo /bin/php artisan cache:clear
[ $? -eq 0 ]&& sudo /bin/php artisan config:clear
[ $? -eq 0 ]&& sudo /bin/php artisan config:cache
[ $? -eq 0 ]&& sudo /bin/php artisan route:clear
[ $? -eq 0 ]&& sudo /bin/php artisan view:clear
[ $? -eq 0 ]&& sudo /bin/php artisan clear-compiled
[ $? -eq 0 ]&& sudo /bin/php artisan optimize
[ $? -eq 0 ]&& yes | sudo /bin/composer dump-autoload
[ $? -eq 0 ]&& sudo rm -f bootstrap/cache/config.php
[ $? -eq 0 ]&& sudo chown -R ${WWW_USER}. $WWW_HOME

exit $?