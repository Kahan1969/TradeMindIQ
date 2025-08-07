from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
import sqlite3
import hashlib
import jwt
import datetime
from typing import Optional
import os

app = FastAPI(title="TradeMindIQ API", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Security
security = HTTPBearer()
JWT_SECRET = "your-secret-key-change-in-production"
JWT_ALGORITHM = "HS256"

# Pydantic models
class LoginRequest(BaseModel):
    username: str  # Changed from email to username
    password: str

class UserResponse(BaseModel):
    id: int
    username: str
    email: str

class LoginResponse(BaseModel):
    success: bool
    message: str
    user: UserResponse
    token: str

# Database path
DATABASE_PATH = "/var/www/trademindiq/backend/trademindiq.db"

def get_db_connection():
    """Get database connection"""
    try:
        if not os.path.exists(DATABASE_PATH):
            raise Exception(f"Database file not found at {DATABASE_PATH}")
        
        conn = sqlite3.connect(DATABASE_PATH)
        conn.row_factory = sqlite3.Row
        return conn
    except Exception as e:
        print(f"Database connection error: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Database error: {str(e)}"
        )

def hash_password(password: str) -> str:
    """Hash password using MD5 (for demo purposes)"""
    return hashlib.md5(password.encode()).hexdigest()

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password against hash"""
    return hash_password(plain_password) == hashed_password

def create_access_token(data: dict, expires_delta: Optional[datetime.timedelta] = None):
    """Create JWT access token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.datetime.utcnow() + expires_delta
    else:
        expire = datetime.datetime.utcnow() + datetime.timedelta(hours=24)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, JWT_SECRET, algorithm=JWT_ALGORITHM)
    return encoded_jwt

# Routes
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "ok",
        "service": "TradeMindIQ API",
        "database": "connected" if os.path.exists(DATABASE_PATH) else "not found"
    }

@app.get("/api/health")
async def api_health_check():
    """API health check endpoint"""
    return {
        "status": "ok",
        "service": "TradeMindIQ API",
        "timestamp": datetime.datetime.utcnow().isoformat(),
        "database": "connected" if os.path.exists(DATABASE_PATH) else "not found"
    }

@app.post("/api/auth/login", response_model=LoginResponse)
async def login(login_data: LoginRequest):
    """Login endpoint - now accepts username instead of email"""
    try:
        print(f"Login attempt for username: {login_data.username}")
        
        # Get database connection
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Find user by email (since username contains email format)
        cursor.execute(
            "SELECT id, username, email, hashed_password FROM users WHERE email = ?",
            (login_data.username,)
        )
        user = cursor.fetchone()
        conn.close()
        
        if not user:
            print(f"User not found: {login_data.username}")
            raise HTTPException(
                status_code=401,
                detail="Invalid credentials"
            )
        
        # Verify password
        if not verify_password(login_data.password, user['hashed_password']):
            print(f"Invalid password for user: {login_data.username}")
            raise HTTPException(
                status_code=401,
                detail="Invalid credentials"
            )
        
        # Create access token
        token_data = {
            "user_id": user['id'],
            "username": user['username'],
            "email": user['email'],
            "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=24)
        }
        token = jwt.encode(token_data, JWT_SECRET, algorithm=JWT_ALGORITHM)
        
        print(f"Login successful for user: {login_data.username}")
        
        return LoginResponse(
            success=True,
            message="Login successful",
            user=UserResponse(
                id=user['id'],
                username=user['username'],
                email=user['email']
            ),
            token=token
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Login error: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Database error: {str(e)}"
        )

@app.get("/api/auth/me")
async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Get current user info"""
    try:
        # Decode JWT token
        payload = jwt.decode(credentials.credentials, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        email: str = payload.get("email")
        
        if email is None:
            raise HTTPException(
                status_code=401,
                detail="Invalid authentication credentials"
            )
        
        # Get user from database
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id, username, email FROM users WHERE email = ?",
            (email,)
        )
        user = cursor.fetchone()
        conn.close()
        
        if user is None:
            raise HTTPException(
                status_code=401,
                detail="User not found"
            )
        
        return UserResponse(
            id=user['id'],
            username=user['username'],
            email=user['email']
        )
        
    except jwt.PyJWTError:
        raise HTTPException(
            status_code=401,
            detail="Invalid authentication credentials"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Database error: {str(e)}"
        )

# For development
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
