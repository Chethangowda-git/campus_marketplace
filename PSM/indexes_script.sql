-- 03_indexes.sql
-- =====================================================
-- All nonclustered / unique indexes for campus_marketplace
-- Note: In SQL Server, CREATE INDEX (without CLUSTERED)
--       creates a NONCLUSTERED index by default.
-- =====================================================

USE campus_marketplace;
GO

/* ============================
   User table indexes
   ============================ */
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_User_Campus'
      AND object_id = OBJECT_ID('dbo.[User]')
)
    DROP INDEX IX_User_Campus ON dbo.[User];
GO

CREATE INDEX IX_User_Campus 
ON dbo.[User](CampusID);
GO

/* ============================
   Pickup_Point table indexes
   ============================ */
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Pickup_Point_Zipcode'
      AND object_id = OBJECT_ID('dbo.Pickup_Point')
)
    DROP INDEX IX_Pickup_Point_Zipcode ON dbo.Pickup_Point;
GO

CREATE INDEX IX_Pickup_Point_Zipcode 
ON dbo.Pickup_Point(Zipcode);
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Pickup_Point_Campus'
      AND object_id = OBJECT_ID('dbo.Pickup_Point')
)
    DROP INDEX IX_Pickup_Point_Campus ON dbo.Pickup_Point;
GO

CREATE INDEX IX_Pickup_Point_Campus  
ON dbo.Pickup_Point(CampusID);
GO

/* ============================
   Product table indexes
   ============================ */
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Product_Category'
      AND object_id = OBJECT_ID('dbo.Product')
)
    DROP INDEX IX_Product_Category ON dbo.Product;
GO

CREATE INDEX IX_Product_Category 
ON dbo.Product(Category_ID);
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Product_Seller'
      AND object_id = OBJECT_ID('dbo.Product')
)
    DROP INDEX IX_Product_Seller ON dbo.Product;
GO

CREATE INDEX IX_Product_Seller   
ON dbo.Product(Seller_ID);
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Product_Status'
      AND object_id = OBJECT_ID('dbo.Product')
)
    DROP INDEX IX_Product_Status ON dbo.Product;
GO

CREATE INDEX IX_Product_Status   
ON dbo.Product(Product_Status);
GO

/* ============================
   Product_Media table indexes
   ============================ */
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Product_Media_Product'
      AND object_id = OBJECT_ID('dbo.Product_Media')
)
    DROP INDEX IX_Product_Media_Product ON dbo.Product_Media;
GO

CREATE INDEX IX_Product_Media_Product 
ON dbo.Product_Media(Product_ID);
GO

/* ============================
   Order table indexes
   ============================ */
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Order_Product'
      AND object_id = OBJECT_ID('dbo.[Order]')
)
    DROP INDEX IX_Order_Product ON dbo.[Order];
GO

CREATE INDEX IX_Order_Product 
ON dbo.[Order](Product_ID);
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Order_Seller'
      AND object_id = OBJECT_ID('dbo.[Order]')
)
    DROP INDEX IX_Order_Seller ON dbo.[Order];
GO

CREATE INDEX IX_Order_Seller  
ON dbo.[Order](Seller_ID);
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Order_Buyer'
      AND object_id = OBJECT_ID('dbo.[Order]')
)
    DROP INDEX IX_Order_Buyer ON dbo.[Order];
GO

CREATE INDEX IX_Order_Buyer   
ON dbo.[Order](Buyer_ID);
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Order_Status'
      AND object_id = OBJECT_ID('dbo.[Order]')
)
    DROP INDEX IX_Order_Status ON dbo.[Order];
GO

CREATE INDEX IX_Order_Status  
ON dbo.[Order](Status);
GO

-- Unique indexes for composite FKs (used by Rating)
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'UQ_Order_OrderID_Buyer'
      AND object_id = OBJECT_ID('dbo.[Order]')
)
    DROP INDEX UQ_Order_OrderID_Buyer ON dbo.[Order];
GO

CREATE UNIQUE INDEX UQ_Order_OrderID_Buyer 
ON dbo.[Order](OrderID, Buyer_ID);
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'UQ_Order_OrderID_Seller'
      AND object_id = OBJECT_ID('dbo.[Order]')
)
    DROP INDEX UQ_Order_OrderID_Seller ON dbo.[Order];
GO

CREATE UNIQUE INDEX UQ_Order_OrderID_Seller 
ON dbo.[Order](OrderID, Seller_ID);
GO

/* ============================
   Escrow table indexes
   ============================ */
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Escrow_Order'
      AND object_id = OBJECT_ID('dbo.Escrow')
)
    DROP INDEX IX_Escrow_Order ON dbo.Escrow;
GO

