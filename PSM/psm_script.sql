-- 1. Stored procedure: create order + order collection

-- (Scenario 1 – buyer selects product, pickup point, time/date)
-- 	•	Inserts a new row in [Order].
-- 	•	Inserts the matching row in Order_Collection.
-- 	•	Uses a transaction + TRY/CATCH.
-- 	•	Has both input and output parameters.

-- =====================================================
-- usp_CreateOrderWithCollection
-- Scenario 1: Buyer creates order and schedules pickup
-- =====================================================
-- 1. Stored procedure: create order + order collection

-- (Scenario 1 – buyer selects product, pickup point, time/date)
-- 	•	Inserts a new row in [Order].
-- 	•	Inserts the matching row in Order_Collection.
-- 	•	Uses a transaction + TRY/CATCH.
-- 	•	Has both input and output parameters.

-- =====================================================
-- usp_CreateOrderWithCollection
-- Scenario 1: Buyer creates order and schedules pickup
-- =====================================================
CREATE OR ALTER PROCEDURE dbo.usp_CreateOrderWithCollection
    @ProductID       INT,
    @BuyerID         INT,
    @Quantity        INT,
    @PickupPointID   INT,
    @ScheduledDate   DATE = NULL,
    @ScheduledTime   TIME = NULL,
    @NewOrderID      INT OUTPUT,
    @ResultCode      INT OUTPUT,          -- 0 = success, 1 = validation error, 2 = other error
    @ResultMessage   NVARCHAR(400) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SellerID INT;

    BEGIN TRY
        SET @ResultCode = 0;
        SET @ResultMessage = N'';

        BEGIN TRAN;

        -- Get Seller from Product
        SELECT @SellerID = Seller_ID
        FROM dbo.Product
        WHERE Product_ID = @ProductID;

        IF @SellerID IS NULL
        BEGIN
            SET @ResultCode = 1;
            SET @ResultMessage = N'Invalid Product_ID.';
            RAISERROR ('Invalid Product_ID.', 16, 1);
        END;

        -- Basic quantity validation (optional)
        DECLARE @AvailableQty INT;
        SELECT @AvailableQty = Quantity
        FROM dbo.Product
        WHERE Product_ID = @ProductID;

        IF @AvailableQty IS NULL OR @AvailableQty < @Quantity
        BEGIN
            SET @ResultCode = 1;
            SET @ResultMessage = N'Insufficient product quantity.';
            RAISERROR ('Insufficient product quantity.', 16, 1);
        END;

        -- Insert Order
        INSERT INTO dbo.[Order] (Product_ID, Seller_ID, Buyer_ID, Order_Date, Quantity, Status)
        VALUES (@ProductID, @SellerID, @BuyerID, CAST(GETDATE() AS DATE), @Quantity, N'Confirmed');

        SET @NewOrderID = SCOPE_IDENTITY();

        -- Insert Order_Collection entry for this order
        INSERT INTO dbo.Order_Collection (Order_ID, Pickup_Point_ID, Scheduled_Time, Scheduled_Date)
        VALUES (@NewOrderID, @PickupPointID, @ScheduledTime, @ScheduledDate);

        COMMIT TRAN;

        SET @ResultCode = 0;
        SET @ResultMessage = N'Order and collection created successfully.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        IF @ResultCode IS NULL OR @ResultCode = 0
            SET @ResultCode = 2;  -- generic error

        SET @ResultMessage = CONCAT(
            ISNULL(@ResultMessage, N''),
            CASE WHEN LEN(ISNULL(@ResultMessage, N'')) > 0 THEN N' ' ELSE N'' END,
            N'Error: ', ERROR_MESSAGE()
        );
    END CATCH;
END;
GO

-- This procedure covers:
-- 	•	input params (product, buyer, pickup details),
-- 	•	output params (@NewOrderID, @ResultCode, @ResultMessage),
-- 	•	transaction + TRY/CATCH.

-- ===============================================================================================================================================================

-- 2️⃣ Stored procedure: start escrow + generate verification code

