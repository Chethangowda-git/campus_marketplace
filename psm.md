Campus Marketplace – Database & PSM Setup Guide

This document explains how to set up the campus_marketplace SQL Server database, what each .sql file does, and how to prove that:
	1.	Encryption objects are created.
	2.	The verification-code UDF works.
	3.	Stored procedures compile and run with test data.

⸻

1. Tech Stack & Assumptions
	•	Database: Microsoft SQL Server
	•	Scope: Single campus (Northeastern University), student-to-student marketplace
	•	Key PSM features covered:
	•	Normalized schema with constraints + indexes
	•	Column-level encryption (keys, certs, encrypted columns)
	•	Lookup table & strict FK constraints
	•	UDFs (masking, ratings, verification code formatting)
	•	DML triggers (audit logs, aggregate rating maintenance)
	•	Stored procedures with transactions, TRY/CATCH, input/output params

⸻

2. Files & What They Do

2.1 Core Schema & Data

ddl.sql
Creates the entire schema:
	•	Drops and recreates the database:
	•	DROP DATABASE IF EXISTS campus_marketplace;
	•	CREATE DATABASE campus_marketplace;
	•	Creates all core tables:
	•	Category, Zipcode, Campus
	•	[User] (students / marketplace users)
	•	Pickup_Point (meetup locations)
	•	Product, Product_Media
	•	[Order]
	•	Escrow
	•	Rating
	•	Product_Audit_Logs
	•	Escrow_Audit_Logs
	•	Dispute, Dispute_Evidence
	•	Order_Collection
	•	Adds constraints:
	•	PKs, FKs, CHECK constraints (status, rating ranges, price > 0, etc.)
	•	Composite unique indexes for (OrderID, Buyer_ID) and (OrderID, Seller_ID) to support Rating FKs.

Result: A consistent, relational schema for the campus marketplace with escrow, disputes, audits, and ratings.

dml.sql
Inserts sample data for demo/testing:
	•	15 Categories
	•	15 Zipcodes (Boston/Cambridge/Somerville etc.)
	•	1 Campus (NEU)
	•	15 Users (first user = System Admin)
	•	15 Pickup points (NEU locations like Curry, Snell, Marino, etc.)
	•	15 Products (MacBook, textbooks, bikes, etc.)
	•	15 Product_Media rows
	•	15 Orders
	•	15 Escrow records
	•	15 Ratings
	•	15 Product_Audit_Logs
	•	15 Escrow_Audit_Logs
	•	15 Disputes + 15 Dispute_Evidence
	•	15 Order_Collection rows

Result: Database is populated with realistic sample data that exercises all relationships.

⸻

2.2 Encryption & Sensitive Columns

encryption_setup.sql
Sets up the encryption infrastructure inside campus_marketplace:
	1.	Database Master Key (if not already present)
	2.	Certificate: UserDataEncryptionCert
	3.	Symmetric Key: UserDataSymKey (AES_256) encrypted by the certificate

Purpose: Used to encrypt/decrypt sensitive user columns (passwords, phone numbers).

user_pw_pn_encrypted_columns.sql
Adds encrypted storage columns to dbo.[User]:
	•	Encrypted_Password VARBINARY(MAX)
	•	Encrypted_Phone VARBINARY(MAX)
	•	Optionally drops plain-text [Password] column if it exists.

Result: At-rest sensitive data (password, phone) is stored in encrypted form rather than plain text.

⸻

2.3 Lookup / Whitelisting

lookup table.sql
Implements a whitelist / lookup table for NEU users:
	•	Creates dbo.User_Lookup:
	•	LookupID (PK)
	•	Neu_Email (UNIQUE)
	•	Expected_User_Name
	•	Seeds it from existing [User] rows.
	•	Adds FK on [User].Email_ID → User_Lookup.Neu_Email (if not already present), with ON UPDATE CASCADE.

Result: Each user must exist in the NEU whitelist; enforces 1–1 mapping via email and supports controlled onboarding.

Note: dummy.sql contains an older, two-step version (populate → add FK). The final, idempotent version is lookup table.sql.

⸻

2.4 Escrow Verification Flow

escroverification tables.sql
Creates dbo.Escrow_Verification:
	•	One row per order (OrderID PK).
	•	Stores:
	•	Buyer_UserID, Seller_UserID, Buyer_Name
	•	Verification_Code CHAR(6)
	•	Generated_At, Is_Used
	•	Enforces global uniqueness of Verification_Code via UNIQUE constraint.

Purpose: Temporary store of 6-digit verification codes used when buyer and seller meet in person before releasing escrow.

new escrow table constraint.sql
Updates Escrow status logic:
	•	Drops old CHK_Escrow_Status.
	•	Recreates it including N'Dispute_Raised':
	•	Valid statuses: 'Held', 'Released', 'Refunded', 'Dispute_Raised'
	•	Updates some existing Escrow rows to Status = 'Dispute_Raised'.

