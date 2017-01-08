#!/usr/bin/env bash

export DEBIAN_FRONTEND="noninteractive"

sudo apt-get update -y
sudo apt-get upgrade -y

# Get "add-apt-repository" Command
sudo apt-get install -y software-properties-common

# Install Basics: Utilities and some Python dev tools
sudo apt-get install -y build-essential git vim tmux curl wget unzip pigz \
    python-pip python-dev supervisor htop zsh

# Install Oh-My-Zsh
sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"


# Install Nginx & PHP
sudo apt-get install -y nginx \
    php7.0-fpm php7.0-cli php-mcrypt php-curl php-gd \
    php-sqlite3 php-mysql php-pgsql php-imap php-memcached \
    php-mbstring php-xml php7.0-intl

# Nginx Conf
sudo rm -fr /var/www
sudo ln -sv /vagrant/www /var/www
sudo unlink /etc/nginx/sites-enabled/default
sudo ln -sv /vagrant/conf/site.conf /etc/nginx/sites-enabled/site.conf

# Install Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
printf "\nPATH=\"$(sudo su - ubuntu -c 'composer config -g home 2>/dev/null')/vendor/bin:\$PATH\"\n" | tee -a /home/ubuntu/.profile

# Some dev PHP settings
# php cli
sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/cli/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.0/cli/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 128M/" /etc/php/7.0/cli/php.ini
sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.0/cli/php.ini
sudo sed -i "s/;realpath_cache_ttl.*/realpath_cache_size = 4096k/" /etc/php/7.0/cli/php.ini

# php fpm
sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/fpm/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.0/fpm/php.ini
sudo sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.0/fpm/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 128M/" /etc/php/7.0/fpm/php.ini
sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/7.0/fpm/php.ini
sudo sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/7.0/fpm/php.ini
sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.0/fpm/php.ini
sudo sed -i "s/;realpath_cache_ttl.*/realpath_cache_size = 4096k/" /etc/php/7.0/cli/php.ini


# Add user "ubuntu" to group www-data
sudo usermod -a -G www-data ubuntu

# Install MySQL non-interactively
MYSQL_PASS="Passw0rd"
sudo debconf-set-selections <<< "mysql-community-server mysql-community-server/data-dir select ''"
sudo debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password $MYSQL_PASS"
sudo debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password $MYSQL_PASS"
sudo DEBIAN_FRONTEND="noninteractive" apt-get install -y mysql-server

# Set Timezone (Server/MySQL)
sudo ln -sf /usr/share/zoneinfo/UTC /etc/localtime
sudo mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql --user=root --password=$MYSQL_PASS mysql


# Install PhpMyAdmin
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $MYSQL_PASS"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQL_PASS"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $MYSQL_PASS"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none"
sudo DEBIAN_FRONTEND="noninteractive" apt-get -y install phpmyadmin

# Add new DB and User
DBNAME="mydb"
DBUSER="myuser"
DBPASS="mypass"
mysql -uroot -p$MYSQL_PASS -e "CREATE DATABASE $DBNAME"
mysql -uroot -p$MYSQL_PASS -e "grant all privileges on $DBNAME.* to '$DBUSER'@'localhost' identified by '$DBPASS'"


# Install cache software
sudo apt-get install -y redis-server memcached beanstalkd

# Add 1GB swap for memory overflow
sudo fallocate -l 1024M /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo "/swapfile   none    swap    sw    0   0" | sudo tee -a /etc/fstab
printf "vm.swappiness=10\nvm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf && sudo sysctl -p

# Allow caching of NFS file share
sudo apt-get install -y cachefilesd
echo "RUN=yes" | sudo tee /etc/default/cachefilesd

# Fix Locales
sudo apt-get install language-pack-en

# Reload services
sudo service php7.0-fpm restart
sudo service mysql restart
sudo service nginx restart

# Install Symfony
#sudo curl -LsS https://symfony.com/installer -o /usr/local/bin/symfony
#sudo chmod a+x /usr/local/bin/symfony


