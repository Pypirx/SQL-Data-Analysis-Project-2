
/* Exploring table events */

SELECT *
FROM events;

SELECT 
    COUNT(*) as total_rows,
    COUNT(experiment_group) as non_null_rows
FROM events;

/* Exploring time-series datatype */
SELECT 
    min(timestamp) as start_date,
    max(timestamp) as end_date
FROM events;

SELECT
    date_trunc('quarter', timestamp) as quarter,
    COUNT(*) as frequency
FROM events
GROUP BY quarter
ORDER BY quarter;

SELECT 
    EXTRACT(dow from timestamp) as date_of_week,
    COUNT(*) as fregency
FROM events
GROUP BY date_of_week
ORDER BY date_of_week;

SELECT 
    month,
    fregency,
    LAG(fregency) OVER (ORDER BY month) as pre_month,
    fregency - LAG(fregency) OVER (ORDER BY month) as diff
FROM (
    SELECT 
        DATE_TRUNC('month', timestamp) as month,
        COUNT(*) as fregency
    FROM events
    GROUP BY month
);
/***** Therre is a remarkable decline in Feb*****/

SELECT 
    LOWER(traffic_source) AS traffic_source,
    COUNT(*) AS count
FROM events
GROUP BY LOWER(traffic_source);

UPDATE events
SET traffic_source = LOWER(traffic_source);
------------------------------


/* Exploring category data-type */

SELECT 
    event_type,
    frequency,
    ROUND(frequency*100/SUM(frequency) OVER(), 2) as percentage
FROM (
    SELECT 
    event_type,
    COUNT(*) as frequency
FROM events
GROUP BY event_type
ORDER BY frequency DESC
);

WITH base AS (
    SELECT 
        MAX(CASE WHEN event_type = 'view' THEN freq END) AS view,
        MAX(CASE WHEN event_type = 'click' THEN freq END) AS click,
        MAX(CASE WHEN event_type = 'add_to_cart' THEN freq END) AS add_to_cart,
        MAX(CASE WHEN event_type = 'purchase' THEN freq END) AS purchase
    FROM (
        SELECT event_type, COUNT(*) AS freq
        FROM events
        GROUP BY event_type
    ) t
)

SELECT  
    view,
    click,
    add_to_cart,
    purchase,
    ROUND(click * 1.0 / view, 2) AS ctr,
    ROUND(add_to_cart * 1.0 / click, 2) AS add_to_cart_rate,
    ROUND(purchase * 1.0 / add_to_cart, 2) AS purchase_rate,
    ROUND(purchase * 1.0 / view, 2) AS overall_rate
FROM base;
/***** The add_to_cart_rate is fairly high at 75%, while the purchase_rate is lower at 36%*****/


SELECT 
    device_type,
    COUNT(*) as count
FROM events
GROUP BY device_type
ORDER BY count DESC;

SELECT 
    traffic_source,
    COUNT(*) as count
FROM events
GROUP BY traffic_source
ORDER BY count DESC;

SELECT 
    campaign_id,
    COUNT(*) as count
FROM events
GROUP BY campaign_id
ORDER BY count DESC;

SELECT 
    experiment_group,
    COUNT( experiment_group) 
FROM events
GROUP BY experiment_group

------------------


/*Expolring numerical variants*/

SELECT
    MIN(customer_id) as min,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY customer_id) as p25,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY customer_id) as median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY customer_id) as p75,
    MAX(customer_id) as max
FROM events;

SELECT
    MIN(session_id) as min_session,
    MAX(session_id) as max_session,
    MIN(product_id) as min_product,
    MAX(product_id) as max_product
FROM events;

SELECT 
    ROUND(AVG(session_duration_sec), 2) as avg,
    ROUND(STDDEV(session_duration_sec), 2) as Std_dev,
    MIN(session_duration_sec) as min,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY session_duration_sec) AS P25,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY session_duration_sec) AS median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY session_duration_sec) AS P75,
    MAX(session_duration_sec) as max
FROM events;
/* The data is skewed to the right */


-------------------


/* Exporing table transactions */

SELECT 
    COUNT(*) as total_rows,
    COUNT(gross_revenue) as non_null_rows
FROM transactions;

SELECT 
    refund_flag,
    COUNT(*) as count 
FROM transactions
GROUP BY refund_flag
ORDER BY count DESC;

SELECT
    MIN(gross_revenue) as min,
    STDDEV(gross_revenue) as Std_dev,
    AVG(gross_revenue) as mean,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY gross_revenue) as p25,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gross_revenue) as median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY gross_revenue) as p75,
    MAX(gross_revenue) as max
FROM transactions;
/* Data is skewed to the right */

with stats as(
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY gross_revenue) AS Q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY gross_revenue) AS Q3
    FROM transactions
)
SELECT
    gross_revenue,
    COUNT(*) as count 
FROM stats, transactions
WHERE 
    gross_revenue > Q1 - 1.5*(Q3-Q1)
    AND gross_revenue < Q3 + 1.5*(Q3-Q1)
GROUP BY gross_revenue
ORDER BY count DESC;

---------------------


/* Exporing table campaigns */

SELECT *
FROM campaigns;

SELECT
    target_segment,
    COUNT(*) as count 
FROM campaigns
GROUP BY target_segment
ORDER BY count DESC;

/* Exporing table customers */

SELECT *
FROM customers;

SELECT
    COUNT(*) as total_rows,
    COUNT(country) as non_null_rows
FROM customers;

SELECT
    acquisition_channel,
    COUNT(*) as count
FROM customers
GROUP BY acquisition_channel
ORDER BY count DESC;

/* Exporing table products */

SELECT *
FROM products;

SELECT
    COUNT(*) as total_rows,
    COUNT(category) as non_null_rows
FROM products;

SELECT
    is_premium,
    COUNT(*) as count
FROM products
GROUP BY is_premium
ORDER BY count DESC;

SELECT
    COUNT (DISTINCT brand) as count
FROM products

SELECT
    MIN(base_price) as min,
    STDDEV(base_price) as Std_dev,
    AVG(base_price) as mean,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY base_price) as p25,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY base_price) as median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY base_price) as p75,
    MAX(base_price) as max
FROM products


SELECT 
    min(launch_date) as start_date,
    max(launch_date) as end_date
FROM products;

SELECT
    date_trunc('month', launch_date) as quarter,
    COUNT(*) as frequency
FROM products
GROUP BY quarter
ORDER BY frequency DESC;

SELECT 
    EXTRACT(dow from timestamp) as date_of_week,
    COUNT(*) as fregency
FROM events
GROUP BY date_of_week
ORDER BY date_of_week;


/* check standard distribution */
WITH stats AS (
    SELECT 
        AVG(value) AS mean,
        STDDEV(value) AS stddev
    FROM table_name
)
SELECT 
    COUNT(*) * 1.0 / (SELECT COUNT(*) FROM table_name) AS ratio
FROM table_name, stats
WHERE value BETWEEN mean - stddev AND mean + stddev;

/* check correlation */
SELECT CORR(session_duration_sec, purchase_amount) AS corr_value
FROM events;
