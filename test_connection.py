from database import DatabaseManager

try:
    db = DatabaseManager()
    conn = db.get_connection()
    print("✅ Connection successful!")
    conn.close()
    
    users = db.get_all_users()
    print(f"✅ Found {len(users)} users in database")
    print("\nUsers:")
    print(users[['UserID', 'User_Name', 'Email_ID']].head())
except Exception as e:
    print(f"❌ Connection failed: {e}")
    print("\nTroubleshooting:")
    print("1. Make sure Docker container is running: docker ps")
    print("2. Check SA password in database.py")