-- =============================================================
-- Stored Procedure: usp_InitiateEscrowVerification
--
-- Scenario 2 (Part 1): After checkout, buyer triggers escrow.
--
-- Responsibilities:
--   • Ensure the order and escrow record exist.
--   • Set Escrow.Status = 'Held'   (payment initiated).
--   • If a verification code already exists for this order:
--         → return the existing code (no regeneration).
--   • If no code exists:
--         → generate a globally-unique 6-digit verification code
--           using dbo.ufn_GenerateVerificationCode().
--         → insert into Escrow_Verification:
--             - OrderID
--             - Buyer_UserID
--             - Seller_UserID
--             - Buyer_Name
--             - Verification_Code
--   • Return the code to the front-end via OUTPUT parameter.
--
-- Notes:
--   • Verification_Code is globally unique (enforced by UNIQUE constraint).
--   • One active code per order (PRIMARY KEY (OrderID)).
--   • This procedure does NOT regenerate codes once created.
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.usp_InitiateEscrowVerification
    @OrderID          INT,
    @VerificationCode CHAR(6) OUTPUT,
    @ResultCode       INT OUTPUT,         -- 0 = success, 1 = not found, 2 = other error
    @ResultMessage    NVARCHAR(400) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BuyerID  INT, @BuyerName NVARCHAR(100), @SellerID INT;

    BEGIN TRY
        SET @ResultCode = 0;
        SET @ResultMessage = N'';

        BEGIN TRAN;

        -- Get buyer & seller info from order
        SELECT 
            @BuyerID   = o.Buyer_ID,
            @BuyerName = u.User_Name,
            @SellerID  = o.Seller_ID
        FROM dbo.[Order] o
        JOIN dbo.[User] u ON o.Buyer_ID = u.UserID
        WHERE o.OrderID = @OrderID;

        IF @BuyerID IS NULL OR @SellerID IS NULL
        BEGIN
            SET @ResultCode = 1;
            SET @ResultMessage = N'Order not found.';
            RAISERROR ('Order not found.', 16, 1);
        END;

        -- Ensure escrow exists for this order
        IF NOT EXISTS (SELECT 1 FROM dbo.Escrow WHERE OrderID = @OrderID)
        BEGIN
            SET @ResultCode = 1;
            SET @ResultMessage = N'Escrow record not found for this order.';
            RAISERROR ('Escrow record not found for this order.', 16, 1);
        END;

        -- Set escrow status to 'Held' (payment initiated) if not already
        UPDATE dbo.Escrow
        SET Status = N'Held',
            Created_Date = ISNULL(Created_Date, GETDATE())
        WHERE OrderID = @OrderID;

        -- If a code already exists for this order, DO NOT change it (Option A)
        IF EXISTS (SELECT 1 FROM dbo.Escrow_Verification WHERE OrderID = @OrderID)
        BEGIN
            SELECT 
                @VerificationCode = Verification_Code
            FROM dbo.Escrow_Verification
            WHERE OrderID = @OrderID;

            COMMIT TRAN;

            SET @ResultCode = 0;
            SET @ResultMessage = N'Escrow already initiated. Returning existing verification code.';
            RETURN;
        END;

        -- Otherwise generate a new globally unique code using the formatter UDF
        DECLARE @Attempt INT = 0;
        WHILE 1 = 1
        BEGIN
            DECLARE @Rand INT;
            SET @Rand = ABS(CHECKSUM(NEWID())) % 1000000;  -- 0..999999 in SP (allowed)
            SET @VerificationCode = dbo.ufn_FormatVerificationCode(@Rand);

            IF NOT EXISTS (
                SELECT 1 
                FROM dbo.Escrow_Verification
                WHERE Verification_Code = @VerificationCode
            )
                BREAK;  -- unique code found

            SET @Attempt += 1;
            IF @Attempt > 10
            BEGIN
                SET @ResultCode = 2;
                SET @ResultMessage = N'Unable to generate a unique verification code after multiple attempts.';
                RAISERROR ('Unable to generate a unique verification code.', 16, 1);
            END;
        END;

        -- Insert new record into Escrow_Verification
        INSERT INTO dbo.Escrow_Verification
            (OrderID, Buyer_UserID, Seller_UserID, Buyer_Name, Verification_Code)
        VALUES
            (@OrderID, @BuyerID, @SellerID, @BuyerName, @VerificationCode);

        COMMIT TRAN;

        SET @ResultCode = 0;
        SET @ResultMessage = N'Escrow initiated and verification code generated.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        IF @ResultCode IS NULL OR @ResultCode = 0
            SET @ResultCode = 2;

        SET @ResultMessage = CONCAT(
            ISNULL(@ResultMessage, N''),
            CASE WHEN LEN(ISNULL(@ResultMessage, N'')) > 0 THEN N' ' ELSE N'' END,
            N'Error: ', ERROR_MESSAGE()
        );
    END CATCH;
