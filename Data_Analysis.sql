/* 
Problem 1: Campaign Analysis 
- Which campaign generated the highest revenue?
- Which campaign achieved the highest conversion rate?
- Which marketing channel (Email, Social, Paid Search, Display, or Affiliate) generated the most revenue?
- Does expected uplift accurately reflect actual campaign effectiveness?
- Which traffic source generated the highest volume of visitors, and how do conversion rate and customer quality vary across traffic sources?
*/

/* Which campaign generated the highest revenue? */
SELECT 
    campaign_id,
    SUM(gross_revenue) as total_gross_revenue
FROM transactions
WHERE gross_revenue is not NULL
GROUP BY campaign_id
ORDER BY total_gross_revenue DESC; 
--- Campaign 5,18,29 have the most revenue

/* Which campaign achieved the highest conversion rate? */
SELECT
    campaign_id,
    ROUND(click_count *1.0/view_count, 2) as CTR
FROM(
    SELECT  
        campaign_id,
        COUNT(CASE WHEN event_type = 'view' THEN 1 END) as view_count,
        COUNT(CASE WHEN event_type = 'click' THEN 1 END) as click_count
    FROM events
    GROUP BY campaign_id
)
ORDER BY ctr DESC;
-- The CTR ranges from .35 to 0.39, and the highest rate belongs to campaign 14

/* Which channel brings back the most revenue */
SELECT
    campaigns.channel as channel,
    SUM(transactions.gross_revenue) as total_gross_revenue
FROM transactions
JOIN campaigns ON campaigns.campaign_id = transactions.campaign_id
WHERE gross_revenue is not NULL
GROUP BY channel
ORDER BY total_gross_revenue DESC;
--- Affiliate brings back the most revenue, followed by Paid Search, while Social is the smallest

/* Which channel has the most CTR */
with ctr_table as (
        SELECT  
        campaign_id,
        COUNT(CASE WHEN event_type = 'view' THEN 1 END) as view_count,
        COUNT(CASE WHEN event_type = 'click' THEN 1 END) as click_count
    FROM events
    GROUP BY campaign_id
)
SELECT
    channel,
    ROUND(AVG(click_count *1.0/view_count), 2) as CTR
FROM ctr_table
JOIN campaigns ON campaigns.campaign_id = ctr_table.campaign_id
GROUP BY channel
ORDER BY ctr DESC;
-- There are no difference about CTR between channels

/* Which channel has the most number of clicks */
SELECT
    channel,
    COUNT(event_type) as count
FROM events
JOIN campaigns on campaigns.campaign_id = events.campaign_id
WHERE event_type = 'view' and device_type = 'mobile'
GROUP BY channel
ORDER BY count desc;
-- There are no remarrkable difference about number of clicks and type of device between channels

/* Does channel affect the session_duration */
SELECT
    channel
    percentile_cont(0.5) within GROUP (ORDER BY session_duration_sec) as median_sec
FROM events
JOIN campaigns on campaigns.campaign_id = events.campaign_id
GROUP BY channel, traffic_source
ORDER BY median_sec;

/* How many customers does a channel bring back */
SELECT 
    channel,
    COUNT( distinct customer_id) as customer_number
FROM events
JOIN campaigns on campaigns.campaign_id = events.campaign_id
GROUP BY channel
ORDER BY customer_number DESC;
-- Paid Search brings back the most number of customers with 68553 customers after None, followed by Email and Affiliate, and Social is the lowest.

/* Which campaign has the highest conversion rate */
SELECT
    campaign_id,
    ROUND(click_count *1.0/view_count, 2) as CTR
FROM(
    SELECT  
        campaign_id,
        COUNT(CASE WHEN event_type = 'view' THEN 1 END) as view_count,
        COUNT(CASE WHEN event_type = 'click' THEN 1 END) as click_count
    FROM events
    GROUP BY campaign_id
)
ORDER BY ctr DESC;
-- The CTR ranges from .35 to 0.39, with the highest rate belongs to campaign 14

---------------------------------------

