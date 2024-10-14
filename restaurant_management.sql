

-- DROP AND CREATE TABLES IN THE DATABASE 

-- Create EMPLOYEE table
CREATE TABLE EMPLOYEE (
    eid INT AUTO_INCREMENT,
    firstName VARCHAR(25) NOT NULL,
    lastName VARCHAR(25) NOT NULL,
    position VARCHAR(25) NOT NULL,
    email VARCHAR(25) NOT NULL,
    lastWorked DATE,
    PRIMARY KEY (eid)
);

-- Create MENU table
CREATE TABLE MENU (
    mID INT AUTO_INCREMENT,
    itemName VARCHAR(50) UNIQUE NOT NULL,
    description VARCHAR(140) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    type VARCHAR(15) NOT NULL,
    PRIMARY KEY (mID)
);

-- Create CUSTOMER table
CREATE TABLE CUSTOMER (
    cid INT AUTO_INCREMENT,
    firstName VARCHAR(25) NOT NULL,
    lastName VARCHAR(25) NOT NULL,
    email VARCHAR(25) NOT NULL,
    discount INT DEFAULT 0,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    mid INT NOT NULL,
    PRIMARY KEY (cid),
    FOREIGN KEY (mid) REFERENCES MENU(mID)
);

-- Create ARC_CUSTOMER table
CREATE TABLE ARC_CUSTOMER (
    cid INT NOT NULL,
    firstName VARCHAR(25) NOT NULL,
    lastName VARCHAR(25) NOT NULL,
    email VARCHAR(25) NOT NULL,
    discount INT DEFAULT 0,
    updatedAt TIMESTAMP,
    mid INT NOT NULL,
    PRIMARY KEY (cid),
    FOREIGN KEY (mid) REFERENCES MENU(mID)
);

-- Create aTABLE table
CREATE TABLE aTABLE (
    tID INT AUTO_INCREMENT,
    eID INT,
    seats INT NOT NULL,
    available CHAR(1) NOT NULL,
    PRIMARY KEY (tID)
);

-- Create RATING table
CREATE TABLE RATING (
    cID INT NOT NULL,
    stars INT,
    feedback VARCHAR(140),
    PRIMARY KEY (cID),
    FOREIGN KEY (cID) REFERENCES CUSTOMER(cid)
);

-- Create RESERVATION table
CREATE TABLE RESERVATION (
    tID INT NOT NULL,
    cID INT NOT NULL,
    partySize INT NOT NULL,
    reservationDate DATE NOT NULL,
    PRIMARY KEY (tID, cID, reservationDate),
    FOREIGN KEY (tID) REFERENCES aTABLE(tID),
    FOREIGN KEY (cID) REFERENCES CUSTOMER(cid) ON DELETE CASCADE
);

-- Create ORDERS table
CREATE TABLE ORDERS (
    orderID INT AUTO_INCREMENT,
    cid INT,
    mid INT,
    orderDate DATE NOT NULL,
    quantity INT NOT NULL,
    PRIMARY KEY (orderID),
    FOREIGN KEY (cid) REFERENCES CUSTOMER(cid) ON DELETE CASCADE,
    FOREIGN KEY (mid) REFERENCES MENU(mID)
);

DROP TABLE IF EXISTS bill;
CREATE TABLE bill (
    cidb INT,
    midb INT,
    itemName VARCHAR(50),
    quantity INT,
    priceb DECIMAL(10,2),
    discountb INT,
    totalb DECIMAL(10,2)
);




-- ALL THE TRIGGERS 
    
-- Trigger to give discounts to customers who give 5-star ratings
DELIMITER $$
CREATE TRIGGER newHighRater
AFTER INSERT ON RATING
FOR EACH ROW
BEGIN
    IF NEW.stars = 5 THEN 
        UPDATE CUSTOMER SET discount = discount + 10 WHERE cid = NEW.cID;
    END IF;
END $$
DELIMITER ;

-- Trigger to maintain discounts for 5-star raters only
DELIMITER $$
CREATE TRIGGER ratingUpdate
AFTER UPDATE ON RATING
FOR EACH ROW
BEGIN
    IF OLD.stars = 5 AND NEW.stars <> 5 THEN
        UPDATE CUSTOMER SET discount = discount - 10 WHERE cid = NEW.cID;
    END IF;
    IF NEW.stars = 5 AND OLD.stars <> 5 THEN
        UPDATE CUSTOMER SET discount = discount + 10 WHERE cid = NEW.cID;
    END IF;
END $$
DELIMITER ;

-- Trigger to update updatedAt when reservation is made
DELIMITER $$
CREATE TRIGGER visiting
AFTER INSERT ON RESERVATION
FOR EACH ROW
BEGIN
    UPDATE CUSTOMER SET updatedAt = CURRENT_TIMESTAMP WHERE cid = NEW.cID;