Result: Escrow can explicitly represent a “dispute raised” state tied to the Dispute table.

⸻

2.5 Indexes

indexes.sql
Adds nonclustered indexes and some unique indexes:
	•	User: IX_User_Campus
	•	Pickup_Point: IX_Pickup_Point_Zipcode, IX_Pickup_Point_Campus
	•	Product: IX_Product_Category, IX_Product_Seller, IX_Product_Status
	•	Product_Media: IX_Product_Media_Product
	•	[Order]: IX_Order_Product, IX_Order_Seller, IX_Order_Buyer, IX_Order_Status
	•	Escrow: IX_Escrow_Order, IX_Escrow_Status
	•	Product_Audit_Logs: by Performed_By_UserID, Product_ID, [Timestamp]
	•	Escrow_Audit_Logs: by Performed_By_UserID, Escrow_ID, [Timestamp]
	•	Dispute: by EscrowID, FiledByUserID, Status
	•	Dispute_Evidence: IX_Dispute_Evidence_Dispute
	•	Order_Collection: by Order_ID, Pickup_Point_ID
	•	Ensures composite unique indexes:
	•	UQ_Order_OrderID_Buyer on (OrderID, Buyer_ID)
	•	UQ_Order_OrderID_Seller on (OrderID, Seller_ID)

Result: Better performance on common lookups and support for composite foreign keys in Rating.

⸻

2.6 UDFs & Rating Trigger

udf.sql
Contains two UDFs and one trigger:
	1.	dbo.ufn_MaskEmail(@Email)
	•	Masks the local part of email (e.g., john.doe@northeastern.edu → j*****e@northeastern.edu).
	•	Used for privacy-safe reporting.
	2.	dbo.ufn_GetSellerAverageRating(@SellerID)
	•	Returns average rating from Rating table for a given seller (Rated_UserID).
	•	If no rows, returns 0.00 (matches Agg_Seller_Rating default).
	3.	Trigger: dbo.trg_Rating_UpdateSellerAgg on dbo.Rating
	•	Fires on INSERT, UPDATE, DELETE.
	•	Finds all affected sellers from inserted and deleted.
	•	Recomputes [User].Agg_Seller_Rating via dbo.ufn_GetSellerAverageRating.

Result: Seller aggregates stay in sync automatically as ratings change.

udf generate verification code.sql
Defines dbo.ufn_FormatVerificationCode(@RandomInt):
	•	Pads an integer to 6 digits (000000–999999).
	•	Used as a helper for verification code generation (called from a generator UDF that returns CHAR(6)).

⸻

2.7 Escrow Audit Trigger

DML Triggers.sql
Defines trigger dbo.trg_Escrow_StatusAudit on dbo.Escrow:
	•	Fired on INSERT and UPDATE.
	•	Case 1: New row (no match in deleted):
	•	Inserts into Escrow_Audit_Logs with:
	•	Field_Change = 'Escrow Created'
	•	Old_status = NULL
	•	New_status = i.Status
	•	Case 2: Existing row where Status changed:
	•	Inserts Field_Change = 'Status Changed'
	•	Logs old and new status.
	•	Uses Performed_By_UserID = 1 as System Admin.

Result: Every creation and status change on Escrow is automatically audited.

⸻

2.8 User-Level Encryption Columns

user_pw_pn_encrypted_columns.sql
(Already discussed above) – adds Encrypted_Password and Encrypted_Phone and drops plain [Password] if present.

Security story:
	•	We use master key + certificate + symmetric key.
	•	Sensitive user data is stored in VARBINARY(MAX) encrypted columns, not as plain text.

⸻

2.9 Stored Procedures (End-to-End Flows)

stored procedures.sql
Implements three main stored procedures:
	1.	dbo.usp_CreateOrderWithCollection
Scenario: Buyer creates an order and schedules pickup.
	•	Inputs:
	•	@ProductID, @BuyerID, @Quantity,
	•	@PickupPointID, @ScheduledDate, @ScheduledTime
	•	Outputs:
	•	@NewOrderID (INT OUTPUT)
	•	@ResultCode (0 = success, 1 = validation error, 2 = other error)
	•	@ResultMessage (NVARCHAR(400))
	•	Behavior:
	•	Validates product and quantity.
	•	Inserts into [Order] with Status = 'Confirmed'.
	•	Inserts into Order_Collection.
	•	Uses explicit transaction + TRY/CATCH and gracefully sets output message.
	2.	dbo.usp_InitiateEscrowVerification
