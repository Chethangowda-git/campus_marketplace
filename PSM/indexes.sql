-- 03_indexes.sql
-- =====================================================
-- All nonclustered / unique indexes for campus_marketplace
-- Note: In SQL Server, CREATE INDEX (without CLUSTERED)
--       creates a NONCLUSTERED index by default.
-- =====================================================

USE campus_marketplace;
GO

-- ============================
-- User table indexes
-- ============================
CREATE INDEX IX_User_Campus 
ON dbo.[User](CampusID);
GO

-- ============================
-- Pickup_Point table indexes
-- ============================
CREATE INDEX IX_Pickup_Point_Zipcode 
ON dbo.Pickup_Point(Zipcode);

CREATE INDEX IX_Pickup_Point_Campus  
ON dbo.Pickup_Point(CampusID);
GO

-- ============================
-- Product table indexes
-- ============================
CREATE INDEX IX_Product_Category 
ON dbo.Product(Category_ID);

CREATE INDEX IX_Product_Seller   
ON dbo.Product(Seller_ID);

CREATE INDEX IX_Product_Status   
ON dbo.Product(Product_Status);
GO

-- ============================
-- Product_Media table indexes
-- ============================
CREATE INDEX IX_Product_Media_Product 
ON dbo.Product_Media(Product_ID);
GO

-- ============================
-- Order table indexes
-- ============================
CREATE INDEX IX_Order_Product 
ON dbo.[Order](Product_ID);

CREATE INDEX IX_Order_Seller  
ON dbo.[Order](Seller_ID);

CREATE INDEX IX_Order_Buyer   
ON dbo.[Order](Buyer_ID);

CREATE INDEX IX_Order_Status  
ON dbo.[Order](Status);
GO

-- Unique indexes for composite FKs (used by Rating)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Order_OrderID_Buyer')
    CREATE UNIQUE INDEX UQ_Order_OrderID_Buyer 
    ON dbo.[Order](OrderID, Buyer_ID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Order_OrderID_Seller')
    CREATE UNIQUE INDEX UQ_Order_OrderID_Seller 
    ON dbo.[Order](OrderID, Seller_ID);
GO

-- ============================
-- Escrow table indexes
-- ============================
CREATE INDEX IX_Escrow_Order  
ON dbo.Escrow(OrderID);

CREATE INDEX IX_Escrow_Status 
ON dbo.Escrow(Status);
GO

-- ============================
-- Product_Audit_Logs indexes
-- ============================
CREATE INDEX IX_Product_Audit_User      
ON dbo.Product_Audit_Logs(Performed_By_UserID);

CREATE INDEX IX_Product_Audit_Product   
ON dbo.Product_Audit_Logs(Product_ID);

CREATE INDEX IX_Product_Audit_Timestamp 
ON dbo.Product_Audit_Logs([Timestamp]);
GO

-- ============================
-- Escrow_Audit_Logs indexes
-- ============================
CREATE INDEX IX_Escrow_Audit_User      
ON dbo.Escrow_Audit_Logs(Performed_By_UserID);

CREATE INDEX IX_Escrow_Audit_Escrow    
ON dbo.Escrow_Audit_Logs(Escrow_ID);

CREATE INDEX IX_Escrow_Audit_Timestamp 
ON dbo.Escrow_Audit_Logs([Timestamp]);
GO

-- ============================
-- Dispute table indexes
-- ============================
CREATE INDEX IX_Dispute_Escrow  
ON dbo.Dispute(EscrowID);

CREATE INDEX IX_Dispute_FiledBy 
ON dbo.Dispute(FiledByUserID);

CREATE INDEX IX_Dispute_Status  
ON dbo.Dispute(Status);
GO

-- ============================
-- Dispute_Evidence indexes
-- ============================
CREATE INDEX IX_Dispute_Evidence_Dispute 
ON dbo.Dispute_Evidence(Dispute_ID);
GO

-- ============================
-- Order_Collection indexes
-- ============================
CREATE INDEX IX_OrderCollection_Order       
ON dbo.Order_Collection(Order_ID);

CREATE INDEX IX_OrderCollection_PickupPoint 
ON dbo.Order_Collection(Pickup_Point_ID);
GO