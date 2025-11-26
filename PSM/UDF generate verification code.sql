CREATE OR ALTER FUNCTION dbo.ufn_FormatVerificationCode
(
    @RandomInt INT   -- must be between 0 and 999999
)
RETURNS CHAR(6)
AS
BEGIN
    RETURN RIGHT('000000' + CAST(@RandomInt AS VARCHAR(6)), 6);
END;
GO