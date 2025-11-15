-- Q1. SELECT clause with WHERE, AND, DISTINCT, Wild Card (LIKE)
-- a.	Fetch the employee number, first name and last name of those employees who are working as Sales Rep reporting to employee with employeenumber 1102 (Refer employee table)

USE classicmodels;

SELECT employeeNumber, firstName, lastName
FROM employees
WHERE jobTitle = 'Sales Rep'
  AND reportsTo = 1102;

-- b.	Show the unique productline values containing the word cars at the end from the products table.

SELECT DISTINCT productLine
FROM products
WHERE productLine LIKE '%cars';


-- Q2. CASE STATEMENTS for Segmentation
-- a. Using a CASE statement, segment customers into three categories based on their country

USE classicmodels;

SELECT customerNumber,
       customerName,
       CASE
         WHEN country IN ('USA','Canada') THEN 'North America'
         WHEN country IN ('UK','France','Germany') THEN 'Europe'
         ELSE 'Other'
       END AS CustomerSegment
FROM customers;

-- Q3. Group By with Aggregation functions and Having clause, Date and Time functions
-- a.	Using the OrderDetails table, identify the top 10 products (by productCode) with the highest total order quantity across all orders.

USE classicmodels;

SELECT productCode,
       SUM(quantityOrdered) AS total_quantity
FROM orderdetails
GROUP BY productCode
ORDER BY total_quantity DESC
LIMIT 10;

-- b.	Company wants to analyse payment frequency by month. Extract the month name from the payment date to count the total number of payments for each month and include only those months with a payment count exceeding 20. Sort the results by total number of payments in descending order.  (Refer Payments table). 

USE classicmodels;

SELECT 
    MONTHNAME(paymentDate) AS month_name,
    COUNT(*) AS total_payments
FROM payments
GROUP BY MONTH(paymentDate), MONTHNAME(paymentDate)
HAVING total_payments > 20
ORDER BY total_payments DESC;



-- Q4. CONSTRAINTS: Primary, key, foreign key, Unique, check, not null, default

-- Create a new database named and Customers_Orders and add the following tables as per the description

-- a.	Create a table named Customers to store customer information. Include the following columns:

CREATE DATABASE IF NOT EXISTS Customers_Orders;
USE Customers_Orders;

CREATE TABLE IF NOT EXISTS Customers (
  customer_id INT AUTO_INCREMENT,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  email VARCHAR(255),
  phone_number VARCHAR(20),
  PRIMARY KEY (customer_id),
  UNIQUE (email)
);
SHOW TABLES;
DESCRIBE Customers;

-- b.	Create a table named Orders to store information about customer orders. Include the following columns
CREATE TABLE IF NOT EXISTS Orders (
  order_id INT AUTO_INCREMENT,
  customer_id INT,
  order_date DATE,
  total_amount DECIMAL(10,2),
  PRIMARY KEY (order_id),
  FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
  CONSTRAINT chk_total_positive CHECK (total_amount > 0)
);
SHOW TABLES;
DESCRIBE Orders;

-- Q5. JOINS — Top 5 countries by order count (Classic Models)
USE classicmodels;

SELECT c.country,
       COUNT(*) AS order_count
FROM orders o
JOIN customers c ON o.customerNumber = c.customerNumber
GROUP BY c.country
ORDER BY order_count DESC
LIMIT 5;

-- Q6. SELF JOIN

-- MySQL: Drop if exists, create table, insert and query
DROP TABLE IF EXISTS Project;

CREATE TABLE Project (
    EmployeeID INT AUTO_INCREMENT PRIMARY KEY,
    FullName VARCHAR(50) NOT NULL,
    Gender ENUM('Male','Female') NOT NULL,
    ManagerID INT
);

-- Insert data (do NOT supply EmployeeID so AUTO_INCREMENT works)
INSERT INTO Project (FullName, Gender, ManagerID) VALUES
('Pranaya', 'Male', 3),
('Priyanka', 'Female', 1),
('Preety', 'Female', NULL),
('Anurag', 'Male', 1),
('Sambit', 'Male', 1),
('Rajesh', 'Male', 3),
('Hina', 'Female', 3);

-- Self-join to show Manager Name and Employee Name
SELECT 
    M.FullName AS `Manager Name`,
    E.FullName AS `Emp Name`
FROM Project E
JOIN Project M
  ON E.ManagerID = M.EmployeeID;
  
 
-- Q7: DDL Commands - CREATE, ALTER, RENAME

-- Safe: drop target if it already exists (so RENAME won't fail)
DROP TABLE IF EXISTS facility_details;

-- Drop source if exists to allow re-running the script cleanly
DROP TABLE IF EXISTS facility;

-- Create table
CREATE TABLE facility (
    Facility_ID INT,
    Name VARCHAR(100),
    State VARCHAR(100),
    Country VARCHAR(100)
);

-- Make Facility_ID NOT NULL AUTO_INCREMENT and add PK
ALTER TABLE facility
  MODIFY Facility_ID INT NOT NULL AUTO_INCREMENT,
  ADD PRIMARY KEY (Facility_ID);

-- Add City column after Name and make it NOT NULL
ALTER TABLE facility
  ADD COLUMN City VARCHAR(100) NOT NULL AFTER Name;

-- Now safely rename facility to facility_details
RENAME TABLE facility TO facility_details;

-- Confirm final structure
DESC facility_details;

-- Q8. Views in SQL

USE classicmodels;

CREATE OR REPLACE VIEW product_category_sales AS
SELECT p.productLine,
       SUM(od.quantityOrdered * od.priceEach) AS total_sales,
       COUNT(DISTINCT od.orderNumber) AS number_of_orders
FROM products p
JOIN orderdetails od ON p.productCode = od.productCode
GROUP BY p.productLine;
SELECT * FROM product_category_sales;



-- Q9. Stored Procedures in SQL with parameters

DROP PROCEDURE IF EXISTS Get_country_payments;
DELIMITER $$

CREATE PROCEDURE Get_country_payments(
  IN input_year INT,
  IN input_country VARCHAR(50)
)
BEGIN
  SELECT 
    YEAR(p.paymentDate) AS `Year`,
    c.country AS `Country`,
    CONCAT(ROUND(SUM(p.amount) / 1000, 0), 'K') AS `Total Amount`
  FROM payments p
  JOIN customers c ON p.customerNumber = c.customerNumber
  WHERE YEAR(p.paymentDate) = input_year
    AND c.country = input_country
  GROUP BY YEAR(p.paymentDate), c.country;
END$$

DELIMITER ;
CALL Get_country_payments(2003, 'France');



-- Q10. Window functions - Rank, dense_rank, lead and lag

-- a) Using customers and orders tables, rank the customers based on their order frequency

