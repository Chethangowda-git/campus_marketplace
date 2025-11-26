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

