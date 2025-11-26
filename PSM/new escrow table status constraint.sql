-- =====================================================
-- Update Escrow status check constraint to include Dispute_Raised
-- =====================================================

-- Drop old constraint
ALTER TABLE dbo.Escrow
DROP CONSTRAINT CHK_Escrow_Status;
GO

-- Recreate with new allowed value
ALTER TABLE dbo.Escrow
ADD CONSTRAINT CHK_Escrow_Status
CHECK (Status IN (N'Held', N'Released', N'Refunded', N'Dispute_Raised'));
GO


-- =====================================================
-- Reflect dispute-raised state in Escrow data
-- Link some Escrow rows to active disputes
-- =====================================================
UPDATE dbo.Escrow
SET Status = N'Dispute_Raised'
WHERE EscrowID IN (4, 7, 10, 13);
GO
