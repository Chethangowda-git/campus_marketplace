-- 1) Populate User_Lookup from existing User rows
INSERT INTO dbo.User_Lookup (Neu_Email, Expected_User_Name)
SELECT 
    Email_ID,
    User_Name
FROM dbo.[User];

-- 2) Now add the foreign key
ALTER TABLE dbo.[User]
ADD CONSTRAINT FK_User_UserLookup
    FOREIGN KEY (Email_ID)
    REFERENCES dbo.User_Lookup(Neu_Email)
    ON DELETE NO ACTION
    ON UPDATE CASCADE;
GO