/* 2. Customer behavior

What is the most common customer journey (e.g., Home → Product Listing Page → Product Detail Page → Cart → Checkout)?
What is the conversion rate at each stage of the purchase funnel?
Which page type has the highest bounce rate?
On average, how many events occur per session, and how long does a typical session last?
Which page type do customers spend the most time on?

/* Number of access to each page */

SELECT 
    page_category,
    count(page_category) as count 
FROM events
GROUP BY page_category
ORDER BY count DESC;
--PLP: 315130, PDP: 314625, Home: 209770, Checkout: 104891, Cart: 104159

/* How long does it take to visit website in one sesssion on median*/

with total_time_visit as(
    SELECT
        session_id,
        SUM(session_duration_sec) as total_sec
    FROM events
    GROUP BY session_id
    )
SELECT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_sec) as median_sec
FROM total_time_visit;
-- the meidan sec is 199.2s wich is corresponding to 3.32m

/* How long does it take to visit to each page on median */

SELECT
    page_category,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY session_duration_sec) as median_page_sec
FROM events
GROUP BY page_category
-- Customer stay at Home page longest.

/* How many events happened in on session and average */
with events_per_session as (
    SELECT
        session_id,
        COUNT(*) as event_number
    FROM events
    GROUP BY session_id
)
SELECT 
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY event_number) as median_number
FROM events_per_session;
-- The median number of events in one sesssion is 2, while the most is 11

/* What kind of page has the most bounce rate? */
with tmp as(
    SELECT 
        page_category,
        COUNT(*) as total_events,
        COUNT(CASE WHEN event_type = 'bounce' THEN 1 END) as bounce_number
    FROM events
    GROUP BY page_category
)
SELECT 
    page_category,
    ROUND(bounce_number *1.0/ total_events, 2) as bounce_rate
FROM tmp;
-- No difference

/* How many customer return the website and number of return on everage */
with tmp as (
    SELECT
        customer_id,
        COUNT(distinct session_id) as return_number
    FROM events
    GROUP BY customer_id
    HAVING COUNT(distinct session_id) > 1
)
SELECT
    COUNT(*) number_of_customer,
    ROUND(AVG(return_number), 0) as avg_return_number
FROM tmp;
-- There are almost 100,000 returned customers and amount of return is 10 times.

/* Page journey on website */
with tmp as (
    SELECT
        session_id,
        STRING_AGG(page_category, '->' ORDER BY timestamp) as page_journey
    FROM events
    GROUP BY session_id
    HAVING COUNT(*) > 1
)
SELECT
    page_journey,
    COUNT(*) as amount
FROM tmp
GROUP BY page_journey
ORDER BY amount DESC;


/* Event journey on website */
with tmp as (
    SELECT
        session_id,
        STRING_AGG(event_type, '->' ORDER BY timestamp) as event_journey
    FROM events
    GROUP BY session_id
    HAVING COUNT(*) > 1
)
SELECT
    event_journey,
    COUNT(*) as amount
FROM tmp
GROUP BY event_journey
ORDER BY amount DESC;

