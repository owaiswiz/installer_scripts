yum -y install epel-release
yum -y install nginx php-fpm php-mysql mariadb-server mariadb

mkdir -p /var/www/html
cp /usr/share/nginx/html/index.html /var/www/html/

sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php.ini
sed -i -e "s|listen = 127.0.0.1:9000|listen = /var/run/php-fpm/php-fpm.sock|" /etc/php-fpm.d/www.conf
sed -i -e "s/default_server//" /etc/nginx/nginx.conf

echo 'server {
        listen 80 default_server;
        listen [::]:80 default_server ipv6only=on;
        root /var/www/html;
        index index.php index.html index.htm;
        server_name localhost;
        location / {
            # First attempt to serve request as file, then
            # as directory, then fall back to displaying a 404.
            try_files $uri $uri/ =404;
            # Uncomment to enable naxsi on this location
            # include /etc/nginx/naxsi.rules
        }
        error_page 404 /404.html;
        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root /usr/share/nginx/html;
        }
        location ~ \.php$ {
            try_files $uri =404;
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:/var/run/php-fpm/php-fpm.sock;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
        }
      }' > /etc/nginx/conf.d/default.conf

echo '<?php
      phpinfo();
      ?>' > /var/www/html/info.php

systemctl start mariadb	  
MYSQLPASS=`dd if=/dev/urandom bs=1 count=12 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev`
mysqladmin -u root -h localhost password "$MYSQLPASS"
echo -e $MYSQLPASS > /root/mysqlpass.txt

systemctl start php-fpm
systemctl enable php-fpm.service
systemctl enable nginx.service
systemctl restart nginx