CREATE INDEX IX_Escrow_Order  
ON dbo.Escrow(OrderID);
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Escrow_Status'
      AND object_id = OBJECT_ID('dbo.Escrow')
)
    DROP INDEX IX_Escrow_Status ON dbo.Escrow;
GO

CREATE INDEX IX_Escrow_Status 
ON dbo.Escrow(Status);
GO

/* ============================
   Product_Audit_Logs indexes
   ============================ */
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Product_Audit_User'
      AND object_id = OBJECT_ID('dbo.Product_Audit_Logs')
)
    DROP INDEX IX_Product_Audit_User ON dbo.Product_Audit_Logs;
GO

CREATE INDEX IX_Product_Audit_User      
ON dbo.Product_Audit_Logs(Performed_By_UserID);
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Product_Audit_Product'
      AND object_id = OBJECT_ID('dbo.Product_Audit_Logs')
)
    DROP INDEX IX_Product_Audit_Product ON dbo.Product_Audit_Logs;
GO

CREATE INDEX IX_Product_Audit_Product   
ON dbo.Product_Audit_Logs(Product_ID);
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Product_Audit_Timestamp'
      AND object_id = OBJECT_ID('dbo.Product_Audit_Logs')
)
    DROP INDEX IX_Product_Audit_Timestamp ON dbo.Product_Audit_Logs;
GO

CREATE INDEX IX_Product_Audit_Timestamp 
ON dbo.Product_Audit_Logs([Timestamp]);
GO

/* ============================
   Escrow_Audit_Logs indexes
   ============================ */
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Escrow_Audit_User'
      AND object_id = OBJECT_ID('dbo.Escrow_Audit_Logs')
)
    DROP INDEX IX_Escrow_Audit_User ON dbo.Escrow_Audit_Logs;
GO

CREATE INDEX IX_Escrow_Audit_User      
ON dbo.Escrow_Audit_Logs(Performed_By_UserID);
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Escrow_Audit_Escrow'
      AND object_id = OBJECT_ID('dbo.Escrow_Audit_Logs')
)
    DROP INDEX IX_Escrow_Audit_Escrow ON dbo.Escrow_Audit_Logs;
GO

CREATE INDEX IX_Escrow_Audit_Escrow    
ON dbo.Escrow_Audit_Logs(Escrow_ID);
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Escrow_Audit_Timestamp'
      AND object_id = OBJECT_ID('dbo.Escrow_Audit_Logs')
)
    DROP INDEX IX_Escrow_Audit_Timestamp ON dbo.Escrow_Audit_Logs;
GO

CREATE INDEX IX_Escrow_Audit_Timestamp 
ON dbo.Escrow_Audit_Logs([Timestamp]);
GO

/* ============================
   Dispute table indexes
   ============================ */
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Dispute_Escrow'
      AND object_id = OBJECT_ID('dbo.Dispute')
)
    DROP INDEX IX_Dispute_Escrow ON dbo.Dispute;
GO

CREATE INDEX IX_Dispute_Escrow  
ON dbo.Dispute(EscrowID);
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Dispute_FiledBy'
      AND object_id = OBJECT_ID('dbo.Dispute')
)
    DROP INDEX IX_Dispute_FiledBy ON dbo.Dispute;
GO

CREATE INDEX IX_Dispute_FiledBy 
ON dbo.Dispute(FiledByUserID);
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Dispute_Status'
      AND object_id = OBJECT_ID('dbo.Dispute')
)
    DROP INDEX IX_Dispute_Status ON dbo.Dispute;
GO

CREATE INDEX IX_Dispute_Status  
ON dbo.Dispute(Status);
GO

/* ============================
   Dispute_Evidence indexes
   ============================ */
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Dispute_Evidence_Dispute'
      AND object_id = OBJECT_ID('dbo.Dispute_Evidence')
)
    DROP INDEX IX_Dispute_Evidence_Dispute ON dbo.Dispute_Evidence;
GO

CREATE INDEX IX_Dispute_Evidence_Dispute 
ON dbo.Dispute_Evidence(Dispute_ID);
GO

/* ============================
   Order_Collection indexes
   ============================ */
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_OrderCollection_Order'
      AND object_id = OBJECT_ID('dbo.Order_Collection')
)
    DROP INDEX IX_OrderCollection_Order ON dbo.Order_Collection;
GO

CREATE INDEX IX_OrderCollection_Order       
ON dbo.Order_Collection(Order_ID);
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_OrderCollection_PickupPoint'
      AND object_id = OBJECT_ID('dbo.Order_Collection')
)
    DROP INDEX IX_OrderCollection_PickupPoint ON dbo.Order_Collection;
GO

CREATE INDEX IX_OrderCollection_PickupPoint 
ON dbo.Order_Collection(Pickup_Point_ID);
GO
