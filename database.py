import pyodbc
import pandas as pd
from typing import Optional, Dict, Any, Tuple
import time
from contextlib import contextmanager

class DatabaseManager:
    def __init__(self):
        self.server = 'localhost,1433'
        self.database = 'campus_marketplace'
        self.username = 'SA'
        self.password = 'IAMRICH2025#@2001'
        self.driver = '{ODBC Driver 18 for SQL Server}'
        self.max_retries = 3
        self.retry_delay = 1
        
    def get_connection(self):
        """Create database connection with retry logic"""
        for attempt in range(self.max_retries):
            try:
                connection_string = (
                    f'DRIVER={self.driver};'
                    f'SERVER={self.server};'
                    f'DATABASE={self.database};'
                    f'UID={self.username};'
                    f'PWD={self.password};'
                    f'TrustServerCertificate=yes;'
                )
                return pyodbc.connect(connection_string)
            except Exception as e:
                if attempt < self.max_retries - 1:
                    time.sleep(self.retry_delay)
                else:
                    raise e
    
    @contextmanager
    def get_cursor(self):
        """Context manager for database cursor"""
        conn = self.get_connection()
        cursor = conn.cursor()
        try:
            yield conn, cursor
        finally:
            cursor.close()
            conn.close()
    
    def execute_query(self, query: str, params: tuple = None) -> bool:
        """Execute INSERT, UPDATE, DELETE queries with transaction support"""
        try:
            with self.get_cursor() as (conn, cursor):
                if params:
                    cursor.execute(query, params)
                else:
                    cursor.execute(query)
                conn.commit()
                return True
        except Exception as e:
            print(f"Error executing query: {e}")
            return False
    
    def fetch_data(self, query: str, params: tuple = None) -> pd.DataFrame:
        """Fetch data and return as DataFrame"""
        try:
            conn = self.get_connection()
            if params:
                df = pd.read_sql(query, conn, params=params)
            else:
                df = pd.read_sql(query, conn)
            conn.close()
            return df
        except Exception as e:
            print(f"Error fetching data: {e}")
            return pd.DataFrame()
    
    # ==================== AUTHENTICATION ====================
    
    def authenticate_user(self, email: str, password: str) -> Optional[Dict]:
        """Authenticate user with email and password (simple string match for now)"""
        try:
            query = """
            SELECT u.UserID, u.User_Name, u.Email_ID, u.Phone_number,
                   u.Verification_Status, u.Agg_Seller_Rating, c.Campus_Name
            FROM [User] u
            JOIN Campus c ON u.CampusID = c.CampusID
            WHERE u.Email_ID = ?
            """
            user_df = self.fetch_data(query, (email,))
            
            if not user_df.empty:
                # For now, simple password check (in production, use encrypted comparison)
                # Since we don't have passwords in sample data, we'll accept any password
                # In real implementation, decrypt and compare
                user = user_df.iloc[0]
                return {
                    'id': int(user['UserID']),
                    'name': str(user['User_Name']),
                    'email': str(user['Email_ID']),
                    'phone': str(user['Phone_number']),
                    'rating': float(user['Agg_Seller_Rating']),
                    'verification': str(user['Verification_Status']),
                    'campus': str(user['Campus_Name'])
                }
            return None
        except Exception as e:
            print(f"Authentication error: {e}")
            return None
    
    # ==================== USER OPERATIONS ====================
    
    def get_all_users(self) -> pd.DataFrame:
        query = """
        SELECT u.UserID, u.User_Name, u.Email_ID, u.Phone_number, 
               u.Verification_Status, u.Agg_Seller_Rating, c.Campus_Name
        FROM [User] u
        JOIN Campus c ON u.CampusID = c.CampusID
        ORDER BY u.UserID
        """
        return self.fetch_data(query)
    
    # ==================== PRODUCT OPERATIONS ====================
    
    def get_all_products(self) -> pd.DataFrame:
        query = """
        SELECT p.Product_ID, p.Product_Name, p.Description, p.Unit_price, 
               p.Quantity, p.Product_Status, c.Category_Name, u.User_Name as Seller,
               p.Standard_price, p.Created_date
        FROM Product p
        JOIN Category c ON p.Category_ID = c.Category_ID
        JOIN [User] u ON p.Seller_ID = u.UserID
        ORDER BY p.Product_ID DESC
        """
        return self.fetch_data(query)
    
    def add_product(self, category_id: int, seller_id: int, name: str, 
                    description: str, standard_price: float, unit_price: float,
                    quantity: int, status: str = 'Active') -> bool:
        query = """
        INSERT INTO Product (Category_ID, Seller_ID, Product_Name, Description, 
                           Standard_price, Unit_price, Quantity, Product_Status, Created_date)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, GETDATE())
        """
        return self.execute_query(query, (
            int(category_id), int(seller_id), str(name), str(description),
            float(standard_price), float(unit_price), int(quantity), str(status)
        ))
    
    # ==================== ORDER OPERATIONS WITH STORED PROCEDURES ====================
    
    def create_order_with_collection(self, product_id: int, buyer_id: int, 
                                    quantity: int, pickup_point_id: int,
                                    scheduled_date=None, scheduled_time=None) -> Tuple[bool, int, str]:
        """
        Call stored procedure: usp_CreateOrderWithCollection
        Returns: (success, order_id, message)
        """
        try:
            with self.get_cursor() as (conn, cursor):
                # Output parameters
                order_id = cursor.var(int)
                result_code = cursor.var(int)
                result_message = cursor.var(str)
                
                # Call stored procedure
                cursor.execute("""
                    DECLARE @NewOrderID INT, @ResultCode INT, @ResultMessage NVARCHAR(400);
                    
                    EXEC dbo.usp_CreateOrderWithCollection
                        @ProductID = ?,
                        @BuyerID = ?,
                        @Quantity = ?,
                        @PickupPointID = ?,
                        @ScheduledDate = ?,
                        @ScheduledTime = ?,
                        @NewOrderID = @NewOrderID OUTPUT,
                        @ResultCode = @ResultCode OUTPUT,
                        @ResultMessage = @ResultMessage OUTPUT;
                    
                    SELECT @NewOrderID AS OrderID, @ResultCode AS ResultCode, @ResultMessage AS ResultMessage;
                """, (product_id, buyer_id, quantity, pickup_point_id, scheduled_date, scheduled_time))
                
                result = cursor.fetchone()
                conn.commit()
                
                if result:
                    new_order_id = result[0]
                    res_code = result[1]
                    res_message = result[2]
                    
                    return (res_code == 0, new_order_id if new_order_id else 0, res_message)
                
                return (False, 0, "No result returned from procedure")
                
        except Exception as e:
            print(f"Error creating order: {e}")
            return (False, 0, f"Error: {str(e)}")
    
    def initiate_escrow_verification(self, order_id: int) -> Tuple[bool, str, str]:
        """
        Call stored procedure: usp_InitiateEscrowVerification
        Returns: (success, verification_code, message)
        """
        try:
            with self.get_cursor() as (conn, cursor):
                cursor.execute("""
                    DECLARE @VerificationCode CHAR(6), @ResultCode INT, @ResultMessage NVARCHAR(400);
                    
                    EXEC dbo.usp_InitiateEscrowVerification
                        @OrderID = ?,
                        @VerificationCode = @VerificationCode OUTPUT,
                        @ResultCode = @ResultCode OUTPUT,
                        @ResultMessage = @ResultMessage OUTPUT;
                    
                    SELECT @VerificationCode AS VerificationCode, @ResultCode AS ResultCode, @ResultMessage AS ResultMessage;
                """, (order_id,))
                
                result = cursor.fetchone()
                conn.commit()
                
                if result:
                    verification_code = result[0]
                    res_code = result[1]
                    res_message = result[2]
                    
                    return (res_code == 0, verification_code if verification_code else "", res_message)
                
                return (False, "", "No result returned from procedure")
                
        except Exception as e:
            print(f"Error initiating escrow: {e}")
            return (False, "", f"Error: {str(e)}")
    
    def verify_escrow_code(self, order_id: int, seller_id: int, entered_code: str) -> Tuple[bool, str]:
        """
        Call stored procedure: usp_VerifyEscrowCodeAndCompletePayment
        Returns: (success, message)
        """
        try:
            with self.get_cursor() as (conn, cursor):
                cursor.execute("""
                    DECLARE @IsVerified BIT, @ResultCode INT, @ResultMessage NVARCHAR(400);
                    
                    EXEC dbo.usp_VerifyEscrowCodeAndCompletePayment
                        @OrderID = ?,
                        @SellerID = ?,
                        @EnteredCode = ?,
                        @IsVerified = @IsVerified OUTPUT,
                        @ResultCode = @ResultCode OUTPUT,
                        @ResultMessage = @ResultMessage OUTPUT;
                    
                    SELECT @IsVerified AS IsVerified, @ResultCode AS ResultCode, @ResultMessage AS ResultMessage;
                """, (order_id, seller_id, entered_code))
                
                result = cursor.fetchone()
                conn.commit()
                
                if result:
                    is_verified = result[0]
                    res_message = result[2]
                    return (bool(is_verified), res_message)
                
                return (False, "No result returned from procedure")
                
        except Exception as e:
            print(f"Error verifying code: {e}")
            return (False, f"Error: {str(e)}")
    
    def get_verification_code(self, order_id: int) -> Optional[str]:
        """Retrieve verification code for an order"""
        try:
            query = "SELECT Verification_Code FROM Escrow_Verification WHERE OrderID = ?"
            result = self.fetch_data(query, (order_id,))
            if not result.empty:
                return result.iloc[0]['Verification_Code']
            return None
        except Exception as e:
            print(f"Error getting verification code: {e}")
            return None
    
    def get_all_orders(self) -> pd.DataFrame:
        query = """
        SELECT o.OrderID, p.Product_Name, 
               seller.User_Name as Seller, buyer.User_Name as Buyer,
               o.Quantity, o.Status, o.Order_Date, o.Product_ID, o.Seller_ID, o.Buyer_ID
        FROM [Order] o
        JOIN Product p ON o.Product_ID = p.Product_ID
        JOIN [User] seller ON o.Seller_ID = seller.UserID
        JOIN [User] buyer ON o.Buyer_ID = buyer.UserID
        ORDER BY o.OrderID DESC
        """
        return self.fetch_data(query)
    
    def update_order_status(self, order_id: int, status: str) -> bool:
        query = "UPDATE [Order] SET Status = ? WHERE OrderID = ?"
        return self.execute_query(query, (str(status), int(order_id)))
    
    # ==================== ESCROW OPERATIONS ====================
    
    def add_escrow(self, order_id: int, amount: float, status: str = 'Held') -> bool:
        query = """
        INSERT INTO Escrow (OrderID, Amount, Status, Created_Date)
        VALUES (?, ?, ?, GETDATE())
        """
        return self.execute_query(query, (int(order_id), float(amount), str(status)))
    
    def update_escrow_status(self, escrow_id: int, status: str) -> bool:
        if status == 'Released' or status == 'Refunded':
            query = """
            UPDATE Escrow 
            SET Status = ?, Release_Date = GETDATE()
            WHERE EscrowID = ?
            """
        else:
            query = "UPDATE Escrow SET Status = ? WHERE EscrowID = ?"
        return self.execute_query(query, (str(status), int(escrow_id)))
    
    # ==================== DISPUTE OPERATIONS ====================
    
    def get_all_disputes(self) -> pd.DataFrame:
        query = """
        SELECT d.Dispute_ID, d.EscrowID, u.User_Name as Filed_By, d.FiledByUserID,
               d.Description, d.Status, d.Open_Date, d.Resolved_Date, d.Resolution_Details,
               o.OrderID, e.Amount
        FROM Dispute d
        JOIN [User] u ON d.FiledByUserID = u.UserID
        JOIN Escrow e ON d.EscrowID = e.EscrowID
        JOIN [Order] o ON e.OrderID = o.OrderID
        ORDER BY d.Dispute_ID DESC
        """
        return self.fetch_data(query)
    
    def add_dispute(self, escrow_id: int, filed_by: int, description: str,
                    status: str = 'Open') -> bool:
        query = """
        INSERT INTO Dispute (EscrowID, FiledByUserID, Description, 
                            Open_Date, Status)
        VALUES (?, ?, ?, GETDATE(), ?)
        """
        return self.execute_query(query, (
            int(escrow_id), int(filed_by), str(description), str(status)
        ))
    
    def update_dispute(self, dispute_id: int, status: str, 
                      resolution_details: str = None) -> bool:
        if status in ['Resolved', 'Closed'] and resolution_details:
            query = """
            UPDATE Dispute 
            SET Status = ?, Resolution_Details = ?, Resolved_Date = GETDATE()
            WHERE Dispute_ID = ?
            """
            return self.execute_query(query, (
                str(status), str(resolution_details), int(dispute_id)
            ))
        else:
            query = "UPDATE Dispute SET Status = ? WHERE Dispute_ID = ?"
            return self.execute_query(query, (str(status), int(dispute_id)))
    
    # ==================== RATING OPERATIONS ====================
    
    def add_rating(self, order_id: int, rater_id: int, rated_id: int,
                   rating_value: float) -> bool:
        query = """
        INSERT INTO Rating (Order_ID, Rater_UserID, Rated_UserID, 
                           Rating_Value, Rating_Date)
        VALUES (?, ?, ?, ?, GETDATE())
        """
        return self.execute_query(query, (
            int(order_id), int(rater_id), int(rated_id), float(rating_value)
        ))
    
    # ==================== HELPER METHODS ====================
    
    def get_categories(self) -> pd.DataFrame:
        return self.fetch_data("SELECT Category_ID, Category_Name FROM Category ORDER BY Category_Name")
    
    def get_pickup_points(self, campus_id: int = 1) -> pd.DataFrame:
        query = """
        SELECT PickupPointID, Location_Name, Street 
        FROM Pickup_Point 
        WHERE CampusID = ?
        ORDER BY Location_Name
        """
        return self.fetch_data(query, (campus_id,))
    
    def get_dashboard_stats(self) -> Dict[str, Any]:
        """Get dashboard statistics"""
        try:
            with self.get_cursor() as (conn, cursor):
                stats = {}
                
                cursor.execute("SELECT COUNT(*) FROM [User]")
                stats['total_users'] = cursor.fetchone()[0]
                
                cursor.execute("SELECT COUNT(*) FROM Product WHERE Product_Status = 'Active'")
                stats['active_products'] = cursor.fetchone()[0]
                
                cursor.execute("SELECT COUNT(*) FROM [Order]")
                stats['total_orders'] = cursor.fetchone()[0]
                
                cursor.execute("SELECT COUNT(*) FROM Dispute WHERE Status IN ('Open', 'In Progress')")
                stats['pending_disputes'] = cursor.fetchone()[0]
                
                cursor.execute("SELECT ISNULL(SUM(Amount), 0) FROM Escrow WHERE Status = 'Held'")
                stats['held_escrow'] = cursor.fetchone()[0]
                
                return stats
        except Exception as e:
            print(f"Error fetching dashboard stats: {e}")
            return {}
    
    def check_product_availability(self, product_id: int, quantity: int) -> Tuple[bool, int, str]:
        """
        Check if product has enough quantity available
        Returns: (available, current_quantity, status)
        """
        try:
            query = "SELECT Quantity, Product_Status FROM Product WHERE Product_ID = ?"
            result = self.fetch_data(query, (product_id,))
            
            if result.empty:
                return (False, 0, "Product not found")
            
            current_qty = int(result.iloc[0]['Quantity'])
            status = result.iloc[0]['Product_Status']
            
            if status != 'Active':
                return (False, current_qty, f"Product is {status}")
            
            if current_qty < quantity:
                return (False, current_qty, f"Only {current_qty} available")
            
            return (True, current_qty, "Available")
            
        except Exception as e:
            return (False, 0, f"Error: {str(e)}")