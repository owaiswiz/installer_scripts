#!/bin/bash
yum install -y httpd mariadb-server mariadb php php-mysql
sudo bash -c 'echo -e "<?php\nphpinfo();\n?>" > /var/www/html/info.php'
systemctl start httpd.service
systemctl enable httpd.service
systemctl start mariadb
systemctl enable mariadb.service
MYSQLPASS=`dd if=/dev/urandom bs=1 count=12 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev`
mysqladmin -u root -h localhost password "$MYSQLPASS"
echo -e $MYSQLPASS > /root/mysqlpass.txt
