
CREATE DATABASE sql_project_2;
-- =====================================================
-- Table campaigns
-- =====================================================
CREATE TABLE campaigns (
    campaign_id INT PRIMARY KEY,
    channel VARCHAR(50),
    objective VARCHAR(50),
    start_date DATE,
    end_date DATE,
    target_segment VARCHAR(50),
    expected_uplift DECIMAL(4,3)
);

-- =====================================================
-- Table customers
-- =====================================================
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    signup_date DATE,
    country VARCHAR(50),
    age INT,
    gender VARCHAR(10),
    loyalty_tier VARCHAR(20),
    acquisition_channel VARCHAR(50)
);

-- =====================================================
-- Table products
-- =====================================================
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    category VARCHAR(50),
    brand VARCHAR(50),
    base_price DECIMAL(5,2),
    launch_date DATE,
    is_premium BOOLEAN
);

-- =====================================================
-- Table events
-- =====================================================

CREATE TABLE events (
    event_id INT PRIMARY KEY,
    timestamp TIMESTAMP,
    customer_id INT,
    session_id INT,
    event_type VARCHAR(50),
    product_id INT,
    device_type VARCHAR(20),
    traffic_source VARCHAR(50),
    campaign_id INT,
    page_category VARCHAR(50),
    session_duration_sec DECIMAL(5,1),
    experiment_group VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (campaign_id) REFERENCES campaigns(campaign_id)
);
-- Create index for foreign key in Table events
CREATE INDEX idx_events_customer ON events(customer_id);
CREATE INDEX idx_events_product ON events(product_id);
CREATE INDEX idx_events_campaign ON events(campaign_id);

-- =====================================================
-- Table transaction 
-- =====================================================
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    timestamp TIMESTAMP,
    customer_id INT,
    product_id INT,
    quantity INT,
    discount_applied DECIMAL(3,2),
    gross_revenue DECIMAL(6,2),
    campaign_id INT,
    refund_flag BOOLEAN,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (campaign_id) REFERENCES campaigns(campaign_id)
);
-- Create index for foreign key in Table transaction
CREATE INDEX idx_transactions_customer ON transactions(customer_id);
CREATE INDEX idx_transactions_product ON transactions(product_id);
CREATE INDEX idx_transactions_campaign ON transactions(campaign_id);

-- =====================================================
-- Insert dataset 
-- =====================================================


COPY campaigns
FROM 'c:\Users\Public\Marketing & E-Commerce Analytics Dataset\campaigns.csv'
DELIMITER ','
CSV HEADER
ENCODING 'UTF8';

COPY customers
FROM 'C:\Users\Public\Marketing & E-Commerce Analytics Dataset\customers.csv'
DELIMITER ','
CSV HEADER
ENCODING 'UTF8';

COPY products
FROM 'c:\Users\Public\Marketing & E-Commerce Analytics Dataset\products.csv'
DELIMITER ','
CSV HEADER
ENCODING 'UTF8';

INSERT INTO campaigns (
    campaign_id, channel, objective, start_date, end_date, target_segment, expected_uplift
)
VALUES (
    0, 'None', 'No Campaign', NULL, NULL, 'None', 0.000
);

COPY events
FROM 'C:\Users\Public\Marketing & E-Commerce Analytics Dataset\events.csv'
DELIMITER ','
CSV HEADER
ENCODING 'UTF8';

COPY transactions
FROM 'c:\Users\Public\Marketing & E-Commerce Analytics Dataset\transactions.csv'
DELIMITER ','
CSV HEADER
ENCODING 'UTF8';

