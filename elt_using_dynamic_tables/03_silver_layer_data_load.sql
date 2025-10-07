ALTER SESSION SET TIMEZONE = 'Asia/Kolkata';
select current_timestamp();


-- changing the context
use role sysadmin;
use warehouse compute_wh;
use schema modern_db.silver;


create or replace warehouse dt_transform_wh 
    with 
    warehouse_size = 'xsmall' 
    warehouse_type = 'standard' 
    auto_suspend = 60 
    auto_resume = true 
    min_cluster_count = 1
    max_cluster_count = 1 
    scaling_policy = 'standard'
    initially_suspended = True;

CREATE OR REPLACE DYNAMIC TABLE modern_db.silver.customer_curated_dt
    TARGET_LAG='5 minutes'
    WAREHOUSE=dt_transform_wh
AS
SELECT
    cust_key,
    name,
    address,
    nation_name,
    phone,
    acct_bal,
    mkt_segment,
    load_ts,
    load_row_number,
    load_file_name
FROM modern_db.bronze.customer_raw
    QUALIFY ROW_NUMBER() OVER (PARTITION BY cust_key ORDER BY load_ts DESC) = 1

     
-- order dynamic table
CREATE OR REPLACE DYNAMIC TABLE modern_db.silver.order_curated_dt
    TARGET_LAG='5 minutes'
    WAREHOUSE=dt_transform_wh
AS
    SELECT
        order_key,
        cust_key,
        order_status,
        total_price,
        order_date,
        order_priority,
        clerk,
        ship_priority,
        load_ts,
        load_row_number,
        load_file_name
    FROM modern_db.bronze.order_raw
    QUALIFY ROW_NUMBER() OVER (PARTITION BY order_key ORDER BY load_ts DESC) = 1