Scenario: Payment initiated, escrow held, verification code generated.
	•	Inputs:
	•	@OrderID
	•	Outputs:
	•	@VerificationCode CHAR(6) OUTPUT
	•	@ResultCode, @ResultMessage
	•	Behavior:
	•	Validates that order exists and escrow row exists.
	•	Sets Escrow.Status = 'Held'.
	•	If Escrow_Verification already has a row → returns existing code.
	•	Else:
	•	Calls dbo.ufn_GenerateVerificationCode() (uses ufn_FormatVerificationCode internally).
	•	Ensures global uniqueness against Escrow_Verification.Verification_Code.
	•	Inserts row into Escrow_Verification.
	•	Wraps everything in a transaction with TRY/CATCH.
	3.	dbo.usp_VerifyEscrowCodeAndCompletePayment
Scenario: Seller enters code at meetup; escrow is released.
	•	Inputs:
	•	@OrderID, @SellerID, @EnteredCode
	•	Outputs:
	•	@IsVerified BIT OUTPUT
	•	@ResultCode, @ResultMessage
	•	Behavior:
	•	Validates that a code exists for the order.
	•	Ensures seller matches the Seller_UserID in Escrow_Verification.
	•	Ensures code is not used and matches @EnteredCode.
	•	On success:
	•	Sets Escrow.Status = 'Released', Release_Date = GETDATE().
	•	Deletes Escrow_Verification row (code destroyed).
	•	Transaction + TRY/CATCH; sets result outputs accordingly.

Result: Complete escrow lifecycle:
	•	Order + pickup → escrow held + code generated → seller verifies code → escrow released and audited.

⸻

3. Recommended Execution Order

For a clean setup from scratch:
	1.	ddl.sql – create database and schema
	2.	dml.sql – insert sample data
	3.	encryption_setup.sql – master key, certificate, symmetric key
	4.	user_pw_pn_encrypted_columns.sql – encrypted columns
	5.	lookup table.sql – User_Lookup + FK
	6.	escroverification tables.sql – Escrow_Verification table
	7.	new escrow table constraint.sql – update escrow status constraint + data
	8.	indexes.sql – indexes and unique constraints
	9.	udf.sql – masking + rating UDF + rating trigger
	10.	udf generate verification code.sql – code formatting helper (and related generator if in this file)
	11.	DML Triggers.sql – Escrow audit trigger
	12.	stored procedures.sql – main business logic procs

After this, the database is ready for demo & testing.

⸻

4. Sample Queries to Prove PSM Features

4.1 Encryption objects exist
-- Symmetric key
SELECT name 
FROM sys.symmetric_keys
WHERE name = 'UserDataSymKey';

-- Certificate
SELECT name
FROM sys.certificates
WHERE name = 'UserDataEncryptionCert';

-- Encrypted columns on User table
SELECT name
FROM sys.columns
WHERE object_id = OBJECT_ID('dbo.[User]')
  AND name IN ('Encrypted_Password', 'Encrypted_Phone');

If these return rows, the encryption infrastructure is correctly set up.

4.2 UDF works and generates a verification code

Assuming the generator function is called dbo.ufn_GenerateVerificationCode():

SELECT dbo.ufn_GenerateVerificationCode() AS SampleVerificationCode;

You should get a 6-digit CHAR(6) value (e.g., 042319).

(If you want to test just the formatting helper:)
SELECT dbo.ufn_FormatVerificationCode(123) AS FormattedCode;
-- Expected: '000123'

4.3 Stored procedure compiles & runs with test data

Example: create an order + collection using sample data:
DECLARE 
    @NewOrderID    INT,
    @ResultCode    INT,
    @ResultMessage NVARCHAR(400);

EXEC dbo.usp_CreateOrderWithCollection
    @ProductID      = 1,        -- existing Product_ID from dml.sql
    @BuyerID        = 9,        -- existing UserID from dml.sql
    @Quantity       = 1,
    @PickupPointID  = 1,        -- existing PickupPointID from dml.sql
    @ScheduledDate  = '2024-11-01',
    @ScheduledTime  = '10:00',
    @NewOrderID     = @NewOrderID OUTPUT,
    @ResultCode     = @ResultCode OUTPUT,
    @ResultMessage  = @ResultMessage OUTPUT;

SELECT 
    @NewOrderID    AS NewOrderID,
    @ResultCode    AS ResultCode,
    @ResultMessage AS ResultMessage;

	•	If ResultCode = 0, procedure is working and the new rows will be visible in:
	•	[Order]
	•	Order_Collection

⸻

5. How to Use This as a Team
	•	For devs:
	•	Clone repo → open in SSMS / Azure Data Studio.
	•	Run scripts in the order in Section 3.
	•	Use Section 4 queries to quickly verify everything is wired correctly.
	•	For report / documentation:
	•	This file explains how PSM requirements are satisfied: encryption, UDFs, triggers, SPs, constraints, indexes.
	•	You can copy sections into the project report if needed.