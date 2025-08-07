#!/bin/bash

# TradeMindIQ Backend Starter
# This script starts your backend services on the server

echo "🚀 Starting TradeMindIQ Backend Services"
echo "======================================="

SERVER_IP="15.204.254.155"
SERVER_USER="ubuntu"

echo "Testing current status:"
echo "Frontend: $(curl -s -o /dev/null -w "%{http_code}" http://$SERVER_IP/)"
echo "Backend:  $(curl -s -o /dev/null -w "%{http_code}" http://$SERVER_IP/api/docs)"
echo ""

echo "📡 Connecting to server to start backend..."
echo "You may be prompted for the server password."
echo ""

# SSH command to start the backend
ssh $SERVER_USER@$SERVER_IP << 'EOF'
echo "🔧 Diagnosing and starting backend services..."

# Check if backend directory exists
if [ -d "/var/www/trademindiq/backend" ]; then
    echo "✅ Backend directory found"
    cd /var/www/trademindiq/backend
    echo "📁 Current directory: $(pwd)"
    echo "📂 Backend files:"
    ls -la
else
    echo "❌ Backend directory not found at /var/www/trademindiq/backend"
    echo "🔍 Searching for backend files..."
    find /var/www -name "*.js" -o -name "package.json" | head -10
fi

echo ""
echo "🔍 Checking PM2 processes..."
pm2 list

echo ""
echo "🛑 Stopping any existing processes..."
pm2 stop all
pm2 delete all

echo ""
echo "🔍 Looking for ecosystem config..."
if [ -f "/var/www/trademindiq/scripts/ecosystem.config.json" ]; then
    echo "✅ Found ecosystem config"
    cat /var/www/trademindiq/scripts/ecosystem.config.json
else
    echo "❌ Ecosystem config not found, checking alternatives..."
    find /var/www -name "ecosystem*" -o -name "pm2*" | head -5
fi

echo ""
echo "� Starting backend services..."
if [ -f "/var/www/trademindiq/backend/server.js" ]; then
    cd /var/www/trademindiq/backend
    echo "Starting from server.js..."
    pm2 start server.js --name "trademindiq-api" -i 2
elif [ -f "/var/www/trademindiq/backend/index.js" ]; then
    cd /var/www/trademindiq/backend
    echo "Starting from index.js..."
    pm2 start index.js --name "trademindiq-api" -i 2
elif [ -f "/var/www/trademindiq/backend/app.js" ]; then
    cd /var/www/trademindiq/backend
    echo "Starting from app.js..."
    pm2 start app.js --name "trademindiq-api" -i 2
else
    echo "🔍 No main backend file found, checking package.json..."
    if [ -f "/var/www/trademindiq/backend/package.json" ]; then
        cd /var/www/trademindiq/backend
        npm start &
        sleep 2
        pm2 start npm --name "trademindiq-api" -- start
    fi
fi

# Save PM2 configuration
pm2 save

echo ""
echo "📊 Final PM2 Status:"
pm2 list

echo ""
echo "🌐 Testing backend locally on server..."
sleep 3
curl -I http://localhost:3001/api/docs 2>/dev/null || curl -I http://localhost:8000/api/docs 2>/dev/null || echo "Backend not responding on common ports"

echo ""
echo "✅ Backend restart completed!"
EOF

echo ""
echo "🎉 Deployment Complete!"
echo "======================"
echo "• Frontend: http://$SERVER_IP"
echo "• Login: demo2@trademindiq.com / demo123"
echo ""
echo "Test your backend:"
curl -I http://$SERVER_IP/api/docs
