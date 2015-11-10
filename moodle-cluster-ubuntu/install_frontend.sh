#!/bin/bash
apt-get -y update
apt-get -y install python-software-properties
add-apt-repository -y ppa:ondrej/php5-oldstable
apt-get -y update

# set up a silent install of MySQL
dbpass=$1

export DEBIAN_FRONTEND=noninteractive
echo mysql-server-5.6 mysql-server/root_password password $dbpass | debconf-set-selections
echo mysql-server-5.6 mysql-server/root_password_again password $dbpass | debconf-set-selections

# install the LAMP stack
apt-get -y install apache2 mysql-client mysql-server php5

# install moodle requirements
apt-get -y install graphviz aspell php5-pspell php5-curl php5-gd php5-intl php5-mysql php5-xmlrpc php5-ldap

# add port 8000 for admin access
perl -0777 -p -i -e 's/Listen 80/Listen 80\nListen 8080/ig' /etc/apache2/ports.conf
perl -0777 -p -i -e 's/\*:80/*:80 *:8080/g' /etc/apache2/sites-enabled/000-default.conf

# install Moodle
cd /var/www/html
wget https://download.moodle.org/download.php/direct/stable29/moodle-2.9.2.zip -O moodle.zip
apt-get install unzip
unzip moodle.zip

# make the moodle directory writable for owner
chown -R www-data moodle
chmod -R 770 moodle

# create moodledata directory
mkdir /var/www/moodledata
chown -R www-data /var/www/moodledata
chmod -R 770 /var/www/moodledata

# TODO: create cron entry
# * * * * *    /usr/bin/php /path/to/moodle/admin/cli/cron.php >/dev/null

# restart Apache
apachectl restart

# mount share file on /var/www/moodledata
SharedStorageAccountName=$2
SharedAzureFileName=$3
SharedStorageAccountKey=$4
apt-get install cifs-utils
mount -t cifs //$SharedStorageAccountName.file.core.windows.net/$SharedAzureFileName /var/www/moodledata -o uid=$(id -u www-data),vers=2.1,username=$SharedStorageAccountName,password=$SharedStorageAccountKey,dir_mode=0770,file_mode=0770
	
#add mount to /etc/fstab to persist across reboots
chmod 770 /etc/fstab
echo "//$SharedStorageAccountName.file.core.windows.net/$SharedAzureFileName /var/www/moodledata cifs uid=$(id -u www-data),vers=3.0,username=$SharedStorageAccountName,password=$SharedStorageAccountKey,dir_mode=0770,file_mode=0770" >> /etc/fstab
