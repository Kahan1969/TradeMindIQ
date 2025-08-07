#!/usr/bin/env python3
"""
TradeMindIQ Database Initialization Script
Run this once to set up the database with demo users
"""

import sqlite3
import os

def init_database():
    # Database file path
    db_path = "trademindiq.db"
    
    print("🚀 Initializing TradeMindIQ Database...")
    
    # Create/connect to database
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Create users table
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        hashed_password TEXT NOT NULL,
        first_name TEXT,
        last_name TEXT,
        role TEXT DEFAULT 'trader',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    ''')
    
    # Create trades table
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS trades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        symbol TEXT NOT NULL,
        side TEXT NOT NULL,
        quantity REAL NOT NULL,
        price REAL NOT NULL,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id)
    )
    ''')
    
    # Demo users data
    demo_users = [
        {
            'username': 'demo1',
            'email': 'demo1@trademindiq.com',
            'password': 'demo123',
            'first_name': 'Demo',
            'last_name': 'User1',
            'role': 'trader'
        },
        {
            'username': 'demo2',
            'email': 'demo2@trademindiq.com', 
            'password': 'demo123',
            'first_name': 'Demo',
            'last_name': 'User2',
            'role': 'trader'
        },
        {
            'username': 'admin',
            'email': 'admin@trademindiq.com',
            'password': 'admin123',
            'first_name': 'Admin',
            'last_name': 'User',
            'role': 'admin'
        }
    ]
    
    # Insert demo users
    for user in demo_users:
        try:
            cursor.execute('''
                INSERT OR REPLACE INTO users 
                (username, email, hashed_password, first_name, last_name, role)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (
                user['username'],
                user['email'], 
                user['password'],  # Using plain text for demo
                user['first_name'],
                user['last_name'],
                user['role']
            ))
            print(f"✅ Created user: {user['email']}")
        except Exception as e:
            print(f"❌ Error creating user {user['email']}: {e}")
    
    # Insert some demo trades
    demo_trades = [
        {'user_id': 1, 'symbol': 'AAPL', 'side': 'BUY', 'quantity': 100, 'price': 175.25},
        {'user_id': 1, 'symbol': 'GOOGL', 'side': 'BUY', 'quantity': 50, 'price': 2850.00},
        {'user_id': 2, 'symbol': 'TSLA', 'side': 'BUY', 'quantity': 75, 'price': 245.80},
        {'user_id': 2, 'symbol': 'MSFT', 'side': 'SELL', 'quantity': 200, 'price': 378.90},
    ]
    
    for trade in demo_trades:
        cursor.execute('''
            INSERT INTO trades (user_id, symbol, side, quantity, price)
            VALUES (?, ?, ?, ?, ?)
        ''', (trade['user_id'], trade['symbol'], trade['side'], trade['quantity'], trade['price']))
    
    print(f"✅ Created {len(demo_trades)} demo trades")
    
    # Commit changes
    conn.commit()
    
    # Verify setup
    cursor.execute("SELECT COUNT(*) FROM users")
    user_count = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM trades") 
    trade_count = cursor.fetchone()[0]
    
    print(f"\n🎉 Database initialized successfully!")
    print(f"📊 Users: {user_count}")
    print(f"📈 Trades: {trade_count}")
    print(f"💾 Database file: {os.path.abspath(db_path)}")
    
    print(f"\n🔑 Demo Login Credentials:")
    print(f"  • demo1@trademindiq.com / demo123")
    print(f"  • demo2@trademindiq.com / demo123") 
    print(f"  • admin@trademindiq.com / admin123")
    
    conn.close()
    return db_path

if __name__ == "__main__":
    db_path = init_database()
    print(f"\n✅ Ready to deploy! Database: {db_path}")
