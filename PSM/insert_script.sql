-- =====================================================
-- Data Insertion Script
-- Campus Marketplace System - Northeastern University
-- =====================================================

USE campus_marketplace;

-- =====================================================
-- Insert Categories (15 rows)
-- =====================================================
INSERT INTO Category (Category_Name) VALUES
('Electronics'),
('Textbooks'),
('Furniture'),
('Clothing'),
('Kitchen Appliances'),
('Sports Equipment'),
('Musical Instruments'),
('Art Supplies'),
('School Supplies'),
('Health & Beauty'),
('Bikes & Transportation'),
('Home Decor'),
('Gaming'),
('Photography'),
('Laboratory Equipment');

-- =====================================================
-- Insert Zipcode (15 rows)
-- These represent various Boston-area zipcodes for future expansion
-- Currently all pickup points use 02115, but this provides flexibility
-- =====================================================
INSERT INTO Zipcode (Zipcode, City, State) VALUES
('02115', 'Boston', 'Massachusetts'),
('02120', 'Roxbury', 'Massachusetts'),
('02121', 'Dorchester', 'Massachusetts'),
('02125', 'Dorchester', 'Massachusetts'),
('02130', 'Jamaica Plain', 'Massachusetts'),
('02134', 'Allston', 'Massachusetts'),
('02135', 'Brighton', 'Massachusetts'),
('02138', 'Cambridge', 'Massachusetts'),
('02139', 'Cambridge', 'Massachusetts'),
('02140', 'Cambridge', 'Massachusetts'),
('02141', 'Cambridge', 'Massachusetts'),
('02142', 'Cambridge', 'Massachusetts'),
('02143', 'Somerville', 'Massachusetts'),
('02144', 'Somerville', 'Massachusetts'),
('02145', 'Somerville', 'Massachusetts');

-- =====================================================
-- Insert Campus (1 row - Northeastern University)
-- System is currently scoped to a single campus
-- =====================================================
INSERT INTO Campus (CampusID, Campus_Name, Street, Zipcode) VALUES
(1, 'Northeastern University', '360 Huntington Avenue', '02115');

-- =====================================================
-- Insert User_Lookup (15 rows)
-- These must exist before inserting into [User] due to FK on Email_ID
-- =====================================================
INSERT INTO User_Lookup (Neu_Email, Expected_User_Name) VALUES
('admin@northeastern.edu',       'System Admin'),
('johnson.sa@northeastern.edu',  'Sarah Johnson'),
('chen.m@northeastern.edu',      'Michael Chen'),
('rodriguez.e@northeastern.edu', 'Emily Rodriguez'),
('kim.d@northeastern.edu',       'David Kim'),
('williams.j@northeastern.edu',  'Jessica Williams'),
('thompson.r@northeastern.edu',  'Ryan Thompson'),
('martinez.a@northeastern.edu',  'Amanda Martinez'),
('lee.c@northeastern.edu',       'Christopher Lee'),
('brown.a@northeastern.edu',     'Ashley Brown'),
('garcia.d@northeastern.edu',    'Daniel Garcia'),
('davis.o@northeastern.edu',     'Olivia Davis'),
('wilson.m@northeastern.edu',    'Matthew Wilson'),
('anderson.s@northeastern.edu',  'Sophia Anderson'),
('taylor.j@northeastern.edu',    'James Taylor');