END $$
DELIMITER ;

-- Trigger to update updatedAt when reservation is changed
DELIMITER $$
CREATE TRIGGER visitUpdate
AFTER UPDATE ON RESERVATION
FOR EACH ROW
BEGIN
    UPDATE CUSTOMER SET updatedAt = CURRENT_TIMESTAMP WHERE cid = NEW.cID;
END $$
DELIMITER ;


-- ALL THE STORED PROCEDURES 

-- Procedure to archive customers
DELIMITER $$
CREATE PROCEDURE archiveCustomers(IN oldDate DATE)
BEGIN
    INSERT INTO ARC_CUSTOMER SELECT * FROM CUSTOMER WHERE updatedAt < oldDate;
    DELETE FROM CUSTOMER WHERE updatedAt < oldDate;
END $$
DELIMITER ;

-- Temporary table for dates
DROP TABLE IF EXISTS dates;
CREATE TABLE dates(adate DATE);

-- Procedure to populate weekDates
DELIMITER $$
CREATE PROCEDURE weekDates()
BEGIN
    DECLARE tempdate DATE DEFAULT CURRENT_DATE;
    WHILE tempdate < CURRENT_DATE + INTERVAL 7 DAY DO
        INSERT INTO dates VALUES (tempdate);
        SET tempdate = tempdate + INTERVAL 1 DAY;
    END WHILE;
END $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE generateBill(IN customerId INT)
BEGIN
    -- Clear existing bill entries for the customer
    DELETE FROM bill WHERE cidb = customerId;

    -- Insert the order details into the bill table
    INSERT INTO bill (cidb, midb, itemName, quantity, priceb, discountb)
    SELECT O.cid, O.mid, M.itemName, O.quantity, M.price * O.quantity, C.discount
    FROM ORDERS O
    JOIN MENU M ON O.mid = M.mID
    JOIN CUSTOMER C ON O.cid = C.cid
    WHERE O.cid = customerId;

    -- Calculate total with discount
    CALL assigntotal();
END $$
DELIMITER ;


-- Create bill table
DROP TABLE IF EXISTS bill;
CREATE TABLE bill (
    cidb INT,
    midb INT,
    firstnameb VARCHAR(10),
    priceb DECIMAL(10,2),
    discountb INT,
    totalb DECIMAL(10,2)
);

-- Procedure to create the bill
-- Procedure to assign total bill amount
drop procedure assigntotal;
DELIMITER $$
CREATE PROCEDURE assigntotal()
BEGIN
    -- Declare variables
    DECLARE v_cidb INT;
    DECLARE v_midb INT;
    DECLARE v_quantity INT;
    DECLARE v_priceb DECIMAL(10,2);
    DECLARE v_discountb DECIMAL(10,2);
    DECLARE v_totalb DECIMAL(10,2);
    DECLARE done BOOLEAN DEFAULT FALSE;

    -- Declare a cursor
    DECLARE rec_cursor CURSOR FOR SELECT cidb, midb, priceb, quantity, discountb FROM bill;
    
    -- Declare a continue handler to set done variable when cursor reaches end
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Open the cursor
    OPEN rec_cursor;

    -- Loop through cursor
    read_loop: LOOP
        -- Fetch values from the cursor
        FETCH rec_cursor INTO v_cidb, v_midb, v_priceb, v_quantity, v_discountb;

        -- Exit loop if done
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Calculate total amount with discount applied
        SET v_totalb = (v_priceb * v_quantity) - v_discountb;

        -- Update the bill table with the calculated total
        UPDATE bill SET totalb = v_totalb WHERE cidb = v_cidb AND midb = v_midb;
    END LOOP;

    -- Close the cursor
    CLOSE rec_cursor;
END $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE placeOrder(IN customerId INT, IN menuId INT, IN orderQty INT)
BEGIN
    INSERT INTO ORDERS (cid, mid, orderDate, quantity) 
    VALUES (customerId, menuId, CURRENT_DATE, orderQty);
END $$
DELIMITER ;






-- INSERT ALL THE SAMPLE DATA

-- Insert sample employees
INSERT INTO EMPLOYEE (firstName, lastName, position, lastWorked, email) 
VALUES ('Satvik', 'Gupta', 'Server', CURRENT_DATE, 'satvik@gmail.com');

INSERT INTO EMPLOYEE (firstName, lastName, position, lastWorked, email) 
VALUES ('Saksham', 'Agarwal', 'Supervisor', CURRENT_DATE, 'saksham@gmail.com');

