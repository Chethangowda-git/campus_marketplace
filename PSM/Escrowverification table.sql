IF OBJECT_ID('dbo.Escrow_Verification', 'U') IS NOT NULL
    DROP TABLE dbo.Escrow_Verification;
GO

CREATE TABLE dbo.Escrow_Verification (
    OrderID           INT           NOT NULL PRIMARY KEY,      -- one row per order
    Buyer_UserID      INT           NOT NULL,
    Seller_UserID     INT           NOT NULL,
    Buyer_Name        NVARCHAR(100) NOT NULL,
    Verification_Code CHAR(6)       NOT NULL,                  -- 6-digit code
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

