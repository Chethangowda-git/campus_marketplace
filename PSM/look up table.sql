-- =====================================================
-- LOOKUP TABLE: User_Lookup
-- Purpose:
--   Whitelist of allowed NEU users for signup.
--   One-to-one with dbo.[User] via NEU email.
-- =====================================================
USE campus_marketplace;
GO

-- =====================================================
-- LOOKUP TABLE: User_Lookup
-- Whitelist of allowed NEU users for signup.
-- One-to-one with dbo.[User] via NEU email.
-- =====================================================

IF OBJECT_ID('dbo.User_Lookup', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.User_Lookup (
        LookupID           INT IDENTITY(1,1) PRIMARY KEY,
        Neu_Email          NVARCHAR(255) NOT NULL UNIQUE,
        Expected_User_Name NVARCHAR(100) NOT NULL
    );
END;
GO

-- Seed lookup from existing users if missing
INSERT INTO dbo.User_Lookup (Neu_Email, Expected_User_Name)
SELECT 
    u.Email_ID,
    u.User_Name
FROM dbo.[User] u
LEFT JOIN dbo.User_Lookup lu
    ON lu.Neu_Email = u.Email_ID
WHERE lu.Neu_Email IS NULL;
GO

-- Add FK only if it does not exist
-- Enforce 1–1 relationship between User and User_Lookup by email
IF NOT EXISTS (
    SELECT 1 
    FROM sys.foreign_keys 
    WHERE name = 'FK_User_UserLookup'
      AND parent_object_id = OBJECT_ID('dbo.[User]')
)
BEGIN
    ALTER TABLE dbo.[User]
    ADD CONSTRAINT FK_User_UserLookup
        FOREIGN KEY (Email_ID)
        REFERENCES dbo.User_Lookup(Neu_Email)
        ON DELETE NO ACTION
        ON UPDATE CASCADE;
END;
GO