END;
GO


-- ===============================================================================================================================================================

-- 3️⃣ Stored procedure: verify code + complete payment

-- =============================================================
-- Stored Procedure: usp_VerifyEscrowCodeAndCompletePayment
--
-- Scenario 2 (Part 2): Seller enters the verification code
-- during in-person meetup with the buyer.
--
-- Responsibilities:
--   • Validate the verification code for the given OrderID.
--   • Validate that the seller attempting verification is the
--       SAME seller assigned to the order (stored in Escrow_Verification).
--   • Reject if:
--       - no code exists,
--       - seller does not match,
--       - code is incorrect,
--       - code was previously used.
--   • If verification succeeds:
--       - update Escrow.Status = 'Released'   (payment completed),
--       - set Escrow.Release_Date = current timestamp,
--       - delete the row from Escrow_Verification
--         (code is destroyed after completion).
--
-- Notes:
--   • Deleting the row allows the table to behave like a
--     “temp-like” store without affecting other orders.
--   • Audit of Escrow.Status changes is handled by your trigger.
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.usp_VerifyEscrowCodeAndCompletePayment
    @OrderID        INT,
    @SellerID       INT,
    @EnteredCode    CHAR(6),
    @IsVerified     BIT OUTPUT,           -- 1 = success, 0 = failure
    @ResultCode     INT OUTPUT,           -- 0 = success, 1 = invalid, 2 = other error
    @ResultMessage  NVARCHAR(400) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @StoredCode      CHAR(6),
        @IsUsed          BIT,
        @StoredSellerID  INT;

    BEGIN TRY
        SET @IsVerified = 0;
        SET @ResultCode = 0;
        SET @ResultMessage = N'';

        BEGIN TRAN;

        -- Load verification data
        SELECT 
            @StoredCode     = Verification_Code,
            @IsUsed         = Is_Used,
            @StoredSellerID = Seller_UserID
        FROM dbo.Escrow_Verification
        WHERE OrderID = @OrderID;

        IF @StoredCode IS NULL
        BEGIN
            SET @ResultCode = 1;
            SET @ResultMessage = N'No verification code found for this order.';
            RAISERROR ('No verification code found for this order.', 16, 1);
        END;

        -- Make sure the seller is the correct seller for this order
        IF @StoredSellerID <> @SellerID
        BEGIN
            SET @ResultCode = 1;
            SET @ResultMessage = N'Seller mismatch. You are not authorized for this order.';
            RAISERROR ('Seller mismatch.', 16, 1);
        END;

        IF @IsUsed = 1
        BEGIN
            SET @ResultCode = 1;
            SET @ResultMessage = N'Code already used.';
            RAISERROR ('Code already used.', 16, 1);
        END;

        IF @StoredCode <> @EnteredCode
        BEGIN
            SET @ResultCode = 1;
            SET @ResultMessage = N'Invalid verification code.';
            RAISERROR ('Invalid verification code.', 16, 1);
        END;

        -- If we reach here, seller is correct and code is valid & unused
        UPDATE dbo.Escrow
        SET Status       = N'Released',   -- payment completed
            Release_Date = GETDATE()
        WHERE OrderID = @OrderID;

        -- Mark as used and remove the temp data (destroy the code)
        DELETE FROM dbo.Escrow_Verification
        WHERE OrderID = @OrderID;

        COMMIT TRAN;

        SET @IsVerified  = 1;
        SET @ResultCode  = 0;
        SET @ResultMessage = N'Code verified and payment completed.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        IF @ResultCode IS NULL OR @ResultCode = 0
            SET @ResultCode = 2;

        SET @ResultMessage = CONCAT(
            ISNULL(@ResultMessage, N''),
            CASE WHEN LEN(ISNULL(@ResultMessage, N'')) > 0 THEN N' ' ELSE N'' END,
            N'Error: ', ERROR_MESSAGE()
        );

        SET @IsVerified = 0;
    END CATCH;
END;
GO
-- ===============================================================================================================================================================



