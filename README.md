# 1.Project Overview
## Business Problem
Understand customer behavior, marketing effectiveness, and product performance to identify growth opportunities, improve retention, and maximize revenue
## Project Objectives
Analyze customer behavior, marketing performance, and product effectiveness to uncover growth opportunities, improve retention, and drive sustainable revenue growth.
## Key Questions Addressed
1. How effective are marketing campaigns? 
2. How do customers behave across the purchase journey?
3. Which customer segments drive the most value? 
4. What product and pricing factors most influence revenue and profitability?
# 2. Dataset
## Dataset source
- Source: [Marketing & E-Commerce Analytics Dataset from Kaggle](https://www.kaggle.com/datasets/geethasagarbonthu/marketing-and-e-commerce-analytics-dataset?select=customers.csv)
- This is a realistic, multi-table synthetic dataset designed to simulate a modern e-commerce business environment.
- It includes customer profiles, products, marketing campaigns, user behavior events, and purchase transactions.
- The dataset supports a wide range of analytical applications, including EDA, funnel analysis, A/B testing, uplift modeling, customer segmentation, and product performance evaluation.
- All data is synthetically generated using Python and contains no real customer or business information.
## Key table and variables
- Customers: `customer_id`, `signup_date`, `country`, `age`, `gender`, `loyalty_tier`, `acquisition_channel`
- Events: `event_id`, `timestamp`, `customer_id`, `session_id`, `event_type`, `product_id`, `device_type`, `traffic_source`, `campaign_id`, `page_category`, `session_duration_sec`, `experiment_group`
- Transactions: `transaction_id`, `timestamp`, `customer_id`, `product_id`, `quantity`, `discount_applied`, `gross_revenue`, `campaign_id`, `refund_flag`
- Products: `product_id`, `category`, `brand`, `base_price`, `launch_date`, `is_premium`
- Campaigns: `campaign_id`, `channel`, `objective`, `start_date`, `end_date`, `target_segment`, `expected_uplift`
# 3. Methodology
## Data Cleaning and Preperation
- Checked for missing values and handled null records appropriately.
- Identified and removed duplicate entries to ensure data accuracy.
- Validated data types and corrected formatting inconsistencies.
- Standardized categorical variables, date formats, and naming conventions across tables.
- Merged relevant tables, including customers, events, transactions, products, and campaigns.
- Created derived metrics such as conversion rate, customer lifetime value (CLV), average order value (AOV), and campaign response indicators.
- Verified data integrity and consistency after transformation.
- Prepared the final analytical dataset for exploratory analysis, statistical modeling, and business insights generation.
## Exporatory Data Analysis
- Assessed data completeness and structure across all major tables.
- Examined temporal patterns and seasonality in user activity.
- Analyzed customer behavior across the conversion funnel.
- Evaluated distributions of key numerical variables.
- Identified outliers using percentile and IQR methods.
- Explored customer demographics and acquisition channels.
- Investigated product portfolio composition and pricing structure.
- Assessed campaign targeting and experimental group distribution.
- Examined relationships between behavioral, transactional, and marketing variables.
# 4.Key insights
## A. Campaign Analysis
### 1. Revenue is concentrated in a small number of campaigns
- Campaigns 5, 18, and 29 generated the highest total revenue.
- This suggests that a limited number of campaigns are responsible for a disproportionately large share of overall sales.
- These top-performing campaigns should be analyzed further to identify the factors driving their success, such as targeting strategy, messaging, timing, or promotional offers.
### Recommendations
- Increase budget allocation toward campaigns 5, 18, and 29. Identify and replicate their successful attributes across future campaigns.
### 2. High engagement does not necessarily translate into high revenue
- Campaign 14 achieved the highest click-through rate (CTR), indicating strong audience engagement.
- However, it was not among the top revenue-generating campaigns. This highlights a gap between initial interest and final purchase behavior, suggesting that attracting clicks alone is not sufficient to maximize revenue.
### Recommendations
Optimize high-CTR but low-revenue campaigns by:
- Investigate why Campaign 14 generates strong engagement but weaker monetization.
- Potential areas for improvement include: Landing page relevance, Offer alignment, Checkout experience, Audience targeting
### 3. Affiliate is the strongest revenue-generating channel
- Among all marketing channels, Affiliate delivered the highest total revenue. This indicates that affiliate traffic is highly monetizable and likely attracts users with stronger purchase intent.
- In contrast, Social generated the lowest revenue, suggesting weaker monetization efficiency.
### Recommendations
- Prioritize Affiliate for revenue growth
- Expand partnerships and investment in the Affiliate channel.
- Focus on scaling affiliate programs while maintaining partner quality.
### 4. Paid Search is the most effective channel for customer acquisition
- Paid Search brought in the largest number of unique customers.
- This makes it the strongest channel for expanding customer reach and acquiring new users at scale.
### Recommendations
- Reassess Social channel strategy
- Review Social campaigns to determine whether they should focus on:
- Brand awareness rather than direct conversions, or improved audience targeting and creative optimization.
## B. Customer Behavior
### 1. Customer sessions are relatively short and focused
- The median session duration is approximately 199 seconds (around 3.3 minutes).
- This suggests that most visitors engage in quick, goal-oriented browsing rather than extended exploration.
```sql
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
```
### Recommendations
Strengthen the Home page as a conversion gateway
- Given its high dwell time, the Home page should effectively direct users toward key actions.
- Consider: Personalized product recommendations, Featured promotions
### 2. User journeys are concise
- The median number of events per session is only 2 interactions.
- Most sessions involve limited engagement, implying that users either find what they need quickly or leave early.
- This also suggests there may be opportunities to encourage deeper exploration.
```sql
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
```
### Recommendations
Encourage deeper session engagement
- With only two median events per session, there is room to increase interaction depth.
- Tactics may include: Cross-selling recommendations, Related product suggestions, Recently viewed items.
### 3. Customer retention is strong
- Nearly 100,000 customers returned for more than one session.
- Returning customers visit the site an average of 10 times, indicating high engagement and repeat interest.
```sql
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
```
### Recommendations
Segment first-time vs. returning visitors
- Compare behavior between new and returning customers to identify differences in: Conversion rates, Average order value, Browsing depth. This will support more tailored marketing and UX strategies.
### 4. Users predominantly move back and forth between product detail pages (PDP) and product listing pages (PLP)
- Most common behavior: Users frequently navigate back and forth between PDP and PLP (Product Detail Page ↔ Product Listing Page).
- Trend of returning to homepage: There are many sessions where users return to Home after browsing PLP or PDP, suggesting that users may not have found the desired product.
- Journey leading to cart/checkout: Sequences such as PDP->Cart, PLP->Checkout reflect steps closer to conversion.
```sql
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
```
### Recommendations
- Preserve filters and scroll position when users return to PLP from PDP to reduce friction during product comparison.
- Add "Recently Viewed" or "Compare" features so users don't need to navigate back and forth multiple times.
- Improve product recommendations on PLP (e.g., add "Similar Products", "Suggestions based on browsing history").
### 5. While the website drives strong engagement with high click-through and add-to-cart rates, the biggest drop-off occurs at checkout
- CTR (click-through rate) = click / view = 0.36  → About 36% of views lead to clicks. This is relatively high, showing that the website and products are attractive.

- Add-to-cart rate = add_to_cart / click = 0.75  → 75% of clicks result in adding items to the cart. This is excellent, indicating strong purchase intent after clicking.

- Purchase rate = purchase / add_to_cart = 0.36  → 36% of cart additions lead to purchases. This is the biggest drop in the funnel, showing many users abandon their carts before checkout.

- View-to-purchase rate = purchase / view = 0.10  → Only 10% of views result in purchases. This is the final conversion rate, reflecting overall website effectiveness.
```sql
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
```
### Recomendations
- Focus on optimizing the checkout flow: simplify the process, make costs transparent, and provide more payment methods.
- Reduce cart abandonment with reminder emails, promotions, or remarketing campaigns.
- Track detailed user behavior to identify the exact causes of drop-off.
## C. Customer Segmentaion Analysis
### 1. Revenue is driven by broad, mass-market customer segments
- Bronze-tier customers contribute the highest total revenue, outperforming higher loyalty tiers.
- The 35–44 age group generates the most revenue among all age segments.
- Geographically, the United States is the largest revenue contributor by a substantial margin.
### Recommendations
Protect and grow the core revenue segment
- Prioritize retention and engagement strategies for:
+ Bronze-tier customers
+ Customers aged 35–44
+ The U.S. market
### 2. Premium customers generate value but also carry higher return risk
- Although premium loyalty tiers typically represent highly valuable customers, the Platinum segment has the highest refund rate.
- This suggests that high-value customers may also have higher expectations regarding product quality, service, or purchase fit.
```sql
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
```
### Recommendations
Improve retention and upgrade pathways for Bronze customers
- Since Bronze customers generate the largest revenue pool, there is significant opportunity to increase their lifetime value.
- Develop strategies to move these customers into higher loyalty tiers through: Tier-based rewards, Exclusive offers, Personalized recommendations
- The goal is to convert volume into long-term value.
## D. Product And Revenue Analysis
### 1. Premium products deliver higher value—but at a higher risk
- Premium products exhibit a higher refund rate than non-premium products.
- While premium items likely contribute higher margins and order values, they also carry greater post-purchase risk.
```sql
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
```
### Recommendations
Reduce refund rates for premium products
- Conduct a root-cause analysis to identify why premium products are returned more frequently.
- Focus on: Product quality assurance, More accurate product descriptions, Enhanced product imagery and specifications
### 2. Discounts improve conversion, but not necessarily revenue
- Higher discount levels are associated with higher purchase rates, indicating that discounts are effective at driving conversions.
- However, discounted transactions do not consistently generate higher total revenue.
```sql
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
```
### Recommendations
- Optimize discount strategy for profitability, not just conversion
- Shift from broad discounting to more targeted promotional strategies.
- Consider: Segment-specific discounts, Personalized offers for price-sensitive customers

# Conclusion
This project provided a comprehensive evaluation of marketing performance, customer behavior, and product effectiveness in a modern e-commerce environment. The analysis identified key revenue drivers, high-performing acquisition channels, valuable customer segments, and important behavioral patterns across the customer journey.

Overall, the findings highlight that sustainable growth depends on optimizing campaign effectiveness, improving customer retention, enhancing the shopping experience, and balancing conversion growth with long-term profitability. These insights can support more data-driven decision-making and help drive future business performance.