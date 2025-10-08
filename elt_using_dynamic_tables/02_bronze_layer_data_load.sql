
-- changing the context
use role sysadmin;
use warehouse compute_wh;
use schema modern_db.bronze;

-- create tables inside the raw layer
-- ----------------------------------
create or replace table modern_db.bronze.customer_raw (
    cust_key number,
    name text,
    address text,
    nation_name text,
    phone text,
    acct_bal number,
    mkt_segment text,
    load_ts timestamp,
    load_row_number number,
    load_file_name text 
);

-- creating order table with 11 columns
create or replace table modern_db.bronze.order_raw (
    order_key number,
    cust_key number,
    order_status text(1),
    total_price number,
    order_date date,
    order_priority text,
    clerk text,
    ship_priority number(1),
    load_ts timestamp,
    load_row_number number,
    load_file_name text 
);

-- creating a new warehosue
create or replace warehouse dt_task_load_wh 
    with 
    warehouse_size = 'xsmall' 
    warehouse_type = 'standard' 
    auto_suspend = 60 
    auto_resume = true 
    min_cluster_count = 1
    max_cluster_count = 1 
    scaling_policy = 'standard'
    initially_suspended = True;

    
create or replace task modern_db.bronze.copy_to_customer_raw_task
warehouse = dt_task_load_wh
schedule = '2 minute'
as
copy into modern_db.bronze.customer_raw from 
(
select 
    t.$1,t.$2,t.$3,t.$4,t.$5,t.$6,t.$7,
    current_timestamp(),
    metadata$file_row_number,
    metadata$filename
from @modern_db.source.landing_stage/customer/ as t
)
file_format = (format_name = 'modern_db.source.csv_format');

-- order data
create or replace task modern_db.bronze.copy_to_order_raw_task
warehouse = compute_wh
after modern_db.bronze.copy_to_customer_raw_task
as
copy into modern_db.bronze.order_raw from 
(
select 
    t.$1,t.$2,t.$3,t.$4,t.$5,t.$6,t.$7,t.$8,
    current_timestamp(),
    metadata$file_row_number,
    metadata$filename
from @modern_db.source.landing_stage/order/ as t
)
file_format = (format_name = 'modern_db.source.csv_format');

alter task modern_db.bronze.copy_to_order_raw_task resume;
alter task modern_db.bronze.copy_to_customer_raw_task resume;

alter task modern_db.bronze.copy_to_customer_raw_task suspend;
alter task modern_db.bronze.copy_to_order_raw_task suspend;