/* Conversion rate */
WITH tmp AS (
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
    ROUND(purchase * 1.0 / view, 2) AS view_to_purchase_rate
FROM tmp;
-- view to purchase rate is 0.10, while ctr is 0.36
-- add_to_cart rate is 0.75, while purchase_rate is 0.36, drop by .39

---------------------
/* 
3. Customer Segmentation Analysis
Which customer segments (by age, country, gender, and loyalty tier) have the highest customer lifetime value (CLV)?
Which acquisition channels generate customers with the highest purchase rates?
Which customer segments have the highest refund rates?
How does retention rate vary across customer acquisition cohorts?
*/

/* which customer segmentation by loytalty contributes to the revenue the most */
SELECT 
    loyalty_tier,
    SUM(gross_revenue) as total_revenue 
FROM transactions tr
JOIN customers c on c.customer_id = tr.customer_id
WHERE gross_revenue is not NULL
GROUP BY loyalty_tier
ORDER BY total_revenue DESC;
-- The 1st is bronze

/* which customer segmentation by country contributes to the revenue the most */
SELECT 
    country,
    SUM(gross_revenue) as total_revenue 
FROM transactions tr
JOIN customers c on c.customer_id = tr.customer_id
WHERE gross_revenue is not NULL
GROUP BY country
ORDER BY total_revenue DESC;
-- US is the largest, while AU is smallest

/* which customer segmentation by loytalty contributes to the revenue the most */
WITH customer_age_group AS (
    SELECT
        tr.gross_revenue,
        CASE
            WHEN c.age BETWEEN 18 AND 24 THEN '18-24'
            WHEN c.age BETWEEN 25 AND 34 THEN '25-34'
            WHEN c.age BETWEEN 35 AND 44 THEN '35-44'
            WHEN c.age BETWEEN 45 AND 54 THEN '45-54'
            WHEN c.age BETWEEN 55 AND 64 THEN '55-64'
            ELSE '65+'
        END AS age_group
    FROM transactions tr
    JOIN customers c
        ON c.customer_id = tr.customer_id
    WHERE gross_revenue IS NOT NULL
)
SELECT
    age_group,
    SUM(gross_revenue) AS total_revenue
FROM customer_age_group
GROUP BY age_group
ORDER BY total_revenue DESC;
-- the age group 35-44 contributes to the total revenue the most

/* Which acquisition channel does customers have a higher rate of purchase */
with tmp as (
SELECT
    acquisition_channel,
    COUNT(*) as total_event_number,
    COUNT( CASE WHEN event_type = 'purchase' THEN 1 END) as purchase_number
FROM events e
JOIN customers c on c.customer_id = e.customer_id
GROUP BY acquisition_channel
)
SELECT
    acquisition_channel,
    ROUND(purchase_number * 100.0/total_event_number, 2) as purchase_rate
FROM tmp
ORDER BY purchase_rate DESC;
-- Paid Search channel has the highest purchase rate at 5.17

/* Which customer segmentation by loyalty_tier has the highest refund rate */
WITH tmp AS (
    SELECT
        loyalty_tier,
        COUNT(*) as total,
        COUNT(CASE WHEN refund_flag = TRUE THEN 1 END) as refund_number
    FROM transactions tr
    JOIN customers c
        ON c.customer_id = tr.customer_id
    GROUP BY loyalty_tier
)
SELECT
    loyalty_tier,
    ROUND(refund_number*1.0/total, 3) as refund_rate
FROM tmp
ORDER BY refund_rate DESC;
-- The platinum segment has the highest refund rate at 0.031

/* Những khách hàng đăng ký ở các thời điểm khác nhau có mức độ quay lại khác nhau không? 
- Những khách hàng đăng ký trong cùng một tháng có quay lại sử dụng sản phẩm trong các tháng tiếp theo hay không?
*/
WITH cohort_base AS (
    -- Xác định cohort đăng ký của từng khách hàng
    SELECT
        customer_id,
        DATE_TRUNC('month', signup_date) AS cohort_month
    FROM customers
),

customer_activity AS (
    -- Xác định tháng hoạt động của khách hàng
    SELECT DISTINCT
        e.customer_id,
        DATE_TRUNC('month', e.timestamp) AS activity_month
    FROM events e
),

cohort_activity AS (
    -- Ghép cohort với hoạt động và tính số tháng kể từ đăng ký
    SELECT
        cb.cohort_month,
        ca.customer_id,
        ca.activity_month,
        (
            EXTRACT(YEAR FROM AGE(ca.activity_month, cb.cohort_month)) * 12
            + EXTRACT(MONTH FROM AGE(ca.activity_month, cb.cohort_month))
        ) AS month_number
    FROM cohort_base cb
    JOIN customer_activity ca
        ON cb.customer_id = ca.customer_id
    WHERE ca.activity_month >= cb.cohort_month
),

cohort_size AS (
    -- Quy mô ban đầu của từng cohort
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM cohort_base
    GROUP BY cohort_month
),

retention_table AS (
    -- Số khách hàng active theo từng cohort và tháng
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT customer_id) AS active_users
    FROM cohort_activity
    GROUP BY cohort_month, month_number
)