INSERT INTO EMPLOYEE (firstName, lastName, position, lastWorked, email) 
VALUES ('Rohan', 'Kumar', 'Manager', CURRENT_DATE - INTERVAL 2 DAY, 'rohan.kumar@gmail.com');

INSERT INTO EMPLOYEE (firstName, lastName, position, lastWorked, email) 
VALUES ('Neha', 'Sharma', 'Chef', CURRENT_DATE - INTERVAL 5 DAY, 'neha.sharma@gmail.com');

INSERT INTO EMPLOYEE (firstName, lastName, position, lastWorked, email) 
VALUES ('Aryan', 'Jain', 'Server', CURRENT_DATE - INTERVAL 10 DAY, 'aryan.jain@gmail.com');




-- Insert sample menu items
INSERT INTO MENU (itemName, description, price, type) 
VALUES ('Spring Rolls', 'A fresh spring rolls with pork and shrimp', 65, 'food');

INSERT INTO MENU (itemName, description, price, type) 
VALUES ('Chicken Biryani', 'Traditional spicy rice with chicken', 150, 'food');

INSERT INTO MENU (itemName, description, price, type) 
VALUES ('Butter Naan', 'Soft naan bread with butter', 25, 'food');

INSERT INTO MENU (itemName, description, price, type) 
VALUES ('Lemonade', 'Refreshing lemonade drink', 40, 'beverage');

INSERT INTO MENU (itemName, description, price, type) 
VALUES ('Gulab Jamun', 'Indian dessert made of milk solids', 50, 'dessert');


-- Add more menu items as needed...

-- Insert sample customers
INSERT INTO CUSTOMER (firstName, lastName, email, mid) 
VALUES ('Samiksha', 'Hooda', 'samiksha@gmail.com', 1);

INSERT INTO CUSTOMER (firstName, lastName, email, mid) 
VALUES ('Baijal', 'And', 'baijal@aol.net', 2);

INSERT INTO CUSTOMER (firstName, lastName, email, mid) 
VALUES ('Aarav', 'Singh', 'aarav.singh@example.com', 3);

INSERT INTO CUSTOMER (firstName, lastName, email, mid) 
VALUES ('Isha', 'Gupta', 'isha.gupta@example.com', 4);

INSERT INTO CUSTOMER (firstName, lastName, email, mid) 
VALUES ('Vikram', 'Raj', 'vikram.raj@example.com', 1);

INSERT INTO CUSTOMER (firstName, lastName, email, mid) 
VALUES ('Nisha', 'Kapoor', 'nisha.kapoor@example.com', 2);


-- Insert sample tables
INSERT INTO aTABLE (seats, available, eID) 
VALUES (4, 'Y', (SELECT eID FROM EMPLOYEE WHERE email='satvik@gmail.com'));

INSERT INTO aTABLE (seats, available, eID) 
VALUES (6, 'Y', (SELECT eID FROM EMPLOYEE WHERE email='rohan.kumar@gmail.com'));

INSERT INTO aTABLE (seats, available, eID) 
VALUES (2, 'N', (SELECT eID FROM EMPLOYEE WHERE email='neha.sharma@gmail.com'));

INSERT INTO aTABLE (seats, available, eID) 
VALUES (4, 'Y', (SELECT eID FROM EMPLOYEE WHERE email='aryan.jain@gmail.com'));


-- Insert sample ratings
INSERT INTO RATING (cID, stars, feedback) 
VALUES (4, 4, 'Great restaurant with good food and good price');

INSERT INTO RATING (cID, stars, feedback) 
VALUES (1, 5, 'Fantastic service and delicious food!');

INSERT INTO RATING (cID, stars, feedback) 
VALUES (5, 5, 'Food was decent, but service was slow');

INSERT INTO RATING (cID, stars, feedback) 
VALUES (3, 4, 'Good ambience, tasty food but a bit overpriced');

INSERT INTO RATING(cID, stars, feedback)
VALUES (6,5,'Loved the place');

INSERT INTO RATING(cID, stars, feedback)
VALUES (7,5,'The Management is just awesome');


-- Insert sample reservations
INSERT INTO RESERVATION (tID, cID, partySize, reservationDate) 
VALUES (1, 1, 3, CURRENT_DATE);

INSERT INTO RESERVATION (tID, cID, partySize, reservationDate) 
VALUES (1, 4, 6, CURRENT_DATE + INTERVAL 2 DAY);

INSERT INTO RESERVATION (tID, cID, partySize, reservationDate) 
VALUES (2, 5, 2, CURRENT_DATE + INTERVAL 3 DAY);

INSERT INTO RESERVATION (tID, cID, partySize, reservationDate) 
VALUES (3, 6, 6, CURRENT_DATE + INTERVAL 5 DAY);

use restaurant_management;

select * from arc_customer