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


