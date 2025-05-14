#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.
set -x # Print commands and their arguments as they are executed.

export DEBIAN_FRONTEND=noninteractive # Avoid interactive prompts during package installation

echo "Starting user_data script execution..."

# Update package lists
echo "Updating package lists..."
sudo apt-get update -y
echo "Package lists updated."

# Install Nginx
echo "Installing Nginx..."
sudo apt-get install -y nginx
echo "Nginx installed."

# Install MySQL Server
echo "Installing MySQL Server..."
sudo apt-get install -y mysql-server
echo "MySQL Server installed."

# Create a custom Nginx welcome page
echo "Creating custom Nginx welcome page..."
sudo tee /var/www/html/index.html > /dev/null <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to Azure VM - $(hostname)</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f8ff; color: #333; text-align: center; }
        h1 { color: #0078d4; }
        p { font-size: 1.2em; }
        .container { background-color: #fff; padding: 20px; border-radius: 8px; box-shadow: 0 0 10px rgba(0,0,0,0.1); display: inline-block;}
    </style>
</head>
<body>
    <div class="container">
        <h1>Hello World! Welcome to your Azure VM!</h1>
        <p>This Nginx page is served from the VM: <strong>$(hostname)</strong></p>
        <p>Provisioned with Terraform and GitHub Actions.</p>
        <p>Nginx and MySQL have been installed.</p>
    </div>
</body>
</html>
EOF
echo "Custom Nginx welcome page created."

# Enable and start Nginx
echo "Enabling and starting Nginx service..."
sudo systemctl enable nginx
sudo systemctl start nginx
echo "Nginx service started."

# Enable and start MySQL
echo "Enabling and starting MySQL service..."
sudo systemctl enable mysql
sudo systemctl start mysql
echo "MySQL service started."

# Note: For a production setup, you would need to run 'mysql_secure_installation'
# (which is interactive) or automate its steps for security hardening.
# This script provides a basic installation.

echo "User_data script execution completed successfully." | sudo tee /var/log/user_data_status.txt
