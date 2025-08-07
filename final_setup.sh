#!/bin/bash

# TradeMindIQ One-Time Setup Script
# This will get your login working once and for all!

echo "🚀 TradeMindIQ Complete Setup"
echo "=============================="

SERVER_IP="15.204.254.155"
SERVER_USER="ubuntu"

echo "1️⃣ Deploying database initialization script..."
scp init_database.py $SERVER_USER@$SERVER_IP:/tmp/

echo "2️⃣ Setting up backend and database..."
ssh $SERVER_USER@$SERVER_IP << 'EOF'

# Create backend directory
sudo mkdir -p /var/www/trademindiq/backend
cd /var/www/trademindiq/backend

# Copy and run database initialization
cp /tmp/init_database.py .
python3 init_database.py

# Create the FastAPI main.py with absolute database path
cat > main.py << 'FASTAPI_CODE'
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import sqlite3
import jwt
import os

app = FastAPI(title="TradeMindIQ API", version="1.0.0")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SECRET_KEY = "trademindiq_secret_key_2025"

# Get absolute path to database
DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "trademindiq.db")

class LoginRequest(BaseModel):
    email: str
    password: str

@app.get("/api/health")
def health_check():
    return {"status": "ok", "service": "TradeMindIQ API", "db_path": DB_PATH}

@app.get("/")
def read_root():
    return {"message": "TradeMindIQ API is running", "status": "ok"}

@app.post("/api/auth/login")
def login(request: LoginRequest):
    try:
        print(f"Attempting login for: {request.email}")
        print(f"Database path: {DB_PATH}")
        
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute(
            "SELECT id, username, email, hashed_password, first_name, last_name, role FROM users WHERE email = ?", 
            (request.email,)
        )
        row = cursor.fetchone()
        conn.close()

        if not row:
            print(f"User not found: {request.email}")
            raise HTTPException(status_code=401, detail="Invalid credentials")

        user_id, username, email, stored_password, first_name, last_name, role = row
        print(f"Found user: {username}")

        # Simple password check (plain text for demo)
        if stored_password != request.password:
            print(f"Password mismatch for {email}")
            raise HTTPException(status_code=401, detail="Invalid credentials")

        # Generate JWT token
        token = jwt.encode({
            "user_id": user_id,
            "username": username, 
            "email": email,
            "role": role
        }, SECRET_KEY, algorithm="HS256")

        return {
            "success": True,
            "message": "Login successful",
            "user": {
                "id": user_id,
                "username": username,
                "email": email,
                "first_name": first_name,
                "last_name": last_name,
                "role": role
            },
            "token": token
        }

    except HTTPException as e:
        raise e
    except Exception as e:
        print(f"Database error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@app.get("/api/portfolio")
def get_portfolio():
    return {
        "total_value": 125000.50,
        "day_change": 2350.75,
        "day_change_percent": 1.92,
        "positions": [
            {"symbol": "AAPL", "shares": 100, "current_price": 175.25, "day_change": 2.50},
            {"symbol": "GOOGL", "shares": 50, "current_price": 2850.00, "day_change": -15.25},
            {"symbol": "TSLA", "shares": 75, "current_price": 245.80, "day_change": 8.90}
        ]
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
FASTAPI_CODE

# Set proper permissions
sudo chown -R ubuntu:ubuntu /var/www/trademindiq/backend

# Stop any existing PM2 processes
pm2 delete all 2>/dev/null || true

# Start FastAPI with PM2
pm2 start "uvicorn main:app --host 0.0.0.0 --port 8000" --name trademindiq-fastapi --cwd /var/www/trademindiq/backend
pm2 save

echo "✅ Backend setup complete!"
pm2 list

EOF

echo "3️⃣ Testing the setup..."
sleep 3

echo "Testing health endpoint:"
curl -s http://$SERVER_IP/api/health | jq .

echo -e "\nTesting login:"
curl -X POST http://$SERVER_IP/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo2@trademindiq.com","password":"demo123"}' | jq .

echo -e "\n🎉 Setup Complete!"
echo "=============================="
echo "Your TradeMindIQ platform is ready!"
echo "• Frontend: http://$SERVER_IP"
echo "• Demo Login: demo2@trademindiq.com / demo123"
echo ""
echo "The 'Server unavailable' error should now be GONE! ✅"