-- =====================================================
-- Insert Users (15 rows - First user is admin)
-- Note: User table is quoted because USER is a MySQL reserved word
-- Includes [Password] column as per updated DDL
-- =====================================================
INSERT INTO [User] (CampusID, User_Name, Verification_Status, Phone_number, [Password], Agg_Seller_Rating, Email_ID) VALUES
(1, 'System Admin',      'Verified', '+1-617-373-2000', 'Admin@123',      5.00, 'admin@northeastern.edu'),
(1, 'Sarah Johnson',     'Verified', '+1-617-555-0101', 'Password1!',     4.85, 'johnson.sa@northeastern.edu'),
(1, 'Michael Chen',      'Verified', '+1-617-555-0102', 'Password1!',     4.92, 'chen.m@northeastern.edu'),
(1, 'Emily Rodriguez',   'Verified', '+1-617-555-0103', 'Password1!',     4.78, 'rodriguez.e@northeastern.edu'),
(1, 'David Kim',         'Pending',  '+1-617-555-0104', 'Password1!',     0.00, 'kim.d@northeastern.edu'),
(1, 'Jessica Williams',  'Verified', '+1-617-555-0105', 'Password1!',     4.88, 'williams.j@northeastern.edu'),
(1, 'Ryan Thompson',     'Verified', '+1-617-555-0106', 'Password1!',     4.65, 'thompson.r@northeastern.edu'),
(1, 'Amanda Martinez',   'Verified', '+1-617-555-0107', 'Password1!',     4.95, 'martinez.a@northeastern.edu'),
(1, 'Christopher Lee',   'Verified', '+1-617-555-0108', 'Password1!',     4.72, 'lee.c@northeastern.edu'),
(1, 'Ashley Brown',      'Pending',  '+1-617-555-0109', 'Password1!',     0.00, 'brown.a@northeastern.edu'),
(1, 'Daniel Garcia',     'Verified', '+1-617-555-0110', 'Password1!',     4.81, 'garcia.d@northeastern.edu'),
(1, 'Olivia Davis',      'Verified', '+1-617-555-0111', 'Password1!',     4.89, 'davis.o@northeastern.edu'),
(1, 'Matthew Wilson',    'Verified', '+1-617-555-0112', 'Password1!',     4.76, 'wilson.m@northeastern.edu'),
(1, 'Sophia Anderson',   'Verified', '+1-617-555-0113', 'Password1!',     4.93, 'anderson.s@northeastern.edu'),
(1, 'James Taylor',      'Verified', '+1-617-555-0114', 'Password1!',     4.68, 'taylor.j@northeastern.edu');

-- =====================================================
-- Insert Pickup Points (15 rows)
-- All currently on NEU campus (CampusID=1) using zipcode 02115
-- =====================================================
INSERT INTO Pickup_Point (Zipcode, CampusID, Location_Name, Street) VALUES
('02115', 1, 'Curry Student Center', '346 Huntington Avenue'),
('02115', 1, 'Snell Library Main Entrance', '360 Huntington Avenue'),
('02115', 1, 'Marino Recreation Center', '369 Huntington Avenue'),
('02115', 1, 'International Village', '1155 Tremont Street'),
('02115', 1, 'West Village F', '440 Huntington Avenue'),
('02115', 1, 'Ryder Hall Lobby', '11 Leon Street'),
('02115', 1, 'Forsyth Building Entrance', '360 Huntington Avenue'),
('02115', 1, 'Hurtig Hall Main Entrance', '334 Nightingale Hall'),
('02115', 1, 'Churchill Hall Reception', '380 Huntington Avenue'),
('02115', 1, 'Hayden Hall Lounge', '370 Huntington Avenue'),
('02115', 1, 'Ell Hall Front Desk', '346 Huntington Avenue'),
('02115', 1, 'Richards Hall Lobby', '360 Huntington Avenue'),
('02115', 1, 'Behrakis Health Sciences Center', '360 Huntington Avenue'),
('02115', 1, 'Shillman Hall Entrance', '115 Forsyth Street'),
('02115', 1, 'Mugar Life Sciences Building', '360 Huntington Avenue');