-- This procedure covers:
-- 	•	input params (product, buyer, pickup details),
-- 	•	output params (@NewOrderID, @ResultCode, @ResultMessage),
-- 	•	transaction + TRY/CATCH.

-- ===============================================================================================================================================================

-- 2️⃣ Stored procedure: start escrow + generate verification code

-- =============================================================
-- Stored Procedure: usp_InitiateEscrowVerification
--
-- Scenario 2 (Part 1): After checkout, buyer triggers escrow.
--
-- Responsibilities:
--   • Ensure the order and escrow record exist.
--   • Set Escrow.Status = 'Held'   (payment initiated).
--   • If a verification code already exists for this order:
--         → return the existing code (no regeneration).
--   • If no code exists:
--         → generate a globally-unique 6-digit verification code
--           using dbo.ufn_GenerateVerificationCode().
--         → insert into Escrow_Verification:
--             - OrderID
--             - Buyer_UserID
--             - Seller_UserID
--             - Buyer_Name
--             - Verification_Code
--   • Return the code to the front-end via OUTPUT parameter.
--
-- Notes:
--   • Verification_Code is globally unique (enforced by UNIQUE constraint).
--   • One active code per order (PRIMARY KEY (OrderID)).
--   • This procedure does NOT regenerate codes once created.
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.usp_InitiateEscrowVerification
    @OrderID          INT,
    @VerificationCode CHAR(6) OUTPUT,
    @ResultCode       INT OUTPUT,         -- 0 = success, 1 = not found, 2 = other error
    @ResultMessage    NVARCHAR(400) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BuyerID  INT, @BuyerName NVARCHAR(100), @SellerID INT;

    BEGIN TRY
        SET @ResultCode = 0;
        SET @ResultMessage = N'';

        BEGIN TRAN;

        -- Get buyer & seller info from order
        SELECT 
            @BuyerID   = o.Buyer_ID,
            @BuyerName = u.User_Name,
            @SellerID  = o.Seller_ID
        FROM dbo.[Order] o
        JOIN dbo.[User] u ON o.Buyer_ID = u.UserID
        WHERE o.OrderID = @OrderID;

        IF @BuyerID IS NULL OR @SellerID IS NULL
        BEGIN
            SET @ResultCode = 1;
            SET @ResultMessage = N'Order not found.';
            RAISERROR ('Order not found.', 16, 1);
        END;

        -- Ensure escrow exists for this order
        IF NOT EXISTS (SELECT 1 FROM dbo.Escrow WHERE OrderID = @OrderID)
        BEGIN
            SET @ResultCode = 1;
            SET @ResultMessage = N'Escrow record not found for this order.';
            RAISERROR ('Escrow record not found for this order.', 16, 1);
        END;

        -- Set escrow status to 'Held' (payment initiated) if not already
        UPDATE dbo.Escrow
        SET Status = N'Held',
            Created_Date = ISNULL(Created_Date, GETDATE())
        WHERE OrderID = @OrderID;

        -- If a code already exists for this order, DO NOT change it (Option A)
        IF EXISTS (SELECT 1 FROM dbo.Escrow_Verification WHERE OrderID = @OrderID)
        BEGIN
            SELECT 
                @VerificationCode = Verification_Code
            FROM dbo.Escrow_Verification
            WHERE OrderID = @OrderID;

            COMMIT TRAN;

            SET @ResultCode = 0;
            SET @ResultMessage = N'Escrow already initiated. Returning existing verification code.';
            RETURN;
        END;

        -- Otherwise generate a new globally unique code using the formatter UDF
        DECLARE @Attempt INT = 0;
        WHILE 1 = 1
        BEGIN
            DECLARE @Rand INT;
            SET @Rand = ABS(CHECKSUM(NEWID())) % 1000000;  -- 0..999999 in SP (allowed)
            SET @VerificationCode = dbo.ufn_FormatVerificationCode(@Rand);

            IF NOT EXISTS (
                SELECT 1 
                FROM dbo.Escrow_Verification
                WHERE Verification_Code = @VerificationCode
            )
                BREAK;  -- unique code found

            SET @Attempt += 1;
            IF @Attempt > 10
            BEGIN
                SET @ResultCode = 2;
                SET @ResultMessage = N'Unable to generate a unique verification code after multiple attempts.';
                RAISERROR ('Unable to generate a unique verification code.', 16, 1);
            END;
        END;

        -- Insert new record into Escrow_Verification
        INSERT INTO dbo.Escrow_Verification
            (OrderID, Buyer_UserID, Seller_UserID, Buyer_Name, Verification_Code)
        VALUES
            (@OrderID, @BuyerID, @SellerID, @BuyerName, @VerificationCode);

        COMMIT TRAN;

        SET @ResultCode = 0;
        SET @ResultMessage = N'Escrow initiated and verification code generated.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        IF @ResultCode IS NULL OR @ResultCode = 0
            SET @ResultCode = 2;

        SET @ResultMessage = CONCAT(
            ISNULL(@ResultMessage, N''),
            CASE WHEN LEN(ISNULL(@ResultMessage, N'')) > 0 THEN N' ' ELSE N'' END,
            N'Error: ', ERROR_MESSAGE()
        );
    END CATCH;
