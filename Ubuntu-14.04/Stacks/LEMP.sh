#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo -E apt-get install -y nginx php5-fpm php5-mysql mysql-server php5-mcrypt php5-gd php5-curl
sudo mkdir -p /var/www/html
sudo echo "server {
        listen 80 default_server;
        listen [::]:80 default_server ipv6only=on;
        root /var/www/html;
        index index.php index.html index.htm;
        server_name localhost;
        location / {
            # First attempt to serve request as file, then
            # as directory, then fall back to displaying a 404.
            try_files \$uri \$uri/ =404;
            # Uncomment to enable naxsi on this location
            # include /etc/nginx/naxsi.rules
        }
        error_page 404 /404.html;
        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root /usr/share/nginx/html;
        }
        location ~ \.php$ {
            try_files \$uri =404;
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:/var/run/php5-fpm.sock;
            fastcgi_index index.php;
            include fastcgi.conf;
        }
      }" > /etc/nginx/sites-available/default
sudo echo -e "<?php\nphpinfo();\n?>" > /var/www/html/info.php
sudo cp /usr/share/nginx/html/index.html /var/www/html/
sudo sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini
file=/etc/nginx/fastcgi.conf; if [ ! -f "$file" ]; then sudo ln -s /etc/nginx/fastcgi_params "$file"; fi
MYSQLPASS=`dd if=/dev/urandom bs=1 count=12 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev`
mysqladmin -u root -h localhost password "$MYSQLPASS"
sudo echo -e $MYSQLPASS > /root/mysqlpass.txt
sudo service nginx restart