-- =====================================================
-- Insert Products (15 rows)
-- Product_Status must be: 'Active', 'Sold', or 'Inactive'
-- =====================================================
INSERT INTO Product (Category_ID, Seller_ID, Product_Name, Description, Standard_price, Unit_price, Quantity, Product_Status, Created_date) VALUES
(1, 2, 'MacBook Air M2 2023', 'Lightly used MacBook Air with M2 chip, 8GB RAM, 256GB SSD. Excellent condition with original charger and box.', 1199.99, 899.99, 1, 'Active', '2024-09-15'),
(2, 3, 'Calculus Early Transcendentals 9th Ed', 'James Stewart calculus textbook for MATH 1341. Like new condition, no highlighting or writing inside.', 299.99, 149.99, 1, 'Active', '2024-09-20'),
(3, 2, 'IKEA Study Desk with Drawer', 'White study desk in great condition. Perfect for dorm room. Dimensions: 47x23 inches. Easy to assemble.', 129.99, 75.00, 1, 'Active', '2024-10-01'),
(4, 6, 'North Face Winter Jacket', 'Black North Face parka, size medium. Warm and waterproof. Worn only one season. Perfect for Boston winters.', 249.99, 120.00, 1, 'Active', '2024-10-10'),
(5, 8, 'Keurig Coffee Maker K-Elite', 'Single serve coffee maker with multiple brew sizes. Includes 20 K-cups. Barely used, works perfectly.', 169.99, 85.00, 1, 'Active', '2024-10-12'),
(6, 7, 'Tennis Racket Wilson Pro Staff', 'Professional grade tennis racket with carry case. Great condition, recently restrung. Grip size 4 3/8.', 199.99, 95.00, 1, 'Sold', '2024-09-25'),
(7, 11, 'Yamaha Acoustic Guitar FG800', 'Beautiful sounding acoustic guitar perfect for beginners or intermediate players. Includes soft case and tuner.', 299.99, 180.00, 1, 'Active', '2024-10-05'),
(8, 12, 'Professional Art Supply Set', 'Complete art supply kit with watercolors, brushes, pencils, and sketchbook. Perfect for studio classes.', 89.99, 55.00, 1, 'Active', '2024-10-08'),
(9, 3, 'Scientific Calculator TI-84 Plus', 'Texas Instruments graphing calculator required for engineering courses. Excellent working condition.', 129.99, 75.00, 1, 'Active', '2024-09-18'),
(10, 14, 'Skincare Bundle Korean Beauty', 'Unopened Korean skincare products including cleanser, toner, serum, and moisturizer. Retail value over $150.', 159.99, 89.99, 1, 'Active', '2024-10-15'),
(11, 6, 'Schwinn Hybrid Bike 700c', 'Reliable commuter bike with 21-speed gears. Includes lock and lights. Perfect for getting around campus.', 349.99, 220.00, 1, 'Active', '2024-09-28'),
(12, 8, 'Bohemian Tapestry Wall Hanging', 'Large decorative tapestry, 60x80 inches. Perfect for dorm room decoration. Machine washable.', 39.99, 22.00, 2, 'Active', '2024-10-11'),
(13, 13, 'PlayStation 5 Controller DualSense', 'White PS5 controller in excellent condition. Barely used, no drift issues. Includes charging cable.', 69.99, 45.00, 1, 'Active', '2024-10-14'),
(14, 11, 'Canon EOS Rebel T7 Camera Kit', 'DSLR camera with 18-55mm lens, battery, charger, and camera bag. Great for photography students.', 549.99, 380.00, 1, 'Active', '2024-10-03'),
(15, 14, 'Laboratory Safety Goggles Set', 'Pack of 3 ANSI-certified safety goggles for chemistry and biology labs. Brand new, never used.', 29.99, 18.00, 3, 'Active', '2024-10-09');

-- =====================================================
-- Insert Product Media (15 rows)
-- =====================================================
INSERT INTO Product_Media (Product_ID, Media_link, Media_Type) VALUES
(1, 'https://cdn.marketplace.neu.edu/products/macbook-air-m2-front.jpg', 'image/jpeg'),
(2, 'https://cdn.marketplace.neu.edu/products/calculus-textbook-cover.jpg', 'image/jpeg'),
(3, 'https://cdn.marketplace.neu.edu/products/ikea-desk-white.jpg', 'image/jpeg'),
(4, 'https://cdn.marketplace.neu.edu/products/northface-jacket-black.jpg', 'image/jpeg'),
(5, 'https://cdn.marketplace.neu.edu/products/keurig-elite-silver.jpg', 'image/jpeg'),
(6, 'https://cdn.marketplace.neu.edu/products/wilson-tennis-racket.jpg', 'image/jpeg'),
(7, 'https://cdn.marketplace.neu.edu/products/yamaha-guitar-fg800.jpg', 'image/jpeg'),
(8, 'https://cdn.marketplace.neu.edu/products/art-supply-set-complete.jpg', 'image/jpeg'),
(9, 'https://cdn.marketplace.neu.edu/products/ti84-calculator-graphing.jpg', 'image/jpeg'),
(10, 'https://cdn.marketplace.neu.edu/products/korean-skincare-bundle.jpg', 'image/jpeg'),
(11, 'https://cdn.marketplace.neu.edu/products/schwinn-hybrid-bike-blue.jpg', 'image/jpeg'),
(12, 'https://cdn.marketplace.neu.edu/products/bohemian-tapestry-large.jpg', 'image/jpeg'),
(13, 'https://cdn.marketplace.neu.edu/products/ps5-controller-white.jpg', 'image/jpeg'),
(14, 'https://cdn.marketplace.neu.edu/products/canon-t7-camera-kit.jpg', 'image/jpeg'),
(15, 'https://cdn.marketplace.neu.edu/products/lab-goggles-safety-set.jpg', 'image/jpeg');

