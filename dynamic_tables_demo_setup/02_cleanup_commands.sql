-- Silver layer cleanup commands
drop table if exists modern_db.silver.customer_curated_dt;
drop table if exists modern_db.silver.order_curated_dt;

-- Gold layer cleanup commands
drop table if exists modern_db.gold.dim_customer_dt;
drop table if exists modern_db.gold.dim_date_dt;
drop table if exists modern_db.gold.dim_priority_dt;
drop table if exists modern_db.gold.order_fact_dt;

-- Raw layer cleanup commands
TRUNCATE TABLE MODERN_DB.BRONZE.CUSTOMER_RAW;
TRUNCATE TABLE MODERN_DB.BRONZE.ORDER_RAW;
