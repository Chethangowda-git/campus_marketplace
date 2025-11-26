import pyodbc
import pandas as pd
from typing import Optional, List, Dict, Any

class DatabaseManager:
    def __init__(self):
        self.server = 'localhost,1433'
        self.database = 'campus_marketplace'
        self.username = 'SA'
        self.password = 'IAMRICH2025#@2001'  # CHANGE THIS TO YOUR ACTUAL PASSWORD
        self.driver = '{ODBC Driver 18 for SQL Server}'
        
    def get_connection(self):
        """Create database connection"""
        connection_string = (
            f'DRIVER={self.driver};'
            f'SERVER={self.server};'
            f'DATABASE={self.database};'
            f'UID={self.username};'
            f'PWD={self.password};'
            f'TrustServerCertificate=yes;'
        )
        return pyodbc.connect(connection_string)
    
    def execute_query(self, query: str, params: tuple = None) -> bool:
        """Execute INSERT, UPDATE, DELETE queries"""
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            conn.commit()
            cursor.close()
            conn.close()
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
    
    def add_user(self, campus_id: int, name: str, email: str, phone: str, 
                 verification: str = 'Pending') -> bool:
        query = """
        INSERT INTO [User] (CampusID, User_Name, Email_ID, Phone_number, 
                           Verification_Status, Agg_Seller_Rating)
        VALUES (?, ?, ?, ?, ?, 0.00)
        """
        return self.execute_query(query, (
            int(campus_id), 
            str(name), 
            str(email), 
            str(phone), 
            str(verification)
        ))
    
    def update_user(self, user_id: int, name: str, email: str, phone: str, 
                    verification: str) -> bool:
        query = """
        UPDATE [User] 
        SET User_Name = ?, Email_ID = ?, Phone_number = ?, Verification_Status = ?
        WHERE UserID = ?
        """
        return self.execute_query(query, (
            str(name), 
            str(email), 
            str(phone), 
            str(verification), 
            int(user_id)
        ))
    
    def delete_user(self, user_id: int) -> bool:
        query = "DELETE FROM [User] WHERE UserID = ?"
        return self.execute_query(query, (int(user_id),))
    
    # ==================== PRODUCT OPERATIONS ====================
    
    def get_all_products(self) -> pd.DataFrame:
        query = """
        SELECT p.Product_ID, p.Product_Name, p.Description, p.Unit_price, 
               p.Quantity, p.Product_Status, c.Category_Name, u.User_Name as Seller
        FROM Product p
        JOIN Category c ON p.Category_ID = c.Category_ID
        JOIN [User] u ON p.Seller_ID = u.UserID
        ORDER BY p.Product_ID
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
            int(category_id), 
            int(seller_id), 
            str(name), 
            str(description),
            float(standard_price), 
            float(unit_price), 
            int(quantity), 
            str(status)
        ))
    
    def update_product(self, product_id: int, name: str, description: str,
                      unit_price: float, quantity: int, status: str) -> bool:
        query = """
        UPDATE Product 
        SET Product_Name = ?, Description = ?, Unit_price = ?, 
            Quantity = ?, Product_Status = ?
        WHERE Product_ID = ?
        """
        return self.execute_query(query, (
            str(name), 
            str(description), 
            float(unit_price), 
            int(quantity), 
            str(status), 
            int(product_id)
        ))
    
    def delete_product(self, product_id: int) -> bool:
        query = "DELETE FROM Product WHERE Product_ID = ?"
        return self.execute_query(query, (int(product_id),))
    
    # ==================== ORDER OPERATIONS ====================
    
    def get_all_orders(self) -> pd.DataFrame:
        query = """
        SELECT o.OrderID, p.Product_Name, 
               seller.User_Name as Seller, buyer.User_Name as Buyer,
               o.Quantity, o.Status, o.Order_Date
        FROM [Order] o
        JOIN Product p ON o.Product_ID = p.Product_ID
        JOIN [User] seller ON o.Seller_ID = seller.UserID
        JOIN [User] buyer ON o.Buyer_ID = buyer.UserID
        ORDER BY o.OrderID DESC
        """
        return self.fetch_data(query)
    
    def add_order(self, product_id: int, seller_id: int, buyer_id: int,
                  quantity: int, status: str = 'Confirmed') -> bool:
        query = """
        INSERT INTO [Order] (Product_ID, Seller_ID, Buyer_ID, Order_Date, 
                            Quantity, Status)
        VALUES (?, ?, ?, GETDATE(), ?, ?)
        """
        return self.execute_query(query, (
            int(product_id), 
            int(seller_id), 
            int(buyer_id), 
            int(quantity), 
            str(status)
        ))
    
    def update_order_status(self, order_id: int, status: str) -> bool:
        query = "UPDATE [Order] SET Status = ? WHERE OrderID = ?"
        return self.execute_query(query, (str(status), int(order_id)))
    
    def delete_order(self, order_id: int) -> bool:
        query = "DELETE FROM [Order] WHERE OrderID = ?"
        return self.execute_query(query, (int(order_id),))
    
    # ==================== ESCROW OPERATIONS ====================
    
    def get_all_escrows(self) -> pd.DataFrame:
        query = """
        SELECT e.EscrowID, e.OrderID, e.Amount, e.Status, 
               e.Created_Date, e.Release_Date
        FROM Escrow e
        ORDER BY e.EscrowID DESC
        """
        return self.fetch_data(query)
    
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
    
    def delete_escrow(self, escrow_id: int) -> bool:
        query = "DELETE FROM Escrow WHERE EscrowID = ?"
        return self.execute_query(query, (int(escrow_id),))
    
    # ==================== DISPUTE OPERATIONS ====================
    
    def get_all_disputes(self) -> pd.DataFrame:
        query = """
        SELECT d.Dispute_ID, d.EscrowID, u.User_Name as Filed_By,
               d.Description, d.Status, d.Open_Date, d.Resolved_Date
        FROM Dispute d
        JOIN [User] u ON d.FiledByUserID = u.UserID
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
            int(escrow_id), 
            int(filed_by), 
            str(description), 
            str(status)
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
                str(status), 
                str(resolution_details), 
                int(dispute_id)
            ))
        else:
            query = "UPDATE Dispute SET Status = ? WHERE Dispute_ID = ?"
            return self.execute_query(query, (str(status), int(dispute_id)))
    
    def delete_dispute(self, dispute_id: int) -> bool:
        query = "DELETE FROM Dispute WHERE Dispute_ID = ?"
        return self.execute_query(query, (int(dispute_id),))
    
    # ==================== RATING OPERATIONS ====================
    
    def get_all_ratings(self) -> pd.DataFrame:
        query = """
        SELECT r.RatingID, r.Order_ID, 
               rater.User_Name as Rater, rated.User_Name as Rated_User,
               r.Rating_Value, r.Rating_Date
        FROM Rating r
        JOIN [User] rater ON r.Rater_UserID = rater.UserID
        JOIN [User] rated ON r.Rated_UserID = rated.UserID
        ORDER BY r.RatingID DESC
        """
        return self.fetch_data(query)
    
    def add_rating(self, order_id: int, rater_id: int, rated_id: int,
                   rating_value: float) -> bool:
        query = """
        INSERT INTO Rating (Order_ID, Rater_UserID, Rated_UserID, 
                           Rating_Value, Rating_Date)
        VALUES (?, ?, ?, ?, GETDATE())
        """
        return self.execute_query(query, (
            int(order_id), 
            int(rater_id), 
            int(rated_id), 
            float(rating_value)
        ))
    
    def delete_rating(self, rating_id: int) -> bool:
        query = "DELETE FROM Rating WHERE RatingID = ?"
        return self.execute_query(query, (int(rating_id),))
    
    # ==================== HELPER METHODS ====================
    
    def get_categories(self) -> pd.DataFrame:
        return self.fetch_data("SELECT Category_ID, Category_Name FROM Category ORDER BY Category_Name")
    
    def get_campuses(self) -> pd.DataFrame:
        return self.fetch_data("SELECT CampusID, Campus_Name FROM Campus")
    
    def get_verified_users(self) -> pd.DataFrame:
        return self.fetch_data("SELECT UserID, User_Name FROM [User] WHERE Verification_Status = 'Verified' ORDER BY User_Name")
    
    def get_all_users_for_dropdown(self) -> pd.DataFrame:
        return self.fetch_data("SELECT UserID, User_Name FROM [User] ORDER BY User_Name")
    
    def get_active_products(self) -> pd.DataFrame:
        return self.fetch_data("SELECT Product_ID, Product_Name FROM Product WHERE Product_Status = 'Active' ORDER BY Product_Name")
    
    def get_dashboard_stats(self) -> Dict[str, Any]:
        """Get dashboard statistics"""
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            
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
            
            cursor.close()
            conn.close()
            
            return stats
        except Exception as e:
            print(f"Error fetching dashboard stats: {e}")
            return {}