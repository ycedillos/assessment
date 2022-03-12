#!/bin/bash
set -x

# Install necessary dependencies
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
sudo apt-get update
sudo apt-get -y -qq install curl wget git vim unzip mysql-client apache2 ghostscript libapache2-mod-php php php-bcmath php-curl php-imagick php-intl php-xmlrpc php-soap php-json php-mbstring php-mysql php-xml php-zip php-gd
#sudo add-apt-repository ppa:longsleep/golang-backports -y
#sudo apt-get -y -qq install golang-go

# Setup sudo to allow no-password sudo for "hashicorp" group and adding "terraform" user
sudo groupadd -r hashicorp
sudo useradd -m -s /bin/bash terraform
sudo usermod -a -G hashicorp terraform
sudo cp /etc/sudoers /etc/sudoers.orig
echo "terraform  ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/terraform

# Installing SSH key
sudo mkdir -p /home/terraform/.ssh
sudo chmod 700 /home/terraform/.ssh
sudo cp /tmp/tf-packer.pub /home/terraform/.ssh/authorized_keys
sudo chmod 600 /home/terraform/.ssh/authorized_keys
sudo chown -R terraform /home/terraform/.ssh
sudo usermod --shell /bin/bash terraform

# Configuring Wordpress
sudo mkdir -p /var/www/wordpress
sudo mv /tmp/wordpress.conf /etc/apache2/sites-available/wordpress.conf
sudo rm /etc/apache2/sites-enabled/000-default.conf
sudo rm /etc/apache2/sites-available/000-default.conf
sudo ln -s /etc/apache2/sites-available/wordpress.conf /etc/apache2/sites-enabled
sudo a2enmod rewrite
cd /tmp
curl -O https://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz
touch /tmp/wordpress/.htaccess
mkdir /tmp/wordpress/wp-content/upgrade
sudo cp -a /tmp/wordpress/. /var/www/wordpress
sudo chown -R www-data:www-data /var/www/wordpress
sudo find /var/www/wordpress/ -type d -exec chmod 750 {} \;
sudo find /var/www/wordpress/ -type f -exec chmod 640 {} \;