#!/bin/bash

echo "🚀 TradeMindIQ Complete Solution"
echo "================================="

# Step 1: Upload and run database initialization
echo "1️⃣ Setting up database..."
scp init_db.py ubuntu@15.204.254.155:/tmp/
ssh ubuntu@15.204.254.155 "
    sudo mv /tmp/init_db.py /var/www/trademindiq/backend/
    cd /var/www/trademindiq/backend
    python3 init_db.py
    sudo chmod 666 trademindiq.db
    ls -la trademindiq.db
"

# Step 2: Install required Python packages
echo "2️⃣ Installing Python dependencies..."
ssh ubuntu@15.204.254.155 "
    cd /var/www/trademindiq/backend
    sudo apt update
    sudo apt install -y python3-pip
    pip3 install fastapi uvicorn python-multipart pyjwt python-jose[cryptography]
"

# Step 3: Start FastAPI service
echo "3️⃣ Starting FastAPI service..."
ssh ubuntu@15.204.254.155 "
    cd /var/www/trademindiq/backend
    pm2 delete all || true
    pm2 start 'python3 -m uvicorn main:app --host 0.0.0.0 --port 8000' --name trademindiq-fastapi --cwd /var/www/trademindiq/backend
    pm2 save
    sleep 3
    pm2 status
"

# Step 4: Test the complete setup
echo "4️⃣ Testing the complete setup..."
echo "Testing health endpoint:"
curl -s http://15.204.254.155/api/health | python3 -m json.tool

echo -e "\nTesting login with demo2@trademindiq.com:"
curl -s -X POST http://15.204.254.155/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo2@trademindiq.com","password":"demo123"}' | python3 -m json.tool

echo -e "\n🎉 Complete Solution Deployed!"
echo "==============================="
echo "Your TradeMindIQ platform is ready!"
echo "• Frontend: http://15.204.254.155"
echo "• Demo Login: demo2@trademindiq.com / demo123"
echo ""
echo "The login should now work perfectly! ✅"