-- =====================================================
-- Insert Orders (15 rows)
-- Status must be: 'Confirmed', 'Delivered', or 'Cancelled'
-- =====================================================
INSERT INTO [Order] (Product_ID, Seller_ID, Buyer_ID, Order_Date, Quantity, Status) VALUES
(1, 2, 9,  '2024-10-20', 1, 'Delivered'),
(2, 3, 5,  '2024-10-22', 1, 'Delivered'),
(3, 2, 7,  '2024-10-18', 1, 'Delivered'),
(4, 6, 10, '2024-10-25', 1, 'Confirmed'),
(5, 8, 4,  '2024-10-23', 1, 'Delivered'),
(6, 7, 15, '2024-10-15', 1, 'Delivered'),
(7, 11, 9, '2024-10-19', 1, 'Confirmed'),
(8, 12, 13,'2024-10-21', 1, 'Delivered'),
(9, 3, 6,  '2024-10-17', 1, 'Delivered'),
(10, 14, 2,'2024-10-26', 1, 'Confirmed'),
(11, 6, 12,'2024-10-16', 1, 'Delivered'),
(12, 8, 11,'2024-10-24', 2, 'Delivered'),
(13, 13, 7,'2024-10-27', 1, 'Confirmed'),
(14, 11, 14,'2024-10-19', 1, 'Delivered'),
(15, 14, 3,'2024-10-22', 2, 'Delivered');

-- =====================================================
-- Insert Escrow (15 rows)
-- Status must be: 'Held', 'Released', 'Refunded', or 'Dispute_Raised'
-- UNIQUE constraint enforces 1-to-1 relationship with Order
-- =====================================================
INSERT INTO Escrow (OrderID, Amount, Status, Created_Date, Release_Date) VALUES
(1,  899.99, 'Released',       '2024-10-20 14:30:00', '2024-10-28 10:15:00'),
(2,  149.99, 'Released',       '2024-10-22 09:45:00', '2024-10-29 16:20:00'),
(3,   75.00, 'Released',       '2024-10-18 11:20:00', '2024-10-25 14:30:00'),
(4,  120.00, 'Dispute_Raised', '2024-10-25 16:00:00', NULL),
(5,   85.00, 'Released',       '2024-10-23 10:30:00', '2024-10-30 09:45:00'),
(6,   95.00, 'Released',       '2024-10-15 13:15:00', '2024-10-22 11:00:00'),
(7,  180.00, 'Dispute_Raised', '2024-10-19 15:45:00', NULL),
(8,   55.00, 'Released',       '2024-10-21 12:00:00', '2024-10-28 15:30:00'),
(9,   75.00, 'Released',       '2024-10-17 14:20:00', '2024-10-24 10:45:00'),
(10,  89.99, 'Dispute_Raised', '2024-10-26 11:30:00', NULL),
(11, 220.00, 'Released',       '2024-10-16 09:00:00', '2024-10-23 13:15:00'),
(12,  44.00, 'Released',       '2024-10-24 16:30:00', '2024-10-31 12:00:00'),
(13,  45.00, 'Dispute_Raised', '2024-10-27 10:15:00', NULL),
(14, 380.00, 'Released',       '2024-10-19 13:45:00', '2024-10-26 16:30:00'),
(15,  36.00, 'Released',       '2024-10-22 15:00:00', '2024-10-29 11:20:00');

-- =====================================================
-- Insert Escrow Verification (sample rows)
-- One row per order, verification codes are 6-digit and globally unique
-- =====================================================
INSERT INTO Escrow_Verification
    (OrderID, Buyer_UserID, Seller_UserID, Buyer_Name, Verification_Code, Generated_At, Is_Used)
