#!/bin/sh
#
# WordPress Setup Script
#
# This script will install and configure WordPress on
# an Ubuntu 14.04 instance
export DEBIAN_FRONTEND=noninteractive;

# Generate root and wordpress mysql passwords
rootmysqlpass=`dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev | tr -dc 'a-zA-Z0-9'`;
wpmysqlpass=`dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev | tr -dc 'a-zA-Z0-9'`;


# Write passwords to file
echo "Root MySQL Password: $rootmysqlpass" > /root/passwords.txt;
echo "Wordpress MySQL Password: $wpmysqlpass" >> /root/passwords.txt;

apt-get update;
apt-get -y upgrade;
# Install Nginx/MySQL
apt-get -y install debconf-utils
apt-get -y install mysql-server
apt-get install -y php5-fpm php5-mysql mysql-client unzip;
echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/nginx-stable.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C300EE8C
apt-get update
apt-get -y install nginx
#start nginx
service nginx start
# Download and uncompress WordPress
wget https://wordpress.org/latest.zip -O /tmp/wordpress.zip;
cd /tmp/ || exit;
unzip /tmp/wordpress.zip;
# Set up database user
/usr/bin/mysqladmin -u root -h localhost create wordpress;
/usr/bin/mysqladmin -u root -h localhost password $rootmysqlpass;
/usr/bin/mysql -uroot -p$rootmysqlpass -e "CREATE USER wordpress@localhost IDENTIFIED BY '"$wpmysqlpass"'";
/usr/bin/mysql -uroot -p$rootmysqlpass -e "GRANT ALL PRIVILEGES ON wordpress.* TO wordpress@localhost";
# Configure PHP
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini
sed -i "s|listen = 127.0.0.1:9000|listen = /var/run/php5-fpm.sock|" /etc/php5/fpm/pool.d/www.conf;
service php5-fpm restart
# Configure Nginx
mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
cat > /etc/nginx/sites-available/default << "EOF"
server {
	listen 80 default_server;
	listen [::]:80 default_server ipv6only=on;
	root /var/www/html;
	index index.php index.html index.htm;
	server_name localhost;
	location / {
			# First attempt to serve request as file, then
			# as directory, then fall back to displaying a 404.
			try_files $uri $uri/ /index.php?q=$uri&$args;
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
			fastcgi_pass unix:/var/run/php5-fpm.sock;
			fastcgi_index index.php;
			include fastcgi.conf;
	}
}
EOF

cat /etc/nginx/sites-available/default
# Configure Nginx sites-available
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/wordpress
rm /etc/nginx/sites-available/default
rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/wordpress
#Configure WordPress
cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php;
sed -i "s|'DB_NAME', 'database_name_here'|'DB_NAME', 'wordpress'|g" /tmp/wordpress/wp-config.php;
sed -i "s/'DB_USER', 'username_here'/'DB_USER', 'wordpress'/g" /tmp/wordpress/wp-config.php;
sed -i "s/'DB_PASSWORD', 'password_here'/'DB_PASSWORD', '$wpmysqlpass'/g" /tmp/wordpress/wp-config.php;
for i in `seq 1 8`
do
wp_salt=$(</dev/urandom tr -dc 'a-zA-Z0-9!@#$%^&*()\-_ []{}<>~`+=,.;:/?|' | head -c 64 | sed -e 's/[\/&]/\\&/g');
sed -i "0,/put your unique phrase here/s/put your unique phrase here/$wp_salt/" /tmp/wordpress/wp-config.php;
done
cp -Rf /tmp/wordpress/* /var/www/html/.;
rm -f /var/www/index.html;
chown -Rf www-data:www-data /var/www/html;
service nginx restart;
