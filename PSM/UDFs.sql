-- =====================================================
-- UDF: ufn_MaskEmail
-- Purpose:
--   Returns a masked version of an email address to
--   protect user privacy in reporting views.
--
--   Examples:
--     'john.doe@northeastern.edu'
--       -> 'j*****e@northeastern.edu'
--
--   Rules:
--     - If '@' is missing, returns the original string.
--     - Keeps first and last character of the local part,
--       masks everything in between with '*'.
-- =====================================================
CREATE OR ALTER FUNCTION dbo.ufn_MaskEmail
(
    @Email NVARCHAR(255)
)
RETURNS NVARCHAR(255)
AS
BEGIN
    DECLARE 
        @AtPos INT,
        @LocalPart NVARCHAR(255),
        @DomainPart NVARCHAR(255),
        @LocalLen INT,
        @MaskedLocal NVARCHAR(255);

    -- Find '@'
    SET @AtPos = CHARINDEX('@', @Email);

    -- If no '@', return as is
    IF @AtPos = 0
        RETURN @Email;

    SET @LocalPart  = SUBSTRING(@Email, 1, @AtPos - 1);
    SET @DomainPart = SUBSTRING(@Email, @AtPos + 1, LEN(@Email) - @AtPos);
    SET @LocalLen   = LEN(@LocalPart);

    -- Handle very short local parts
    IF @LocalLen <= 1
        SET @MaskedLocal = REPLICATE('*', @LocalLen);
    ELSE IF @LocalLen = 2
        SET @MaskedLocal = LEFT(@LocalPart, 1) + '*';
    ELSE
        -- Keep first and last char, mask the middle
        SET @MaskedLocal = 
            LEFT(@LocalPart, 1) +
            REPLICATE('*', @LocalLen - 2) +
            RIGHT(@LocalPart, 1);

    RETURN @MaskedLocal + N'@' + @DomainPart;
END;
GO

-- ====================================================================================================================================================================================================================

-- =====================================================
-- UDF: ufn_GetSellerAverageRating
-- Purpose:
--   Returns the average rating for a given Seller (UserID)
--   based on Rating.Rating_Value where Rated_UserID = @SellerID.
--
-- Behavior:
--   - If the seller has no ratings, returns 0.00
--     (consistent with Agg_Seller_Rating default = 0.00).
-- =====================================================
CREATE OR ALTER FUNCTION dbo.ufn_GetSellerAverageRating
(
    @SellerID INT
)
RETURNS DECIMAL(4,2)
AS
BEGIN
    DECLARE @Avg DECIMAL(4,2);

    SELECT 
        @Avg = AVG(CAST(Rating_Value AS DECIMAL(4,2)))
    FROM dbo.Rating
    WHERE Rated_UserID = @SellerID;

    RETURN ISNULL(@Avg, 0.00);
END;
GO

-- =====================================================
-- Trigger: trg_Rating_UpdateSellerAgg
--
-- Purpose:
--   Maintain [User].Agg_Seller_Rating automatically whenever
--   ratings are inserted, updated, or deleted.
--
-- Logic:
--   - Identify all distinct sellers (Rated_UserID) affected
--     by the operation (from INSERTED and DELETED).
--   - For each such seller, recompute:
--         Agg_Seller_Rating = dbo.ufn_GetSellerAverageRating(UserID)
--     using the UDF.
--
-- Notes:
--   - Works for INSERT, UPDATE, and DELETE.
--   - If all ratings for a seller are deleted, the UDF
--     returns 0.00 and the aggregate is reset to 0.00.
-- =====================================================
CREATE OR ALTER TRIGGER dbo.trg_Rating_UpdateSellerAgg
ON dbo.Rating
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH ChangedSellers AS (
        SELECT DISTINCT Rated_UserID AS SellerID
        FROM inserted
        WHERE Rated_UserID IS NOT NULL

        UNION

        SELECT DISTINCT Rated_UserID AS SellerID
        FROM deleted
        WHERE Rated_UserID IS NOT NULL
    )
    UPDATE u
    SET Agg_Seller_Rating = dbo.ufn_GetSellerAverageRating(u.UserID)
    FROM dbo.[User] u
    JOIN ChangedSellers cs
        ON u.UserID = cs.SellerID;
END;
GO
