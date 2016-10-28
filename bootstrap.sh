#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update -y
sudo apt-get upgrade -y

# Get "add-apt-repository" Command
sudo apt-get install -y software-properties-common

# Install Basics: Utilities and some Python dev tools
sudo apt-get install -y build-essential git vim tmux curl wget unzip pigz \
    python-pip python-dev supervisor htop

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
# php fpm
sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/fpm/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.0/fpm/php.ini
sudo sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.0/fpm/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 128M/" /etc/php/7.0/fpm/php.ini
sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/7.0/fpm/php.ini
sudo sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/7.0/fpm/php.ini
sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.0/fpm/php.ini


# Add user "vagrant" to group www-data
sudo usermod -a -G www-data vagrant

# Install MySQL non-interactively
sudo debconf-set-selections <<< "mysql-community-server mysql-community-server/data-dir select ''"
sudo debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password Passw0rd"
sudo debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password Passw0rd"
sudo sudo apt-get install -y mysql-server

# Set Timezone (Server/MySQL)
sudo ln -sf /usr/share/zoneinfo/UTC /etc/localtime
sudo mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql --user=root --password=Passw0rd mysql

# Install cache software
sudo apt-get install -y redis-server memcached beanstalkd

# Add 1GB swap for memory overflow
sudo fallocate -l 1024M /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo "/swapfile   none    swap    sw    0   0" | sudo tee -a /etc/fstab
printf "vm.swappiness=10\nvm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf && sudo sysctl -p


# Reload services
sudo service nginx restart
sudo service php7.0-fpm restart
sudo service mysql restart