END;
GO
-- ===============================================================================================================================================================

-- 3️⃣ Stored procedure: verify code + complete payment

-- =============================================================
-- Stored Procedure: usp_VerifyEscrowCodeAndCompletePayment
--
-- Scenario 2 (Part 2): Seller enters the verification code
-- during in-person meetup with the buyer.
--
-- Responsibilities:
--   • Validate the verification code for the given OrderID.
--   • Validate that the seller attempting verification is the
--       SAME seller assigned to the order (stored in Escrow_Verification).
--   • Reject if:
--       - no code exists,
--       - seller does not match,
--       - code is incorrect,
--       - code was previously used.
--   • If verification succeeds:
--       - update Escrow.Status = 'Released'   (payment completed),
--       - set Escrow.Release_Date = current timestamp,
--       - delete the row from Escrow_Verification
--         (code is destroyed after completion).
--
-- Notes:
--   • Deleting the row allows the table to behave like a
--     “temp-like” store without affecting other orders.
--   • Audit of Escrow.Status changes is handled by your trigger.
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.usp_VerifyEscrowCodeAndCompletePayment
    @OrderID        INT,
    @SellerID       INT,
    @EnteredCode    CHAR(6),
    @IsVerified     BIT OUTPUT,           -- 1 = success, 0 = failure
    @ResultCode     INT OUTPUT,           -- 0 = success, 1 = invalid, 2 = other error
    @ResultMessage  NVARCHAR(400) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @StoredCode      CHAR(6),
        @IsUsed          BIT,
        @StoredSellerID  INT;

    BEGIN TRY
        SET @IsVerified = 0;
        SET @ResultCode = 0;
        SET @ResultMessage = N'';

        BEGIN TRAN;

        -- Load verification data
        SELECT 
            @StoredCode     = Verification_Code,
            @IsUsed         = Is_Used,
            @StoredSellerID = Seller_UserID
        FROM dbo.Escrow_Verification
        WHERE OrderID = @OrderID;

        IF @StoredCode IS NULL
        BEGIN
            SET @ResultCode = 1;
            SET @ResultMessage = N'No verification code found for this order.';
            RAISERROR ('No verification code found for this order.', 16, 1);
        END;

        -- Make sure the seller is the correct seller for this order
        IF @StoredSellerID <> @SellerID
        BEGIN
            SET @ResultCode = 1;
            SET @ResultMessage = N'Seller mismatch. You are not authorized for this order.';
            RAISERROR ('Seller mismatch.', 16, 1);
        END;

        IF @IsUsed = 1
        BEGIN
            SET @ResultCode = 1;
            SET @ResultMessage = N'Code already used.';
            RAISERROR ('Code already used.', 16, 1);
        END;

        IF @StoredCode <> @EnteredCode
        BEGIN
            SET @ResultCode = 1;
            SET @ResultMessage = N'Invalid verification code.';
            RAISERROR ('Invalid verification code.', 16, 1);
        END;

        -- If we reach here, seller is correct and code is valid & unused
        UPDATE dbo.Escrow
        SET Status       = N'Released',   -- payment completed
            Release_Date = GETDATE()
        WHERE OrderID = @OrderID;

        -- Mark as used and remove the temp data (destroy the code)
        DELETE FROM dbo.Escrow_Verification
        WHERE OrderID = @OrderID;

        COMMIT TRAN;

        SET @IsVerified  = 1;
        SET @ResultCode  = 0;
        SET @ResultMessage = N'Code verified and payment completed.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        IF @ResultCode IS NULL OR @ResultCode = 0
            SET @ResultCode = 2;

        SET @ResultMessage = CONCAT(
            ISNULL(@ResultMessage, N''),
            CASE WHEN LEN(ISNULL(@ResultMessage, N'')) > 0 THEN N' ' ELSE N'' END,
            N'Error: ', ERROR_MESSAGE()
        );

        SET @IsVerified = 0;
    END CATCH;
