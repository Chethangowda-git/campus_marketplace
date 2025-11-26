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