SELECT 
    c.customerName,
    COUNT(o.orderNumber) AS order_count,
    DENSE_RANK() OVER (ORDER BY COUNT(o.orderNumber) DESC) AS order_frequency_rnk
FROM 
    customers c
JOIN 
    orders o ON c.customerNumber = o.customerNumber
GROUP BY 
    c.customerName
ORDER BY 
    order_frequency_rnk;


-- b) Calculate year wise, month name wise count of orders and year over year (YoY) percentage change. Format the YoY values in no decimals and show in % sign


WITH monthly_orders AS (
  SELECT 
    YEAR(orderDate) AS order_year,
    MONTHNAME(orderDate) AS month_name,
    MONTH(orderDate) AS month_num,
    COUNT(orderNumber) AS total_orders
  FROM orders
  GROUP BY YEAR(orderDate), MONTH(orderDate), MONTHNAME(orderDate)
)
SELECT 
  order_year AS `Year`,
  month_name AS `Month`,
  total_orders AS `Total Orders`,
  CASE
    WHEN LAG(total_orders) OVER (ORDER BY order_year, month_num) IS NULL THEN NULL
    ELSE CONCAT(
      ROUND(((total_orders - LAG(total_orders) OVER (ORDER BY order_year, month_num)) 
             / LAG(total_orders) OVER (ORDER BY order_year, month_num)) * 100),
      '%'
    )
  END AS `% YoY Change`
FROM monthly_orders
ORDER BY order_year, month_num;

-- Q11.Subqueries and their applications


USE classicmodels;

SELECT productLine,
       COUNT(*) AS Total
FROM products
WHERE buyPrice > (SELECT AVG(buyPrice) FROM products)
GROUP BY productLine;


-- Q12. ERROR HANDLING in SQL

USE classicmodels;

-- Drop old table and procedure if needed
DROP TABLE IF EXISTS Emp_EH;
CREATE TABLE Emp_EH (
    EmpID INT PRIMARY KEY,
    EmpName VARCHAR(50),
    EmailAddress VARCHAR(100)
);

DROP PROCEDURE IF EXISTS Insert_Emp_EH;
DELIMITER $$

CREATE PROCEDURE Insert_Emp_EH(
    IN p_EmpID INT,
    IN p_EmpName VARCHAR(50),
    IN p_EmailAddress VARCHAR(100)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        -- rollback in case a transaction started
        ROLLBACK;
        SELECT 'Error occurred' AS Message;
    END;

    START TRANSACTION;
        INSERT INTO Emp_EH (EmpID, EmpName, EmailAddress)
        VALUES (p_EmpID, p_EmpName, p_EmailAddress);
    COMMIT;

    SELECT 'Record inserted successfully' AS Message;
END$$

DELIMITER ;
CALL Insert_Emp_EH(1, 'John', 'john@example.com');



-- Q13. TRIGGERS

USE classicmodels;

-- Drop existing table if present (avoids "table exists" error)
DROP TABLE IF EXISTS `Emp_BIT`;

-- Create table (id as PK to avoid duplicate-insert errors)
CREATE TABLE `Emp_BIT` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `Name` VARCHAR(50) NOT NULL,
  `Occupation` VARCHAR(50),
  `Working_date` DATE,
  `Working_hours` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert initial rows (explicit column list so it maps to columns correctly)
INSERT INTO `Emp_BIT` (`Name`,`Occupation`,`Working_date`,`Working_hours`) VALUES
('Robin', 'Scientist', '2020-10-04', 12),  
('Warner', 'Engineer', '2020-10-04', 10),  
('Peter', 'Actor', '2020-10-04', 13),  
('Marco', 'Doctor', '2020-10-04', 14),  
('Brayden', 'Teacher', '2020-10-04', 12),  
('Antonio', 'Business', '2020-10-04', 11);

-- If a trigger with same name exists, drop it first to avoid "trigger exists" error
DROP TRIGGER IF EXISTS `trg_BI_WorkingHours_Positive`;

-- Create BEFORE INSERT trigger to make negative Working_hours positive
DELIMITER $$
CREATE TRIGGER `trg_BI_WorkingHours_Positive`
BEFORE INSERT ON `Emp_BIT`
FOR EACH ROW
BEGIN
  IF NEW.`Working_hours` < 0 THEN
    SET NEW.`Working_hours` = ABS(NEW.`Working_hours`);
  END IF;
END$$
DELIMITER ;

-- Test: insert a row with negative hours (it should be stored as positive)
INSERT INTO `Emp_BIT` (`Name`,`Occupation`,`Working_date`,`Working_hours`)
VALUES ('John','Nurse','2020-10-05', -9);

-- View results
SELECT id, `Name`, Occupation, Working_date, Working_hours FROM `Emp_BIT`;
