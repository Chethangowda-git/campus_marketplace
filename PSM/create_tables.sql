-- =====================================================
--------- Database Schema Creation Script ---------------
-- =====================================================

-- Writing this to make sure that everytime it uses master and then our database get executed
USE master;
GO

-- Drop database if exists and create fresh
DROP DATABASE IF EXISTS campus_marketplace;
GO
CREATE DATABASE campus_marketplace;
GO
USE campus_marketplace;
GO

--=====================================================================
-----Drop all tables if they exist (in reverse dependency order)-------
--=====================================================================
DROP TABLE IF EXISTS dbo.Order_Collection;
DROP TABLE IF EXISTS dbo.Dispute_Evidence;
DROP TABLE IF EXISTS dbo.Dispute;
DROP TABLE IF EXISTS dbo.Escrow_Audit_Logs;
DROP TABLE IF EXISTS dbo.Product_Audit_Logs;
DROP TABLE IF EXISTS dbo.Rating;
DROP TABLE IF EXISTS dbo.Escrow_Verification;
DROP TABLE IF EXISTS dbo.Escrow;
DROP TABLE IF EXISTS dbo.[Order];
DROP TABLE IF EXISTS dbo.Product_Media;
DROP TABLE IF EXISTS dbo.Product;
DROP TABLE IF EXISTS dbo.Pickup_Point;
DROP TABLE IF EXISTS dbo.[User];
DROP TABLE IF EXISTS dbo.User_Lookup;
DROP TABLE IF EXISTS dbo.Campus;
DROP TABLE IF EXISTS dbo.Zipcode;
DROP TABLE IF EXISTS dbo.Category;

-- =====================================================
-----------------Table: Category----------------------
-- =====================================================
CREATE TABLE dbo.Category (
    Category_ID   INT IDENTITY(1,1) PRIMARY KEY,
    Category_Name NVARCHAR(100) NOT NULL UNIQUE
);
GO

-- =====================================================
-------------------Table: Zipcode----------------------
-- =====================================================
CREATE TABLE dbo.Zipcode (
    Zipcode VARCHAR(10)  PRIMARY KEY,  -- supports ZIP+4
    City    NVARCHAR(50) NOT NULL,
    [State] NVARCHAR(50) NOT NULL
);
GO

-- =====================================================
-------------------Table: Campus------------------------
-- =====================================================
CREATE TABLE dbo.Campus (
    CampusID     INT PRIMARY KEY,  -- or INT IDENTITY(1,1)
    Campus_Name  NVARCHAR(100) NOT NULL,
    Street       NVARCHAR(255) NOT NULL,
    Zipcode      VARCHAR(10) NOT NULL,
    FOREIGN KEY (Zipcode) REFERENCES dbo.Zipcode(Zipcode)
        ON DELETE NO ACTION
        ON UPDATE CASCADE  
);
GO

