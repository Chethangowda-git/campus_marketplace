-- 01_encryption_setup.sql
-- =====================================================
-- Encryption Infrastructure for campus_marketplace
-- - Database Master Key
-- - Certificate
-- - Symmetric Key (AES_256)
-- =====================================================

USE campus_marketplace;
GO

-- 1. Create Database Master Key (one per database)
--    NOTE: Choose a strong password and keep it safe.
IF NOT EXISTS (
    SELECT 1 
    FROM sys.symmetric_keys 
    WHERE name = '##MS_DatabaseMasterKey##'
)
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongMasterKeyPassword!123';
END;
GO

-- 2. Create Certificate (used to protect the symmetric key)
IF NOT EXISTS (
    SELECT 1 
    FROM sys.certificates 
    WHERE name = 'UserDataEncryptionCert'
)
BEGIN
    CREATE CERTIFICATE UserDataEncryptionCert
    WITH SUBJECT = 'Certificate for User Table Encryption';
END;
GO

-- 3. Create Symmetric Key (actual key used for column encryption)
IF NOT EXISTS (
    SELECT 1 
    FROM sys.symmetric_keys 
    WHERE name = 'UserDataSymKey'
)
BEGIN
    CREATE SYMMETRIC KEY UserDataSymKey
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE UserDataEncryptionCert;
END;
GO

-- We use a database master key, a certificate, and an AES-256 symmetric key to implement column-level encryption for sensitive user data.







-- 02_user_encrypted_columns.sql
-- =====================================================
-- Add encrypted columns for sensitive user data
--   - Encrypted_Password : encrypted version of password
--   - Encrypted_Phone    : encrypted version of phone number
-- =====================================================

USE campus_marketplace;
GO

-- 1. Add encrypted columns (if not already present)
IF COL_LENGTH('dbo.[User]', 'Encrypted_Password') IS NULL
BEGIN
    ALTER TABLE dbo.[User]
    ADD Encrypted_Password VARBINARY(MAX) NULL;
END;
GO

IF COL_LENGTH('dbo.[User]', 'Encrypted_Phone') IS NULL
BEGIN
    ALTER TABLE dbo.[User]
    ADD Encrypted_Phone VARBINARY(MAX) NULL;
END;
GO

-- 2. (Optional but recommended) Drop plain-text Password column if it exists
--    This shows that we are not storing raw passwords at rest.
IF COL_LENGTH('dbo.[User]', 'Password') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[User]
    DROP COLUMN [Password];
END;
GO


-- Encrypted_Password will contain the encrypted password (instead of storing it in clear text).
-- Encrypted_Phone will contain the encrypted phone number.
-- We kept Phone_number column for compatibility with existing sample data, but sensitive storage is in Encrypted_Phone. For a real system, 
--     we could eventually remove the plain column and only expose decrypted values when necessary.






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