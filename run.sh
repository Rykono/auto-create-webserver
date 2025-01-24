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
run_with_progress "sudo apt install -y software-properties-common" "Installing software-properties-common"

# Add PHP 8.2 repository
echo "Adding PHP 8.2 repository..."
run_with_progress "sudo add-apt-repository ppa:ondrej/php -y" "Adding Ondřej PHP repository"
run_with_progress "sudo apt update" "Updating package lists"

# Install PHP 8.2 and extensions
echo "Installing PHP 8.2 and required extensions..."
run_with_progress "sudo apt install -y php8.2 php8.2-bcmath php8.2-ctype php8.2-xml php8.2-pdo php8.2-mbstring php8.2-curl php8.2-gd php8.2-imagick php8.2-zip php8.2-intl" "Installing PHP 8.2 and extensions"

# Set PHP 8.2 as the default version
echo "Setting PHP 8.2 as the default version..."
run_with_progress "sudo update-alternatives --set php /usr/bin/php8.2" "Setting PHP 8.2 as default"

# Install other necessary dependencies
run_with_progress "sudo apt install -y apache2 mysql-server redis composer curl build-essential python3" "Installing other dependencies"

# Install NVM
echo "Installing NVM..."
run_with_progress "curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash" "Installing NVM"
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
source "$NVM_DIR/bash_completion"

# Check and handle 000-default.conf
echo "Configuring Apache..."
if sudo a2dissite 000-default.conf &> /dev/null; then
    echo -e "[Disabling default site] \e[32mDone\e[0m" # Green "Done"
else
    echo -e "[Disabling default site] \e[33mSkipped (already disabled or not found)\e[0m" # Yellow "Skipped"
fi

# Check and handle existing project directory
project_dir="/var/www/html/$domainname.com"
if [ -d "$project_dir" ]; then
    echo "Project directory already exists: $project_dir"
    read -p "Do you want to delete the existing project and start over? (y/N): " delete_project
    if [[ "$delete_project" =~ ^[Yy]$ ]]; then
        run_with_progress "sudo rm -rf \"$project_dir\"" "Deleting existing project directory"
    else
        echo -e "\e[31mScript stopped. Existing project retained.\e[0m"
        exit 0
    fi
fi

# Create project directory
echo "Setting up project directory..."
run_with_progress "sudo mkdir -p \"$project_dir\"" "Creating project directory"
run_with_progress "sudo chown -R ubuntu:www-data \"$project_dir\"" "Setting directory ownership"
cd "$project_dir"

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
echo "Running Composer install..."
composer install
echo "Running NVM setup and NPM install..."
nvm install --lts
nvm use --lts
npm install
echo "Running NPM build..."
npm run build

echo -e "\n\e[32mSetup complete!\e[0m"