SELECT
    rt.cohort_month,
    rt.month_number,
    cs.cohort_size,
    rt.active_users,
    ROUND(100.0 * rt.active_users / cs.cohort_size, 2) AS retention_rate
FROM retention_table rt
JOIN cohort_size cs
    ON rt.cohort_month = cs.cohort_month
ORDER BY rt.cohort_month, rt.month_number;

-------------------------------------

/* 
4. Product and Revenue Analysis
- Which product categories contribute the most to total revenue?
- Do premium products exhibit different refund rates compared to non-premium products?
- How do discounts affect revenue and conversion rates?
*/

/* Which product categories contribute to the revenue the most? */
SELECT
    category,
    SUM(gross_revenue) as total_revenue
FROM transactions t
JOIN products p on t.product_id = p.product_id
GROUP BY category
ORDER BY total_revenue DESC;
-- Electronics brouhgt back the most revenue

/* Is there any difference in refund rate between premium and ordinary products? */
with tmp as(
SELECT 
    is_premium,
    COUNT(CASE WHEN refund_flag = 'TRUE' THEN 1 END ) as refund_count,
    COUNT(*) as total
FROM transactions t
JOIN products p on p.product_id = t.product_id
GROUP BY is_premium
)
SELECT
    is_premium,
    ROUND(refund_count*1.0/total,3) as refund_rate
FROM tmp;
-- The premium products have higher refund_rate

/* Does discount amount affect purchase rate? */
WITH event_summary AS (
    SELECT
        customer_id,
        COUNT(*) AS total_events,
        COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) AS purchase_events
    FROM events
    GROUP BY customer_id
),

transaction_summary AS (
    SELECT
        customer_id,
        MAX(discount_applied) AS discount_level
    FROM transactions
    GROUP BY customer_id
)

SELECT
    t.discount_level,
    COUNT(*) AS customers,
    ROUND(AVG(e.purchase_events::numeric / e.total_events), 4) AS avg_purchase_rate
FROM event_summary e
JOIN transaction_summary t
    ON e.customer_id = t.customer_id
GROUP BY t.discount_level
ORDER BY t.discount_level;
-- The discount amount affects purchase rate, the more discount there is, the more customers purchase.

/* Does discount amount affect revenue? */
SELECT
    discount_applied,
    SUM(gross_revenue) as total_revenue
FROM transactions
WHERE gross_revenue is not NULL
GROUP BY discount_applied 
ORDER BY total_revenue DESC;
-- This seem discount strategy doesn't work with revenue

/* Time Series Analysis by revenue */ 
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
-- There was a remarkable decline in Feb */

-----------------------------------------------

/* CLV Analysis */
-- Step 1: Calculate some basic index about customers 
SELECT
    customer_id,
    COUNT(DISTINCT transaction_id) AS total_orders,
    SUM(gross_revenue) AS total_revenue,
    AVG(gross_revenue) AS avg_order_value,
    MIN(timestamp) AS first_purchase,
    MAX(timestamp) AS last_purchase,
    DATE_PART('day', MAX(timestamp) - MIN(timestamp)) + 1 AS customer_lifespan_days
FROM transactions
GROUP BY customer_id;

-- Step 2: Measure CLV
WITH customer_metrics AS (
    SELECT
        customer_id,
        COUNT(DISTINCT transaction_id) AS total_orders,
        SUM(gross_revenue) AS total_revenue,
        AVG(gross_revenue) AS avg_order_value,
        DATE_PART('day', MAX(timestamp) - MIN(timestamp)) + 1 AS lifespan_days
    FROM transactions
    GROUP BY customer_id
)

SELECT
    customer_id,
    total_orders,
    total_revenue,
    avg_order_value,
    lifespan_days,
    ROUND(
        avg_order_value *
        (total_orders::numeric / NULLIF(lifespan_days, 0)) *
        365,
        2
    ) AS annualized_clv
FROM customer_metrics;





SELECT * FROM events
