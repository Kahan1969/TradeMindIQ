#!/usr/bin/env python3
"""
TradeMindIQ Database Initialization Script
This script creates a complete database with users and sample data
"""

import sqlite3
import hashlib
import os
import datetime
from pathlib import Path

def hash_password(password: str) -> str:
    """Hash password using MD5 (for demo purposes)"""
    return hashlib.md5(password.encode()).hexdigest()

def init_database(db_path: str = "trademindiq.db"):
    """Initialize the complete TradeMindIQ database"""
    
    print(f"🚀 Initializing TradeMindIQ Database at: {db_path}")
    
    # Remove existing database if it exists
    if os.path.exists(db_path):
        os.remove(db_path)
        print(f"🗑️  Removed existing database: {db_path}")
    
    # Create database connection
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Create users table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            email TEXT UNIQUE NOT NULL,
            hashed_password TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Create trades table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS trades (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            symbol TEXT NOT NULL,
            trade_type TEXT NOT NULL,
            quantity REAL NOT NULL,
            price REAL NOT NULL,
            profit_loss REAL DEFAULT 0,
            status TEXT DEFAULT 'open',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users (id)
        )
    ''')
    
    # Create demo users
    demo_users = [
        ('demo1', 'demo1@trademindiq.com', 'demo123'),
        ('demo2', 'demo2@trademindiq.com', 'demo123'),
        ('admin', 'admin@trademindiq.com', 'admin123'),
        ('test', 'test@trademindiq.com', 'test123')
    ]
    
    user_ids = {}
    for username, email, password in demo_users:
        hashed_password = hash_password(password)
        try:
            cursor.execute('''
                INSERT INTO users (username, email, hashed_password, created_at)
                VALUES (?, ?, ?, ?)
            ''', (username, email, hashed_password, datetime.datetime.now()))
            
            user_id = cursor.lastrowid
            user_ids[username] = user_id
            print(f"✅ Created user: {email} (ID: {user_id})")
        except sqlite3.IntegrityError as e:
            print(f"❌ Error creating user {email}: {e}")
    
    # Create sample trades
    sample_trades = [
        ('demo1', 'AAPL', 'buy', 100, 150.25, 525.50),
        ('demo1', 'TSLA', 'sell', 50, 245.75, -125.25),
        ('demo2', 'GOOGL', 'buy', 25, 2750.00, 1250.75),
        ('demo2', 'MSFT', 'buy', 75, 325.50, 325.25),
        ('admin', 'NVDA', 'buy', 200, 875.25, 2150.50),
        ('admin', 'AMD', 'sell', 150, 125.75, -75.25)
    ]
    
    for username, symbol, trade_type, quantity, price, profit_loss in sample_trades:
        if username in user_ids:
            try:
                cursor.execute('''
                    INSERT INTO trades (user_id, symbol, trade_type, quantity, price, profit_loss, status, created_at)
                    VALUES (?, ?, ?, ?, ?, ?, 'closed', ?)
                ''', (user_ids[username], symbol, trade_type, quantity, price, profit_loss, datetime.datetime.now()))
                print(f"✅ Created trade: {symbol} for {username}")
            except Exception as e:
                print(f"❌ Error creating trade: {e}")
    
    # Commit changes
    conn.commit()
    
    # Verify database
    cursor.execute('SELECT COUNT(*) FROM users')
    user_count = cursor.fetchone()[0]
    
    cursor.execute('SELECT COUNT(*) FROM trades')
    trade_count = cursor.fetchone()[0]
    
    conn.close()
    
    print(f"\n🎉 Database initialized successfully!")
    print(f"📊 Users: {user_count}")
    print(f"📈 Trades: {trade_count}")
    print(f"💾 Database file: {os.path.abspath(db_path)}")
    
    print(f"\n🔑 Demo Login Credentials:")
    for username, email, password in demo_users:
        print(f"  • {email} / {password}")
    
    print(f"\n✅ Ready to deploy! Database: {db_path}")
    
    return True

def main():
    """Main function"""
    # Get database path from command line or use default
    import sys
    db_path = sys.argv[1] if len(sys.argv) > 1 else "trademindiq.db"
    
    try:
        init_database(db_path)
        print("\n🚀 Database initialization complete!")
        return 0
    except Exception as e:
        print(f"\n❌ Database initialization failed: {e}")
        return 1

if __name__ == "__main__":
    exit(main())