VALUES
(4,  10,  6, 'Ashley Brown',      '100001', '2024-10-25 16:05:00', 0),
(7,   9, 11, 'Christopher Lee',   '100002', '2024-10-19 15:50:00', 0),
(10,  2, 14, 'Sarah Johnson',     '100003', '2024-10-26 11:35:00', 0);

-- =====================================================
-- Insert Ratings (15 rows)
-- UNIQUE constraint enforces: one rating per order
-- Only buyers rate the sellers (enforced by composite FK)
-- =====================================================
INSERT INTO Rating (Order_ID, Rater_UserID, Rated_UserID, Rating_Value, Rating_Date) VALUES
-- Order 1: Buyer(9) rates Seller(2)
(1, 9, 2, 5.00, '2024-10-28'),
-- Order 2: Buyer(5) rates Seller(3)
(2, 5, 3, 4.80, '2024-10-29'),
-- Order 3: Buyer(7) rates Seller(2)
(3, 7, 2, 4.90, '2024-10-25'),
-- Order 4: Buyer(10) rates Seller(6)
(4, 10, 6, 4.75, '2024-10-26'),
-- Order 5: Buyer(4) rates Seller(8)
(5, 4, 8, 5.00, '2024-10-30'),
-- Order 6: Buyer(15) rates Seller(7)
(6, 15, 7, 4.50, '2024-10-22'),
-- Order 7: Buyer(9) rates Seller(11)
(7, 9, 11, 4.85, '2024-10-20'),
-- Order 8: Buyer(13) rates Seller(12)
(8, 13, 12, 4.70, '2024-10-28'),
-- Order 9: Buyer(6) rates Seller(3)
(9, 6, 3, 4.90, '2024-10-24'),
-- Order 10: Buyer(2) rates Seller(14)
(10, 2, 14, 4.95, '2024-10-27'),
-- Order 11: Buyer(12) rates Seller(6)
(11, 12, 6, 4.80, '2024-10-23'),
-- Order 12: Buyer(11) rates Seller(8)
(12, 11, 8, 5.00, '2024-10-31'),
-- Order 13: Buyer(7) rates Seller(13)
(13, 7, 13, 4.65, '2024-10-28'),
-- Order 14: Buyer(14) rates Seller(11)
(14, 14, 11, 4.90, '2024-10-26'),
-- Order 15: Buyer(3) rates Seller(14)
(15, 3, 14, 4.60, '2024-10-29');

-- =====================================================
-- Insert Product Audit Logs (15 rows)
-- =====================================================
INSERT INTO Product_Audit_Logs (Performed_By_UserID, Product_ID, Timestamp, Field_Change, Old_value, New_value) VALUES
(2,  1, '2024-09-15 10:00:00', 'Product Created',  NULL, 'Initial creation'),
(3,  2, '2024-09-20 14:30:00', 'Product Created',  NULL, 'Initial creation'),
(2,  3, '2024-10-01 09:15:00', 'Product Created',  NULL, 'Initial creation'),
(2,  1, '2024-10-18 11:45:00', 'Price Updated',    '949.99', '899.99'),
(6,  4, '2024-10-10 16:20:00', 'Product Created',  NULL, 'Initial creation'),
(7,  6, '2024-10-15 13:30:00', 'Status Changed',   'Active', 'Sold'),
(8,  5, '2024-10-12 10:45:00', 'Product Created',  NULL, 'Initial creation'),
(11, 7, '2024-10-05 15:00:00', 'Product Created',  NULL, 'Initial creation'),
(12, 8, '2024-10-08 11:30:00', 'Product Created',  NULL, 'Initial creation'),
(3,  2, '2024-10-19 14:00:00', 'Description Updated',
     'James Stewart calculus textbook.', 
     'James Stewart calculus textbook for MATH 1341. Like new condition, no highlighting or writing inside.'),
(14, 10, '2024-10-15 09:30:00', 'Product Created', NULL, 'Initial creation'),
(6,  11, '2024-09-28 12:00:00', 'Product Created', NULL, 'Initial creation'),
(8,  12, '2024-10-11 16:45:00', 'Product Created', NULL, 'Initial creation'),
(13, 13, '2024-10-14 10:20:00', 'Product Created', NULL, 'Initial creation'),
(11, 14, '2024-10-03 13:15:00', 'Product Created', NULL, 'Initial creation');