-- ======================================================================================
--------------Table: User (quoted to avoid MySQL reserved word conflict)-----------------
-- ======================================================================================
CREATE TABLE dbo.[User] (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    CampusID INT NOT NULL,
    User_Name NVARCHAR(100) NOT NULL,
    Verification_Status NVARCHAR(20) NOT NULL,
    Phone_number NVARCHAR(20) NOT NULL,
    [Password] NVARCHAR(255) NULL,             -- plain password column (for demo; real systems should hash)
    Agg_Seller_Rating DECIMAL(3,2) DEFAULT (0.00),
    Email_ID NVARCHAR(255) NOT NULL UNIQUE,
    FOREIGN KEY (CampusID) REFERENCES dbo.Campus(CampusID)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO

CREATE INDEX IX_User_Campus ON dbo.[User](CampusID);
GO

-- =====================================================
-- LOOKUP TABLE: User_Lookup (whitelist of NEU users)
-- One-to-one with dbo.[User] via Email_ID -> Neu_Email
-- =====================================================
CREATE TABLE dbo.User_Lookup (
    LookupID           INT IDENTITY(1,1) PRIMARY KEY,
    Neu_Email          NVARCHAR(255) NOT NULL UNIQUE,
    Expected_User_Name NVARCHAR(100) NOT NULL
);
GO

-- Enforce 1–1 relationship between User and User_Lookup by email
ALTER TABLE dbo.[User]
ADD CONSTRAINT FK_User_UserLookup
    FOREIGN KEY (Email_ID)
    REFERENCES dbo.User_Lookup(Neu_Email)
    ON DELETE NO ACTION
    ON UPDATE CASCADE;
GO

-- =====================================================
-----------------Table: Pickup_Point--------------------
-- =====================================================
CREATE TABLE dbo.Pickup_Point (
    PickupPointID INT IDENTITY(1,1) PRIMARY KEY,
    Zipcode VARCHAR(10) NOT NULL,
    CampusID INT NOT NULL,
    Location_Name NVARCHAR(100) NOT NULL,
    Street NVARCHAR(255) NOT NULL,
    FOREIGN KEY (Zipcode) REFERENCES dbo.Zipcode(Zipcode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,  -- changed
    FOREIGN KEY (CampusID) REFERENCES dbo.Campus(CampusID)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO

CREATE INDEX IX_Pickup_Point_Zipcode ON dbo.Pickup_Point(Zipcode);
CREATE INDEX IX_Pickup_Point_Campus  ON dbo.Pickup_Point(CampusID);
GO

-- =====================================================
-------------------Table: Product-----------------------
-- =====================================================
CREATE TABLE dbo.Product (
    Product_ID INT IDENTITY(1,1) PRIMARY KEY,
    Category_ID INT NOT NULL,
    Seller_ID INT NOT NULL,
    Product_Name NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX) NOT NULL,  -- TEXT -> NVARCHAR(MAX) -- since TEXT is deprecated
    Standard_price DECIMAL(10,2) NOT NULL,
    Unit_price     DECIMAL(10,2) NOT NULL,
    Quantity INT NOT NULL,
    Product_Status NVARCHAR(20) NOT NULL,
    Created_date DATE NOT NULL,
    FOREIGN KEY (Category_ID) REFERENCES dbo.Category(Category_ID)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    FOREIGN KEY (Seller_ID) REFERENCES dbo.[User](UserID)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT CHK_Product_UnitPrice   CHECK (Unit_price > 0),
    CONSTRAINT CHK_Product_Quantity    CHECK (Quantity >= 0),
    CONSTRAINT CHK_Product_Status      CHECK (Product_Status IN ('Active', 'Sold', 'Inactive')) 
);
GO

CREATE INDEX IX_Product_Category ON dbo.Product(Category_ID);
CREATE INDEX IX_Product_Seller   ON dbo.Product(Seller_ID);
CREATE INDEX IX_Product_Status   ON dbo.Product(Product_Status);
GO

-- =====================================================
---------------Table: Product_Media--------------------
-- =====================================================
CREATE TABLE dbo.Product_Media (
    Media_ID    INT IDENTITY(1,1) PRIMARY KEY,
    Product_ID  INT NOT NULL,
    Media_link  NVARCHAR(500) NOT NULL,
    Media_Type  NVARCHAR(50)  NOT NULL,
    FOREIGN KEY (Product_ID) REFERENCES dbo.Product(Product_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
GO

CREATE INDEX IX_Product_Media_Product ON dbo.Product_Media(Product_ID);
GO

-- =====================================================
---------------------Table: Order-----------------------
-- =====================================================
CREATE TABLE dbo.[Order] (
    OrderID     INT IDENTITY(1,1) PRIMARY KEY,
    Product_ID  INT NOT NULL,
    Seller_ID   INT NOT NULL,
    Buyer_ID    INT NOT NULL,
    Order_Date  DATE NOT NULL,
    Quantity    INT  NOT NULL,
    Status      NVARCHAR(50) NOT NULL,
    FOREIGN KEY (Product_ID) REFERENCES dbo.Product(Product_ID)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,          
    FOREIGN KEY (Seller_ID) REFERENCES dbo.[User](UserID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,        
    FOREIGN KEY (Buyer_ID) REFERENCES dbo.[User](UserID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,        
    CONSTRAINT CHK_Order_Quantity CHECK (Quantity > 0),
    CONSTRAINT CHK_Order_Status   CHECK (Status IN (N'Confirmed', N'Delivered', N'Cancelled'))
);
GO

CREATE INDEX IX_Order_Product ON dbo.[Order](Product_ID);
CREATE INDEX IX_Order_Seller  ON dbo.[Order](Seller_ID);
CREATE INDEX IX_Order_Buyer   ON dbo.[Order](Buyer_ID);
CREATE INDEX IX_Order_Status  ON dbo.[Order](Status);
GO

-- ============================================================
-------Table: Escrow (1-to-1 relationship with Order)----------
-- ============================================================
CREATE TABLE dbo.Escrow (
    EscrowID      INT IDENTITY(1,1) PRIMARY KEY,
    OrderID       INT NOT NULL UNIQUE,  -- 1:1
    Amount        DECIMAL(10,2) NOT NULL,
    Status        NVARCHAR(20)  NOT NULL,
    Created_Date  DATETIME NOT NULL,
    Release_Date  DATETIME NULL,
    FOREIGN KEY (OrderID) REFERENCES dbo.[Order](OrderID)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT CHK_Escrow_Amount CHECK (Amount > 0),
    CONSTRAINT CHK_Escrow_Status CHECK (
        Status IN (N'Held', N'Released', N'Refunded', N'Dispute_Raised')
    )
);
GO

CREATE INDEX IX_Escrow_Order  ON dbo.Escrow(OrderID);
CREATE INDEX IX_Escrow_Status ON dbo.Escrow(Status);
GO

-- =====================================================
----Table: Rating (one rating per rater per order)------
-- =====================================================
-- Note:
--  one rating per order.
--  Only the buyer (rater) can rate the seller (rated user).

CREATE TABLE dbo.Rating (
    RatingID       INT IDENTITY(1,1) PRIMARY KEY,
    Order_ID       INT NOT NULL UNIQUE,  -- at most one rating per order
    Rater_UserID   INT NOT NULL,         -- must be the Buyer of that Order
    Rated_UserID   INT NOT NULL,         -- must be the Seller of that Order
    Rating_Value   DECIMAL(3,2) NOT NULL,
    Rating_Date    DATE NOT NULL,

    -- Referential integrity
    CONSTRAINT FK_Rating_Order
        FOREIGN KEY (Order_ID) REFERENCES dbo.[Order](OrderID)
        ON DELETE NO ACTION ON UPDATE CASCADE,

    CONSTRAINT FK_Rating_RaterUser
        FOREIGN KEY (Rater_UserID) REFERENCES dbo.[User](UserID)
        ON DELETE NO ACTION ON UPDATE NO ACTION,   -- changed

    CONSTRAINT FK_Rating_RatedUser
        FOREIGN KEY (Rated_UserID) REFERENCES dbo.[User](UserID)
        ON DELETE NO ACTION ON UPDATE NO ACTION,   -- changed

    CONSTRAINT CHK_Rating_Value CHECK (Rating_Value BETWEEN 1.00 AND 5.00)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Order_OrderID_Buyer')
    CREATE UNIQUE INDEX UQ_Order_OrderID_Buyer ON dbo.[Order](OrderID, Buyer_ID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Order_OrderID_Seller')
    CREATE UNIQUE INDEX UQ_Order_OrderID_Seller ON dbo.[Order](OrderID, Seller_ID);
GO

ALTER TABLE dbo.Rating
ADD CONSTRAINT FK_Rating_Order_Buyer
FOREIGN KEY (Order_ID, Rater_UserID)
REFERENCES dbo.[Order](OrderID, Buyer_ID)
ON DELETE NO ACTION ON UPDATE NO ACTION;  
GO

ALTER TABLE dbo.Rating
ADD CONSTRAINT FK_Rating_Order_Seller
FOREIGN KEY (Order_ID, Rated_UserID)
REFERENCES dbo.[Order](OrderID, Seller_ID)
ON DELETE NO ACTION ON UPDATE NO ACTION;  
GO

-- =====================================================
-- Escrow_Verification (verification code temp-like table)
-- One row per Order, globally-unique 6-digit code
-- =====================================================
CREATE TABLE dbo.Escrow_Verification (
    OrderID           INT           NOT NULL PRIMARY KEY,  -- one row per order
    Buyer_UserID      INT           NOT NULL,
    Seller_UserID     INT           NOT NULL,
    Buyer_Name        NVARCHAR(100) NOT NULL,
    Verification_Code CHAR(6)       NOT NULL,              -- 6-digit code
    Generated_At      DATETIME      NOT NULL DEFAULT (GETDATE()),
    Is_Used           BIT           NOT NULL DEFAULT (0),

    CONSTRAINT FK_EscrowVer_Order
        FOREIGN KEY (OrderID) REFERENCES dbo.[Order](OrderID),

    CONSTRAINT FK_EscrowVer_Buyer
        FOREIGN KEY (Buyer_UserID) REFERENCES dbo.[User](UserID),

    CONSTRAINT FK_EscrowVer_Seller
        FOREIGN KEY (Seller_UserID) REFERENCES dbo.[User](UserID),

    -- Global uniqueness: no two orders share the same code
    CONSTRAINT UQ_EscrowVer_Code UNIQUE (Verification_Code)
);
GO

-- =====================================================
-----------Table: Product_Audit_Logs--------------------
-- =====================================================
CREATE TABLE dbo.Product_Audit_Logs (
    Product_Audit_ID     INT IDENTITY(1,1) PRIMARY KEY,
    Performed_By_UserID  INT NOT NULL,
    Product_ID           INT NOT NULL,
    [Timestamp]          DATETIME NOT NULL,          
    Field_Change         VARCHAR(100) NOT NULL,
    Old_value            VARCHAR(500) NULL,
    New_value            VARCHAR(500) NULL,
    FOREIGN KEY (Performed_By_UserID) REFERENCES dbo.[User](UserID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,       
    FOREIGN KEY (Product_ID) REFERENCES dbo.Product(Product_ID)
        ON DELETE NO ACTION        
        ON UPDATE NO ACTION        
);
GO

CREATE INDEX IX_Product_Audit_User      ON dbo.Product_Audit_Logs(Performed_By_UserID);
CREATE INDEX IX_Product_Audit_Product   ON dbo.Product_Audit_Logs(Product_ID);
CREATE INDEX IX_Product_Audit_Timestamp ON dbo.Product_Audit_Logs([Timestamp]);
GO

-- =====================================================
------------Table: Escrow_Audit_Logs--------------------
-- =====================================================
CREATE TABLE dbo.Escrow_Audit_Logs (
    Escrow_Audit_ID      INT IDENTITY(1,1) PRIMARY KEY,
    Performed_By_UserID  INT NOT NULL,
    Escrow_ID            INT NOT NULL,
    [Timestamp]          DATETIME NOT NULL,
    Field_Change         VARCHAR(100) NOT NULL,
    Old_status           VARCHAR(20) NULL,
    New_status           VARCHAR(20) NULL,
    FOREIGN KEY (Performed_By_UserID) REFERENCES dbo.[User](UserID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    FOREIGN KEY (Escrow_ID) REFERENCES dbo.Escrow(EscrowID)
        ON DELETE NO ACTION  
        ON UPDATE NO ACTION  
);
GO

CREATE INDEX IX_Escrow_Audit_User      ON dbo.Escrow_Audit_Logs(Performed_By_UserID);
CREATE INDEX IX_Escrow_Audit_Escrow    ON dbo.Escrow_Audit_Logs(Escrow_ID);
CREATE INDEX IX_Escrow_Audit_Timestamp ON dbo.Escrow_Audit_Logs([Timestamp]);
GO

-- =====================================================
------------------Table: Dispute------------------------
-- =====================================================
CREATE TABLE dbo.Dispute (
    Dispute_ID          INT IDENTITY(1,1) PRIMARY KEY,
    EscrowID            INT NOT NULL,
    FiledByUserID       INT NOT NULL,
    Description         NVARCHAR(MAX) NOT NULL,     
    Open_Date           DATE NOT NULL,
    Resolution_Details  NVARCHAR(MAX) NULL,          
    Resolved_Date       DATE NULL,
    Status              VARCHAR(50) NOT NULL,
    FOREIGN KEY (EscrowID) REFERENCES dbo.Escrow(EscrowID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,  
    FOREIGN KEY (FiledByUserID) REFERENCES dbo.[User](UserID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,  
    CONSTRAINT CHK_Dispute_Status
        CHECK (Status IN ('Open','In Progress','Resolved','Closed'))
);
GO

CREATE INDEX IX_Dispute_Escrow   ON dbo.Dispute(EscrowID);
CREATE INDEX IX_Dispute_FiledBy  ON dbo.Dispute(FiledByUserID);
CREATE INDEX IX_Dispute_Status   ON dbo.Dispute(Status);
GO

-- =====================================================
--------------Table: Dispute_Evidence-------------------
-- =====================================================
CREATE TABLE dbo.Dispute_Evidence (
    Evidence_ID  INT IDENTITY(1,1) PRIMARY KEY,
    Dispute_ID   INT NOT NULL,
    Media_link   VARCHAR(500) NOT NULL,
    Media_Type   VARCHAR(50) NOT NULL,
    FOREIGN KEY (Dispute_ID) REFERENCES dbo.Dispute(Dispute_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
GO

CREATE INDEX IX_Dispute_Evidence_Dispute ON dbo.Dispute_Evidence(Dispute_ID);
GO

-- =============================================================================
----------Table: Order_Collection (1-to-1 relationship with Order)--------------
-- =============================================================================
CREATE TABLE dbo.Order_Collection (
    Collection_ID     INT IDENTITY(1,1) PRIMARY KEY,
    Order_ID          INT NOT NULL UNIQUE,  
    Pickup_Point_ID   INT NOT NULL,
    Scheduled_Time    TIME NULL,
    Scheduled_Date    DATE NULL,
    FOREIGN KEY (Order_ID)
        REFERENCES dbo.[Order](OrderID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,    

    FOREIGN KEY (Pickup_Point_ID)
        REFERENCES dbo.Pickup_Point(PickupPointID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION     
);
GO

CREATE INDEX IX_OrderCollection_Order       ON dbo.Order_Collection(Order_ID);
CREATE INDEX IX_OrderCollection_PickupPoint ON dbo.Order_Collection(Pickup_Point_ID);
GO

-- =====================================================
--------------Schema Creation Complete------------------
-- =====================================================