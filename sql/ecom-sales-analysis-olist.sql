create database olist_db;

use olist_db;

# 1️. What is the average time from purchase to delivery? (Primary Velocity KPI)

select round(avg(datediff(order_delivered_customer_date, order_purchase_timestamp)), 2)
as avg_delivery_days
from olist_orders_dataset
where order_status = 'delivered';


# 2. What is the average time taken at each funnel stage?  (Purchase → Approval → Shipping → Delivery)

select concat(round(avg(datediff(order_approved_at, order_purchase_timestamp)), 2), ' days') as purchase_to_approval, 
		concat(round(avg(datediff(order_delivered_carrier_date, order_approved_at)), 2), ' days') as approval_to_shipping,
        concat(round(avg(datediff(order_delivered_customer_date, order_delivered_carrier_date)),2), ' days') as shipping_to_delivery
from olist_orders_dataset
where order_status = 'delivered';

# 3. Which stage is the slowest in the funnel?

select 'purchase_to_approval' as stage,
concat(round(avg(datediff(order_approved_at, order_purchase_timestamp)), 2), ' days') as avg_days
from olist_orders_dataset
where order_status = 'delivered'
union all
select 'shipping_to_delivery' ,
concat(round(avg(datediff(order_delivered_customer_date, order_delivered_carrier_date)),2), ' days') 
from olist_orders_dataset
where order_status = 'delivered'
order by avg_days desc
limit 1;

# 4️. How many orders never reached delivery? (Stuck deals)

select count(*) as order_not_delivered 
from olist_orders_dataset 
where order_status != 'delivered';

# 5. Where do most orders get stuck in the funnel?

select order_status, count(*) as order_not_delivered 
from olist_orders_dataset 
where order_status != 'delivered'
group by order_status
order by order_not_delivered desc;

# 6. What % of orders are stuck before delivery? (Velocity failure rate)

select 
concat(round(count(*) * 100/ (select count(*) from olist_orders_dataset), 2), ' %') as order_not_delivered 
from olist_orders_dataset 
where order_status != 'delivered';

# 7️. How many orders were delivered late (aging beyond SLA)?

select count(*) as delayed_orders,
concat(round(count(*) * 100/ (select count(*) from olist_orders_dataset), 2), ' %') as percent
from olist_orders_dataset
WHERE order_delivered_customer_date > order_estimated_delivery_date;


# 8️. What is the average delivery delay (late orders only)?

select round(avg(datediff(order_delivered_customer_date, order_estimated_delivery_date))) as avg_delay
from olist_orders_dataset
WHERE order_delivered_customer_date > order_estimated_delivery_date;


# 9. On-time vs Late delivery distribution

select case
when  order_delivered_customer_date <= order_estimated_delivery_date 
then 'on_time'
else 'late'
end as delivery_status, 
count(*) as orders
from olist_orders_dataset
WHERE order_status='delivered'
group by delivery_status;


# 10. Is delivery velocity improving over time?

select 
date_format(order_purchase_timestamp,'%Y-%m') as month,
round(avg(datediff(order_delivered_customer_date, order_purchase_timestamp)), 2) as avg_delivery_days
from olist_orders_dataset
WHERE order_status='delivered'
group by month
order by month;

# 11. Do late deliveries lead to lower review scores?

SELECT 
CASE 
WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
THEN 'Late'
ELSE 'On Time'
END AS delivery_type,
ROUND(AVG(r.review_score),2) AS avg_review
FROM olist_orders_dataset o
JOIN olist_order_reviews_dataset r
ON o.order_id = r.order_id
GROUP BY delivery_type;


# 1️2. Average shipping time (carrier to customer)

select 
concat(round(avg(datediff(order_delivered_customer_date, order_delivered_carrier_date)), 2), ' days')
as car_to_cust
from olist_orders_dataset;

# 13. Orders that took extremely long (>30 days)

select 
count(*) as slow_delivery 
from olist_orders_dataset
where (datediff(order_delivered_customer_date, order_purchase_timestamp)) > 30;

# 14. Revenue tied to late deliveries (Business impact of slow velocity)

select round(sum(p.payment_value), 2) as revenue
from olist_order_payments_dataset p
join olist_orders_dataset o
on p.order_id = o.order_id
where o.order_delivered_customer_date > o.order_estimated_delivery_date;