-- =====================================================
-- Insert Escrow Audit Logs (15 rows)
-- (Updated rows for EscrowID 4 and 7 to use Dispute_Raised)
-- =====================================================
INSERT INTO Escrow_Audit_Logs (Performed_By_UserID, Escrow_ID, Timestamp, Field_Change, Old_status, New_status) VALUES
(1, 1, '2024-10-20 14:30:00', 'Escrow Created',  NULL,   'Held'),
(1, 1, '2024-10-28 10:15:00', 'Status Changed', 'Held',  'Released'),
(1, 2, '2024-10-22 09:45:00', 'Escrow Created',  NULL,   'Held'),
(1, 2, '2024-10-29 16:20:00', 'Status Changed', 'Held',  'Released'),
(1, 3, '2024-10-18 11:20:00', 'Escrow Created',  NULL,   'Held'),
(1, 3, '2024-10-25 14:30:00', 'Status Changed', 'Held',  'Released'),
(1, 4, '2024-10-25 16:00:00', 'Escrow Created',  NULL,   'Dispute_Raised'),
(1, 5, '2024-10-23 10:30:00', 'Escrow Created',  NULL,   'Held'),
(1, 5, '2024-10-30 09:45:00', 'Status Changed', 'Held',  'Released'),
(1, 6, '2024-10-15 13:15:00', 'Escrow Created',  NULL,   'Held'),
(1, 6, '2024-10-22 11:00:00', 'Status Changed', 'Held',  'Released'),
(1, 7, '2024-10-19 15:45:00', 'Escrow Created',  NULL,   'Dispute_Raised'),
(1, 8, '2024-10-21 12:00:00', 'Escrow Created',  NULL,   'Held'),
(1, 8, '2024-10-28 15:30:00', 'Status Changed', 'Held',  'Released'),
(1, 9, '2024-10-17 14:20:00', 'Escrow Created',  NULL,   'Held');

-- =====================================================
-- Insert Disputes (15 rows)
-- Status must be: 'Open', 'In Progress', 'Resolved', or 'Closed'
-- (Some map naturally to Escrow rows with Dispute_Raised)
-- =====================================================
INSERT INTO Dispute (EscrowID, FiledByUserID, Description, Open_Date, Resolution_Details, Resolved_Date, Status) VALUES
(1,  9,  'MacBook screen has minor scratches not mentioned in description', '2024-10-27', 'Seller provided partial refund of $50. Buyer satisfied with resolution.', '2024-10-28', 'Resolved'),
(2,  5,  'Book has water damage on several pages',                             '2024-10-28', 'Full refund issued. Buyer returned the book.',                            '2024-10-29', 'Resolved'),
(3,  7,  'Desk leg is slightly wobbly',                                        '2024-10-24', 'Seller agreed to help fix the issue. Buyer accepted solution.',          '2024-10-25', 'Resolved'),
(4,  10, 'Jacket has small stain on sleeve',                                   '2024-10-26', NULL,                                                                     NULL,        'Open'),
(5,  4,  'Coffee maker missing water filter',                                  '2024-10-29', 'Seller provided replacement filter. Issue resolved.',                    '2024-10-30', 'Resolved'),
(6,  15, 'Tennis racket strings are older than described',                     '2024-10-21', 'Partial refund of $15 provided for restringing cost.',                  '2024-10-22', 'Resolved'),
(7,  9,  'Guitar case has broken zipper',                                      '2024-10-20', NULL,                                                                     NULL,        'In Progress'),
(8,  13, 'Art supply set missing two brushes',                                 '2024-10-27', 'Seller apologized and provided $10 refund. Case closed.',               '2024-10-28', 'Resolved'),
(9,  6,  'Calculator battery cover is cracked',                                '2024-10-23', 'Seller provided new battery cover. Buyer satisfied.',                   '2024-10-24', 'Resolved'),
(10, 2,  'One skincare product expires in 2 months',                           '2024-10-27', NULL,                                                                     NULL,        'Open'),
(11, 12, 'Bike front brake needs adjustment',                                  '2024-10-22', 'Seller met buyer and fixed brakes on-site. Resolved amicably.',         '2024-10-23', 'Resolved'),
(12, 11, 'Tapestry has small hole in corner',                                  '2024-10-30', 'Partial refund of $5 issued. Buyer kept item.',                         '2024-10-31', 'Resolved'),
(13, 7,  'Controller has slight stick drift',                                  '2024-10-28', NULL,                                                                     NULL,        'Open'),
(14, 14, 'Camera lens has dust inside',                                        '2024-10-25', 'Professional cleaning arranged by seller. Issue resolved.',             '2024-10-26', 'Resolved'),
(15, 3,  'Safety goggles packaging was opened',                                '2024-10-28', 'Seller explained quality check process. Buyer accepted explanation.',   '2024-10-29', 'Resolved');

