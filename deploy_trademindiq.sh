#!/bin/bash

# TradeMindIQ Complete Deployment Script
# This script will deploy both frontend and backend to your server

echo "🚀 TradeMindIQ Complete Deployment"
echo "=================================="

SERVER_IP="15.204.254.155"
SERVER_USER="ubuntu"
LOCAL_PROJECT_PATH="/Users/kahangabar/Desktop/TradeMindIQ"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Deployment Configuration:${NC}"
echo "• Server: $SERVER_IP"
echo "• User: $SERVER_USER"
echo "• Local Project: $LOCAL_PROJECT_PATH"
echo ""

# Function to check if command was successful
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1 successful${NC}"
    else
        echo -e "${RED}❌ $1 failed${NC}"
        exit 1
    fi
}

# Test server connection
echo -e "${YELLOW}🔍 Testing server connection...${NC}"
ssh -o ConnectTimeout=10 $SERVER_USER@$SERVER_IP "echo 'Connection successful'" 2>/dev/null
check_status "Server connection"

# Build frontend
echo -e "${YELLOW}🏗️ Building frontend...${NC}"
cd "$LOCAL_PROJECT_PATH/tradem_app"
npm install
npm run build
check_status "Frontend build"

# Deploy frontend
echo -e "${YELLOW}📤 Deploying frontend...${NC}"
rsync -avz --delete build/ $SERVER_USER@$SERVER_IP:/var/www/trademindiq/
check_status "Frontend deployment"

# Deploy backend
echo -e "${YELLOW}📤 Deploying backend...${NC}"
rsync -avz --exclude node_modules backend-example/ $SERVER_USER@$SERVER_IP:/var/www/trademindiq/backend/
check_status "Backend deployment"

# Install backend dependencies and start services
echo -e "${YELLOW}🔧 Setting up backend on server...${NC}"
ssh $SERVER_USER@$SERVER_IP << 'EOF'
echo "📦 Installing backend dependencies..."
cd /var/www/trademindiq/backend
npm install

echo "🛑 Stopping existing PM2 processes..."
pm2 stop all || true
pm2 delete all || true

echo "🔍 Finding main backend file..."
if [ -f "simpleServer.js" ]; then
    MAIN_FILE="simpleServer.js"
elif [ -f "server.js" ]; then
    MAIN_FILE="server.js"
elif [ -f "index.js" ]; then
    MAIN_FILE="index.js"
elif [ -f "app.js" ]; then
    MAIN_FILE="app.js"
else
    echo "❌ No main backend file found"
    exit 1
fi

echo "🚀 Starting backend with $MAIN_FILE..."
pm2 start $MAIN_FILE --name "trademindiq-api" -i 2

echo "💾 Saving PM2 configuration..."
pm2 save

echo "📊 PM2 Status:"
pm2 list

echo "🌐 Testing backend locally..."
sleep 5
curl -s http://localhost:3001/api/health || curl -s http://localhost:8000/api/health || echo "Backend health check failed"

EOF

check_status "Backend setup"

# Test deployment
echo -e "${YELLOW}🧪 Testing deployment...${NC}"
echo "Frontend test:"
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$SERVER_IP/)
if [ "$FRONTEND_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Frontend: $FRONTEND_STATUS${NC}"
else
    echo -e "${RED}❌ Frontend: $FRONTEND_STATUS${NC}"
fi

echo "Backend test:"
sleep 3
BACKEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$SERVER_IP/api/docs)
if [ "$BACKEND_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Backend: $BACKEND_STATUS${NC}"
else
    echo -e "${YELLOW}⚠️ Backend: $BACKEND_STATUS (may still be starting)${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo "=================================="
echo -e "${BLUE}🌐 Your TradeMindIQ Platform:${NC}"
echo "• Frontend: http://$SERVER_IP"
echo "• Backend API: http://$SERVER_IP/api/docs"
echo "• Demo Login: demo2@trademindiq.com / demo123"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "1. Visit your platform: http://$SERVER_IP"
echo "2. Test login with demo credentials"
echo "3. Check all features are working"
echo ""
echo -e "${BLUE}💡 Troubleshooting:${NC}"
echo "• View logs: ssh $SERVER_USER@$SERVER_IP 'pm2 logs'"
echo "• Restart backend: ssh $SERVER_USER@$SERVER_IP 'pm2 restart all'"
echo "• Check status: ssh $SERVER_USER@$SERVER_IP 'pm2 list'"