END;
GO
-- ===============================================================================================================================================================




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



-- =====================================================
-- CAMPUS MARKETPLACE - VIEW CREATION SCRIPT
-- =====================================================


USE campus_marketplace;
GO


-- =====================================================
-- View 1: Product Listing Summary
-- =====================================================
CREATE VIEW vw_Product_Listing_Summary AS
SELECT
   p.Product_ID,
   p.Product_Name,
   p.Description,
   c.Category_Name,
   p.Unit_price,
   p.Standard_price,
   (p.Standard_price - p.Unit_price) AS Discount_Amount,
   p.Quantity AS Available_Quantity,
   p.Product_Status,
   p.Created_date,
   u.User_Name AS Seller_Name,
   u.Agg_Seller_Rating AS Seller_Rating,
   u.Verification_Status,
   cam.Campus_Name,
   (SELECT TOP 1 Media_link
    FROM Product_Media pm
    WHERE pm.Product_ID = p.Product_ID
    ORDER BY pm.Media_ID) AS Primary_Image_URL
FROM Product p
   INNER JOIN Category c ON p.Category_ID = c.Category_ID
   INNER JOIN [User] u ON p.Seller_ID = u.UserID
   INNER JOIN Campus cam ON u.CampusID = cam.CampusID;
GO


-- =====================================================
-- View 2: Order Transaction Details
-- =====================================================
CREATE VIEW vw_Order_Transaction_Details AS
SELECT
   o.OrderID,
   o.Order_Date,
   o.Quantity,
   o.Status AS Order_Status,
   p.Product_ID,
   p.Product_Name,
   c.Category_Name,
   p.Unit_price AS Product_Unit_Price,
   (p.Unit_price * o.Quantity) AS Calculated_Order_Total,
   seller.UserID AS Seller_ID,
   seller.User_Name AS Seller_Name,
   seller.Agg_Seller_Rating AS Seller_Rating,
   buyer.UserID AS Buyer_ID,
   buyer.User_Name AS Buyer_Name,
   e.EscrowID,
   e.Amount AS Escrow_Amount,
   e.Status AS Escrow_Status,
   e.Created_Date AS Payment_Date,
   e.Release_Date AS Payment_Released_Date,
   pp.Location_Name AS Pickup_Location,
   oc.Scheduled_Date AS Pickup_Date,
   oc.Scheduled_Time AS Pickup_Time,
   r.Rating_Value AS Buyer_Rating,
   r.Rating_Date,
   CASE WHEN d.Dispute_ID IS NOT NULL THEN 'YES' ELSE 'NO' END AS Has_Dispute
FROM [Order] o
   INNER JOIN Product p ON o.Product_ID = p.Product_ID
   INNER JOIN Category c ON p.Category_ID = c.Category_ID
   INNER JOIN [User] seller ON o.Seller_ID = seller.UserID
   INNER JOIN [User] buyer ON o.Buyer_ID = buyer.UserID
   INNER JOIN Escrow e ON o.OrderID = e.OrderID
   LEFT JOIN Order_Collection oc ON o.OrderID = oc.Order_ID
   LEFT JOIN Pickup_Point pp ON oc.Pickup_Point_ID = pp.PickupPointID
   LEFT JOIN Rating r ON o.OrderID = r.Order_ID
   LEFT JOIN Dispute d ON e.EscrowID = d.EscrowID;
GO


