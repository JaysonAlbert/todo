#!/bin/bash

# Flutter Web Deployment Script
# This script builds the Flutter web app and deploys it to the server

set -e  # Exit on any error

# Configuration
LOCAL_BUILD_DIR="frontend/build/web"
REMOTE_SERVER=""
REMOTE_USER=""
REMOTE_WEB_DIR="/var/www/todo"
NGINX_CONFIG_SOURCE="nginx-todo.conf"
NGINX_CONFIG_DEST="/etc/nginx/sites-available/todo"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled/todo"

echo "🚀 Starting Flutter Web Deployment..."

# Step 1: Build Flutter web app
echo "📦 Building Flutter web app..."
cd frontend
flutter pub get
flutter build web --release --base-href="/"
cd ..

echo "✅ Flutter web build completed successfully!"

# Step 2: Check if build directory exists
if [ ! -d "$LOCAL_BUILD_DIR" ]; then
    echo "❌ Error: Build directory not found at $LOCAL_BUILD_DIR"
    exit 1
fi

echo "📁 Build files ready at $LOCAL_BUILD_DIR"

# Step 3: Display deployment instructions
echo ""
echo "🔧 Manual Deployment Steps:"
echo "================================"
echo ""
echo "1. Copy files to your server:"
echo "   rsync -avz --delete $LOCAL_BUILD_DIR/ $REMOTE_USER@$REMOTE_SERVER:$REMOTE_WEB_DIR/"
echo ""
echo "2. Copy nginx configuration:"
echo "   scp $NGINX_CONFIG_SOURCE $REMOTE_USER@$REMOTE_SERVER:/tmp/"
echo ""
echo "3. On your server, run these commands:"
echo "   sudo mv /tmp/nginx-todo.conf $NGINX_CONFIG_DEST"
echo "   sudo ln -sf $NGINX_CONFIG_DEST $NGINX_SITES_ENABLED"
echo "   sudo nginx -t"
echo "   sudo systemctl reload nginx"
echo ""
echo "4. Make sure your SSL certificates are in place and update the nginx config paths"
echo ""
echo "5. Ensure your Go backend is running on port 8080"
echo ""

# Step 4: Option to run deployment automatically (uncomment if you want auto-deployment)
echo "🤖 Automatic Deployment (uncomment in script to enable):"
echo "Would you like to deploy automatically? (y/n)"
read -r response

if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
    echo "Please update the script variables at the top with your server details first!"
    echo "Then uncomment the deployment commands below."
    
    echo "📤 Copying files to server..."
    rsync -avz --delete "$LOCAL_BUILD_DIR/" "$REMOTE_USER@$REMOTE_SERVER:$REMOTE_WEB_DIR/"
    
    echo "⚙️  Copying nginx configuration..."
    scp "$NGINX_CONFIG_SOURCE" "$REMOTE_USER@$REMOTE_SERVER:/tmp/"
    
    echo "🔧 Configuring nginx on server..."
    ssh "$REMOTE_USER@$REMOTE_SERVER" "
        sudo mv /tmp/nginx-todo.conf $NGINX_CONFIG_DEST &&
        sudo ln -sf $NGINX_CONFIG_DEST $NGINX_SITES_ENABLED &&
        sudo nginx -t &&
        sudo systemctl reload nginx
    "
    
    echo "✅ Deployment completed successfully!"
else
    echo "📋 Please follow the manual deployment steps above."
fi

echo ""
echo "🎉 Flutter web app is ready for deployment!"
echo "📍 Build location: $LOCAL_BUILD_DIR"
echo "🌐 Production URL: https://todo.example.com" 