#!/bin/bash

# Function to show a loading bar
run_with_progress() {
    command="$1"
    echo -n "[$2] In progress... "
    if eval "$command" &> /dev/null; then
        echo -e "\e[32mDone\e[0m" # Green "Done"
    else
        echo -e "\e[31mFailed\e[0m" # Red "Failed"
        echo "Error encountered during: $2"
        eval "$command" # Show the command output for debugging
        exit 1
    fi
}

# Prompt user for inputs
read -p "Domain Name (No .com): " domainname
read -p "GitHub Token: " githubtoken
read -p "GitHub User: " githubuser
read -p "GitHub Repository (xxxxx.git): " githubres

# Update and install necessary packages
echo "Updating system and installing dependencies..."
run_with_progress "sudo apt update && sudo apt upgrade -y" "System update and upgrade"
run_with_progress "sudo apt install -y apache2 mysql-server php php-bcmath php-ctype php-json php-xml php-pdo php-mbstring php-curl php-gd php-imagick php-zip redis composer curl" "Installing dependencies"

# Install NVM
echo "Installing NVM..."
run_with_progress "curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash" "Installing NVM"
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
source "$NVM_DIR/bash_completion"

# Check and handle existing configuration
config_path="/etc/apache2/sites-available/$domainname.conf"
if [ -f "$config_path" ]; then
    echo "Configuration for $domainname exists. Deleting and recreating."
    run_with_progress "sudo rm \"$config_path\"" "Removing existing Apache configuration"
fi

# Create Apache configuration
echo "Creating Apache configuration..."
sudo tee "$config_path" > /dev/null <<EOF
<VirtualHost *:80>
    ServerName $domainname.com
    ServerAlias www.$domainname.com
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/$domainname.com/public
    #Redirect / https://$domainname.com # Uncomment when SSL is active

    <Directory "/var/www/html/$domainname.com/public/">
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>

<IfModule mod_ssl.c>
    <VirtualHost *:443>
        ServerName $domainname.com
        DocumentRoot /var/www/html/$domainname.com/public

        <Directory />
            Require all denied
            Options None
            AllowOverride None
        </Directory>

        <Directory "/var/www/html/$domainname.com/public/">
            Options FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>

        ErrorLog \${APACHE_LOG_DIR}/$domainname/error.log
        CustomLog \${APACHE_LOG_DIR}/$domainname/access.log combined

        SSLEngine on
        SSLProtocol all
        SSLCertificateFile /etc/apache2/ssl/$domainname.com.pem
        SSLCertificateKeyFile /etc/apache2/ssl/$domainname.com.key
    </VirtualHost>
</IfModule>
EOF

# Enable Apache configuration
echo "Configuring Apache..."
run_with_progress "sudo a2dissite 000-default.conf > /dev/null" "Disabling default site"
run_with_progress "sudo a2enmod rewrite > /dev/null" "Enabling mod_rewrite"
run_with_progress "sudo a2ensite $domainname.conf > /dev/null" "Enabling site configuration"
run_with_progress "sudo service apache2 restart > /dev/null" "Restarting Apache"

# Set up project directory
echo "Setting up project directory..."
run_with_progress "sudo mkdir -p /var/www/html/$domainname.com" "Creating project directory"
run_with_progress "sudo chown -R ubuntu:www-data /var/www/html/$domainname.com" "Setting directory ownership"
cd "/var/www/html/$domainname.com"

# Git setup
echo "Setting up Git repository..."
run_with_progress "git init > /dev/null" "Initializing Git repository"
run_with_progress "git remote add origin https://$githubuser:$githubtoken@github.com/$githubuser/$githubres" "Adding remote repository"
run_with_progress "git pull origin master > /dev/null" "Pulling latest code"

# Set permissions
echo "Setting permissions..."
run_with_progress "sudo find . -type f -exec chmod 664 {} \;" "Setting file permissions"
run_with_progress "sudo find . -type d -exec chmod 775 {} \;" "Setting directory permissions"
run_with_progress "sudo chgrp -R www-data storage bootstrap/cache" "Changing group for storage and cache"
run_with_progress "sudo chmod -R ug+rwx storage bootstrap/cache" "Setting permissions for storage and cache"

# Install dependencies
echo "Installing project dependencies..."
run_with_progress "composer install > /dev/null" "Installing Composer dependencies"
run_with_progress "nvm install --lts > /dev/null" "Installing Node.js LTS version"
run_with_progress "nvm use --lts > /dev/null" "Using Node.js LTS version"
run_with_progress "npm install > /dev/null" "Installing NPM dependencies"
run_with_progress "npm run dev > /dev/null" "Building front-end assets"

echo -e "\n\e[32mSetup complete!\e[0m"
