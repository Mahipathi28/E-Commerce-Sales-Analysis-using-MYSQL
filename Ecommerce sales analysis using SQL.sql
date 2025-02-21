-- Create the database
CREATE DATABASE ecommerce_sales;

-- Use the database
USE ecommerce_sales;

-- Create customers table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    registration_date DATE
);

-- Create products table
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10, 2)
);

-- Create orders table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    total_amount DECIMAL(10, 2),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Create order_items table
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    item_price DECIMAL(10, 2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);


-- Insert sample data into customers table
INSERT INTO customers (customer_id, first_name, last_name, email, registration_date)
VALUES
    (1, 'John', 'Doe', 'john.doe@email.com', '2023-01-01'),
    (2, 'Jane', 'Smith', 'jane.smith@email.com', '2023-01-15'),
    (3, 'Bob', 'Johnson', 'bob.johnson@email.com', '2023-02-01'),
    (4, 'Alice', 'Williams', 'alice.williams@email.com', '2023-02-15'),
    (5, 'Charlie', 'Brown', 'charlie.brown@email.com', '2023-03-01');

-- Insert sample data into products table
INSERT INTO products (product_id, product_name, category, price)
VALUES
    (1, 'Laptop', 'Electronics', 999.99),
    (2, 'Smartphone', 'Electronics', 599.99),
    (3, 'Running Shoes', 'Sports', 79.99),
    (4, 'Coffee Maker', 'Home Appliances', 49.99),
    (5, 'Book: SQL for Beginners', 'Books', 29.99);

-- Insert sample data into orders table
INSERT INTO orders (order_id, customer_id, order_date, total_amount)
VALUES
    (1, 1, '2023-03-15', 1029.98),
    (2, 2, '2023-03-16', 599.99),
    (3, 3, '2023-03-17', 129.98),
    (4, 4, '2023-03-18', 999.99),
    (5, 5, '2023-03-19', 79.98);

-- Insert sample data into order_items table
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, item_price)
VALUES
    (1, 1, 1, 1, 999.99),
    (2, 1, 4, 1, 29.99),
    (3, 2, 2, 1, 599.99),
    (4, 3, 3, 1, 79.99),
    (5, 3, 5, 1, 49.99),
    (6, 4, 1, 1, 999.99),
    (7, 5, 3, 1, 79.99);
	
	
	
	-- 1. Retrieve all customers
SELECT * FROM customers;

-- 2. List all products with their prices
SELECT product_name, price FROM products;

-- 3. Show total number of orders
SELECT COUNT(*) AS total_orders FROM orders;

-- 4. Find the most expensive product
SELECT product_name, price
FROM products
ORDER BY price DESC
LIMIT 1;

-- 5. Calculate the average order total
SELECT AVG(total_amount) AS avg_order_total FROM orders;



-- 1. List customers with their total order amounts
SELECT c.customer_id, c.first_name, c.last_name, SUM(o.total_amount) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC;

-- 2. Find the top 3 best-selling products
SELECT p.product_id, p.product_name, SUM(oi.quantity) AS total_quantity_sold
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_quantity_sold DESC
LIMIT 3;

-- 3. Calculate the revenue by product category
SELECT p.category, SUM(oi.quantity * oi.item_price) AS total_revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;

-- 4. Find customers who have not placed any orders
SELECT c.customer_id, c.first_name, c.last_name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- 5. Calculate the average time between customer registration and their first order
SELECT AVG(DATEDIFF(o.order_date, c.registration_date)) AS avg_days_to_first_order
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id = (
    SELECT MIN(order_id)
    FROM orders
    WHERE customer_id = c.customer_id
);




-- 1. Create a customer segmentation based on total spend
WITH customer_spend AS (
    SELECT c.customer_id, c.first_name, c.last_name, SUM(o.total_amount) AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT 
    customer_id, 
    first_name, 
    last_name, 
    total_spent,
    CASE 
        WHEN total_spent > 1000 THEN 'High Value'
        WHEN total_spent > 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM customer_spend
ORDER BY total_spent DESC;

-- 2. Calculate month-over-month growth in total sales
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        SUM(total_amount) AS total_sales
    FROM orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT 
    month,
    total_sales,
    LAG(total_sales) OVER (ORDER BY month) AS previous_month_sales,
    (total_sales - LAG(total_sales) OVER (ORDER BY month)) / LAG(total_sales) OVER (ORDER BY month) * 100 AS growth_percentage
FROM monthly_sales
ORDER BY month;

-- 3. Identify products often purchased together
SELECT 
    p1.product_name AS product1,
    p2.product_name AS product2,
    COUNT(*) AS purchase_frequency
FROM order_items oi1
JOIN order_items oi2 ON oi1.order_id = oi2.order_id AND oi1.product_id < oi2.product_id
JOIN products p1 ON oi1.product_id = p1.product_id
JOIN products p2 ON oi2.product_id = p2.product_id
GROUP BY p1.product_name, p2.product_name
ORDER BY purchase_frequency DESC
LIMIT 5;

-- 4. Calculate customer lifetime value (CLV)
WITH customer_orders AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        SUM(o.total_amount) AS total_spent,
        COUNT(DISTINCT o.order_id) AS total_orders,
        DATEDIFF(MAX(o.order_date), MIN(o.order_date)) / 365.0 AS customer_lifetime_years
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT 
    customer_id,
    first_name,
    last_name,
    total_spent,
    total_orders,
    customer_lifetime_years,
    (total_spent / customer_lifetime_years) AS annual_value,
    (total_spent / customer_lifetime_years) * 3 AS estimated_clv -- Assuming 3 years as the average customer lifetime
FROM customer_orders
ORDER BY estimated_clv DESC;

-- 5. Analyze seasonal trends in product categories
SELECT 
    p.category,
    QUARTER(o.order_date) AS quarter,
    SUM(oi.quantity * oi.item_price) AS quarterly_revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
GROUP BY p.category, QUARTER(o.order_date)
ORDER BY p.category, quarter;









