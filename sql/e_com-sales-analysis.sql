# https://www.kaggle.com/datasets/thedevastator/unlock-profits-with-e-commerce-sales-data   👉 Dataset link

use sales;

# Question 1. How many orders are entering the system?

select count('order id') from amazon_sale_report;

# Question 2. How many orders successfully convert into delivered ?

select status, count(*) as order_counts 
from amazon_sale_report
where status = 'Shipped - Delivered to Buyer';

# Question 3. What % of orders fail before delivery? (conversion drop-off) 👉 This is the first revenue leakage metric
SELECT 
  ROUND(
    SUM(CASE WHEN status = 'Shipped - Returned to Seller' THEN 1 ELSE 0 END) * 100.0 /
    SUM(CASE WHEN status IN ('Shipped - Delivered to Buyer','Shipped - Returned to Seller') THEN 1 ELSE 0 END),
  2) AS failure_pct
FROM amazon_sale_report;

# Question 4 - Which order statuses cause the highest drop-off? 👉 Insight intent: identify where to intervene

select status, count(status) from amazon_sale_report
group by status
order by count(status) desc;

# Question 5 - Which drop-off causes the highest revenue loss? 👉 This separates volume problems from money problems

SELECT
Status,
SUM(Amount) AS revenue_lost
FROM amazon_sale_report
WHERE Status in(
'Cancelled',
'Shipped - Returned to Seller',
'Shipped - Returning to Seller',
'Shipped - Rejected by Buyer',
'Shipped - Lost in Transit',
'Shipped - Damaged')
GROUP BY Status
ORDER BY revenue_lost DESC;

# Question 6 - How many delivered orders actually generate profit?

SELECT COUNT(DISTINCT `Order ID`) AS delivered_orders
FROM amazon_sale_report
WHERE Status = 'Shipped - Delivered to Buyer';

# Question 7 - What % of total revenue is lost due to failed orders?

SELECT
  ROUND(
    SUM(CASE 
        WHEN Status IN (
            'Cancelled',
            'Shipped - Returned to Seller',
            'Shipped - Returning to Seller',
            'Shipped - Rejected by Buyer',
            'Shipped - Lost in Transit',
            'Shipped - Damaged'
        ) THEN Amount ELSE 0 
    END) * 100.0
    /
    SUM(Amount),
  2) AS revenue_leakage_pct
FROM amazon_sale_report;


# Question 8 - Where is revenue leaking the most in the order-to-delivery funnel?

SELECT
  IF(
    Status IN ('Cancelled','Shipped - Rejected by Buyer'),
    'Customer-driven',
    'Logistics-driven'
  ) AS failure_type,
  CONCAT('₹', FORMAT(SUM(Amount), 2)) AS revenue_lost
FROM amazon_sale_report
WHERE Status IN (
  'Cancelled',
  'Shipped - Rejected by Buyer',
  'Shipped - Returned to Seller',
  'Shipped - Returning to Seller',
  'Shipped - Lost in Transit',
  'Shipped - Damaged'
)
GROUP BY failure_type;


# Question 9 - Are losses concentrated in specific regions?

SELECT
  IFNULL(`ship-state`, 'TOTAL') AS region,
  CONCAT('₹', FORMAT(SUM(Amount), 2)) AS revenue_lost
FROM amazon_sale_report
WHERE Status IN (
  'Cancelled',
  'Shipped - Returned to Seller',
  'Shipped - Returning to Seller',
  'Shipped - Rejected by Buyer',
  'Shipped - Lost in Transit',
  'Shipped - Damaged'
)
GROUP BY `ship-state` WITH ROLLUP;

# Question 10 - Is revenue growing while revenue leakage is increasing over time?


SELECT
  IFNULL(DATE_FORMAT(Date,'%Y-%m'),'Without Dates') AS month,
  CONCAT('₹',FORMAT(SUM(Amount),2)) AS revenue,
  CONCAT('₹',FORMAT(SUM(CASE WHEN Status IN (
    'Cancelled',
    'Shipped - Returned to Seller',
    'Shipped - Returning to Seller',
    'Shipped - Rejected by Buyer',
    'Shipped - Lost in Transit',
    'Shipped - Damaged'
  ) THEN Amount ELSE 0 END),2)) AS leakage
FROM amazon_sale_report
GROUP BY month

UNION ALL

SELECT
  'TOTAL',
  CONCAT('₹',FORMAT(SUM(Amount),2)),
  CONCAT('₹',FORMAT(SUM(CASE WHEN Status IN (
    'Cancelled',
    'Shipped - Returned to Seller',
    'Shipped - Returning to Seller',
    'Shipped - Rejected by Buyer',
    'Shipped - Lost in Transit',
    'Shipped - Damaged'
  ) THEN Amount ELSE 0 END),2))
FROM amazon_sale_report;


# Question 11 - Is revenue growing while revenue leakage is increasing over time?

SELECT
  IFNULL(DATE_FORMAT(Date,'%Y-%m'),'Without Dates') AS month,
  CONCAT('₹',FORMAT(SUM(Amount),2)) AS revenue,
  CONCAT('₹',FORMAT(SUM(CASE WHEN Status IN (
    'Cancelled',
    'Shipped - Returned to Seller',
    'Shipped - Returning to Seller',
    'Shipped - Rejected by Buyer',
    'Shipped - Lost in Transit',
    'Shipped - Damaged'
  ) THEN Amount ELSE 0 END),2)) AS leakage
FROM amazon_sale_report
GROUP BY month

UNION ALL

SELECT
  'TOTAL',
  CONCAT('₹',FORMAT(SUM(Amount),2)),
  CONCAT('₹',FORMAT(SUM(CASE WHEN Status IN (
    'Cancelled',
    'Shipped - Returned to Seller',
    'Shipped - Returning to Seller',
    'Shipped - Rejected by Buyer',
    'Shipped - Lost in Transit',
    'Shipped - Damaged'
  ) THEN Amount ELSE 0 END),2))
FROM amazon_sale_report;






