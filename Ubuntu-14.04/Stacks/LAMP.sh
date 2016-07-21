#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo -E apt-get install -y apache2 php5-mysql mysql-server libapache2-mod-php5 php5-mcrypt php5-gd php5-curl
sudo echo -e "<?php\nphpinfo();\n?>" > /var/www/html/info.php
sudo sed -i -e "s/index.html index.cgi index.pl index.php/index.php index.html index.cgi index.pl/" /etc/apache2/mods-enabled/dir.conf
MYSQLPASS=`dd if=/dev/urandom bs=1 count=12 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev`
mysqladmin -u root -h localhost password "$MYSQLPASS"
sudo echo -e $MYSQLPASS > /root/mysqlpass.txt
sudo service apache2 restart
