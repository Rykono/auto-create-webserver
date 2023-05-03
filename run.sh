sudo apt update && sudo apt upgrade -y
sudo apt install apache2 mysql-server php php-bcmath php-ctype php-json php-xml php-pdo php-mbstring php-curl redis composer -y
sudo curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm" 
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
source ~/.bashrc
read -p "Domain Name (No .com): " domainname
touch /etc/apache2/sites-available/$domainname.conf
echo -e "<VirtualHost *:80>\r\n        ServerName $domainname.com\r\n        ServerAlias www.$domainname.com\r\n        ServerAdmin webmaster@localhost\r\n        DocumentRoot /var/www/html/$domainname.com/public\r\n        #Redirect / https://$domainname.com #uncomment this when ssl active or live \r\n\r\n        <Directory \"/var/www/html/$domainname.com/public/\">\r\n                Options  FollowSymLinks\r\n                AllowOverride All\r\n                Order Allow,Deny\r\n                Allow from all\r\n        </Directory>\r\n\r\n        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,\r\n        # error, crit, alert, emerg.\r\n        # It is also possible to configure the loglevel for particular\r\n        # modules, e.g.\r\n        #LogLevel info ssl:warn\r\n\r\n        ErrorLog ${APACHE_LOG_DIR}/error.log\r\n        CustomLog ${APACHE_LOG_DIR}/access.log combined\r\n\r\n        # For most configuration files from conf-available/, which are\r\n        # enabled or disabled at a global level, it is possible to\r\n        # include a line for only one particular virtual host. For example the\r\n        # following line enables the CGI configuration for this host only\r\n        # after it has been globally disabled with \"a2disconf\".\r\n        #Include conf-available/serve-cgi-bin.conf\r\n</VirtualHost>\r\n<IfModule mod_ssl.c>\r\n        <VirtualHost *:443>\r\n                ServerAdmin webmaster@localhost\r\n                ServerName $domainname.com\r\n                DocumentRoot /var/www/html/$domainname.com/public\r\n\r\n                <Directory />\r\n                        Order Deny,Allow\r\n                        Deny from all\r\n                        Options None\r\n                        AllowOverride None\r\n                </Directory>\r\n\r\n                <Directory /var/www/html/$domainname.com/public>\r\n                        Options FollowSymLinks\r\n                        AllowOverride All\r\n                        Order Allow,Deny\r\n                        Allow from all\r\n                </Directory>\r\n\r\n\r\n                ErrorLog ${APACHE_LOG_DIR}/$domainname/error.log\r\n                CustomLog ${APACHE_LOG_DIR}/$domainname/access.log combined\r\n\r\n                SSLEngine on\r\n                SSLProtocol all\r\n                SSLCertificateFile /etc/apache2/ssl/$domainname.com.pem\r\n                SSLCertificateKeyFile /etc/apache2/ssl/$domainname.com.key\r\n\r\n                <FilesMatch \"\\.(cgi|shtml|phtml|php)$\">\r\n                                SSLOptions +StdEnvVars\r\n                <\/FilesMatch>\r\n                <Directory /usr/lib/cgi-bin>\r\n                                SSLOptions +StdEnvVars\r\n                <\/Directory>\r\n\r\n        <\/VirtualHost>\r\n<\/IfModule>" >> /etc/apache2/sites-available/$domainname.conf
sudo rm /etc/apache2/sites-available/000-default.conf
sudo rm /etc/apache2/sites-available/default-ssl.conf
sudo a2dissite 000-default.conf
sudo a2enmod rewrite
sudo a2ensite $domainname.conf
sudo service apache2 restart
touch /var/www/html/$domainname.com
cd /var/www/html/$domainname.com
git init
read -p "Github Token: " githubtoken
read -p "Github User: " githubuser
read -p "Github Repository (xxxxx.git): " githubres
git remote add origin https://$githubuser:$githubtoken@github.com/$githubuser/$githubres
git pull origin master
composer install
nvm install --lts
nvm use --lts
npm install
npm run dev