-- =====================================================
-- View 3: User Activity Summary
-- =====================================================
CREATE VIEW vw_User_Activity_Summary AS
SELECT
   u.UserID,
   u.User_Name,
   u.Email_ID,
   u.Phone_number,
   u.Verification_Status,
   u.Agg_Seller_Rating,
   cam.Campus_Name,
   COUNT(DISTINCT p.Product_ID) AS Total_Products_Listed,
   COUNT(DISTINCT CASE WHEN p.Product_Status = 'Active' THEN p.Product_ID END) AS Active_Listings,
   COUNT(DISTINCT CASE WHEN p.Product_Status = 'Sold' THEN p.Product_ID END) AS Products_Sold,
   COUNT(DISTINCT sell_order.OrderID) AS Orders_As_Seller,
   ISNULL(SUM(sell_escrow.Amount), 0) AS Total_Revenue_As_Seller,
   COUNT(DISTINCT buy_order.OrderID) AS Orders_As_Buyer,
   ISNULL(SUM(buy_escrow.Amount), 0) AS Total_Spent_As_Buyer,
   COUNT(DISTINCT rating_received.RatingID) AS Ratings_Received_Count,
   AVG(rating_received.Rating_Value) AS Avg_Rating_Received,
   COUNT(DISTINCT rating_given.RatingID) AS Ratings_Given_Count,
   COUNT(DISTINCT dispute.Dispute_ID) AS Disputes_Filed,
   DATEDIFF(DAY,
       (SELECT MIN(Created_date) FROM Product WHERE Seller_ID = u.UserID),
       GETDATE()
   ) AS Days_Since_First_Listing
FROM [User] u
   INNER JOIN Campus cam ON u.CampusID = cam.CampusID
   LEFT JOIN Product p ON u.UserID = p.Seller_ID
   LEFT JOIN [Order] sell_order ON u.UserID = sell_order.Seller_ID
   LEFT JOIN Escrow sell_escrow ON sell_order.OrderID = sell_escrow.OrderID
   LEFT JOIN [Order] buy_order ON u.UserID = buy_order.Buyer_ID
   LEFT JOIN Escrow buy_escrow ON buy_order.OrderID = buy_escrow.OrderID
   LEFT JOIN Rating rating_received ON u.UserID = rating_received.Rated_UserID
   LEFT JOIN Rating rating_given ON u.UserID = rating_given.Rater_UserID
   LEFT JOIN Dispute dispute ON u.UserID = dispute.FiledByUserID
GROUP BY
   u.UserID, u.User_Name, u.Email_ID, u.Phone_number,
   u.Verification_Status, u.Agg_Seller_Rating, cam.Campus_Name;
GO





-- DML Trigger: Escrow → Escrow_Audit_Logs

-- (Scenario 2 – “audit trigger runs” when status changes)

-- This trigger:
-- 	•	Fires on INSERT and UPDATE of Escrow.
-- 	•	If row is newly created → logs “Escrow Created”.
-- 	•	If Status changes → logs “Status Changed”.
-- 	•	Uses Performed_By_UserID = 1 (System Admin user) as the “system actor”.
-- 	•	If you want, you can later change it to some app-level user id.

-- =====================================================
-- Trigger: trg_Escrow_StatusAudit
-- Logs creation and status changes into Escrow_Audit_Logs
-- =====================================================
CREATE OR ALTER TRIGGER dbo.trg_Escrow_StatusAudit
ON dbo.Escrow
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Use System Admin (UserID = 1) as the performer for system-driven changes
    DECLARE @SystemUserID INT = 1;

    -- 1) Log newly created escrows (no matching row in deleted)
    INSERT INTO dbo.Escrow_Audit_Logs
        (Performed_By_UserID, Escrow_ID, [Timestamp], Field_Change, Old_status, New_status)
    SELECT
        @SystemUserID,
        i.EscrowID,
        GETDATE(),
        'Escrow Created',
        NULL,
        i.Status
    FROM inserted i
    LEFT JOIN deleted d ON i.EscrowID = d.EscrowID
    WHERE d.EscrowID IS NULL;

    -- 2) Log status changes on existing escrows
    INSERT INTO dbo.Escrow_Audit_Logs
        (Performed_By_UserID, Escrow_ID, [Timestamp], Field_Change, Old_status, New_status)
    SELECT
        @SystemUserID,
        i.EscrowID,
        GETDATE(),
        'Status Changed',
        d.Status,
        i.Status
    FROM inserted i
    JOIN deleted d ON i.EscrowID = d.EscrowID
    WHERE ISNULL(d.Status, '') <> ISNULL(i.Status, '');
END;
GO

-- Now, whenever your procedures update Escrow.Status (e.g., to 'Held' or 'Released'), this trigger automatically writes appropriate rows into Escrow_Audit_Logs, 
-- which matches your “audit trigger” description.