-- =====================================================
-- Insert Dispute Evidence (15 rows)
-- =====================================================
INSERT INTO Dispute_Evidence (Dispute_ID, Media_link, Media_Type) VALUES
(1,  'https://cdn.disputes.neu.edu/evidence/macbook-screen-scratch-closeup.jpg',  'image/jpeg'),
(2,  'https://cdn.disputes.neu.edu/evidence/textbook-water-damage-pages.jpg',      'image/jpeg'),
(3,  'https://cdn.disputes.neu.edu/evidence/desk-wobbly-leg-video.mp4',            'video/mp4'),
(4,  'https://cdn.disputes.neu.edu/evidence/jacket-sleeve-stain-photo.jpg',       'image/jpeg'),
(5,  'https://cdn.disputes.neu.edu/evidence/keurig-missing-filter-photo.jpg',     'image/jpeg'),
(6,  'https://cdn.disputes.neu.edu/evidence/racket-old-strings-closeup.jpg',      'image/jpeg'),
(7,  'https://cdn.disputes.neu.edu/evidence/guitar-case-broken-zipper.jpg',       'image/jpeg'),
(8,  'https://cdn.disputes.neu.edu/evidence/art-supplies-missing-brushes.jpg',    'image/jpeg'),
(9,  'https://cdn.disputes.neu.edu/evidence/calculator-cracked-cover.jpg',        'image/jpeg'),
(10, 'https://cdn.disputes.neu.edu/evidence/skincare-expiry-date-label.jpg',      'image/jpeg'),
(11, 'https://cdn.disputes.neu.edu/evidence/bike-brake-issue-video.mp4',          'video/mp4'),
(12, 'https://cdn.disputes.neu.edu/evidence/tapestry-hole-corner-photo.jpg',      'image/jpeg'),
(13, 'https://cdn.disputes.neu.edu/evidence/controller-drift-demonstration.mp4',  'video/mp4'),
(14, 'https://cdn.disputes.neu.edu/evidence/camera-lens-dust-macro.jpg',          'image/jpeg'),
(15, 'https://cdn.disputes.neu.edu/evidence/goggles-opened-packaging.jpg',        'image/jpeg');

-- =====================================================
-- Insert Order Collections (15 rows)
-- UNIQUE constraint enforces 1-to-1 relationship with Order
-- =====================================================
INSERT INTO Order_Collection (Order_ID, Pickup_Point_ID, Scheduled_Time, Scheduled_Date) VALUES
(1,  1,  '14:00:00', '2024-10-28'),
(2,  2,  '10:30:00', '2024-10-29'),
(3,  3,  '15:00:00', '2024-10-25'),
(4,  4,  NULL,       NULL),
(5,  5,  '11:00:00', '2024-10-30'),
(6,  6,  '16:30:00', '2024-10-22'),
(7,  7,  NULL,       NULL),
(8,  8,  '13:00:00', '2024-10-28'),
(9,  9,  '09:30:00', '2024-10-24'),
(10, 10, NULL,       NULL),
(11, 11, '12:00:00', '2024-10-23'),
(12, 12, '17:00:00', '2024-10-31'),
(13, 13, NULL,       NULL),
(14, 14, '14:30:00', '2024-10-26'),
(15, 15, '10:00:00', '2024-10-29');

-- =====================================================
-- Data Insertion Complete
-- =====================================================