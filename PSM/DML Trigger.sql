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
