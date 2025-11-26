-- =====================================================
-- Add Password column to User table
-- =====================================================
ALTER TABLE dbo.[User]
ADD [Password] NVARCHAR(255) NULL;  -- in real life: store hashed passwords
GO