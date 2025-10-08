use role sysadmin;
use warehouse compute_wh;
use schema classic_db.silver;



-- validate data set
select 
    t.$1,t.$2,t.$3,t.$4,t.$5,t.$6,t.$7,
    current_timestamp(),
    metadata$file_row_number,
    metadata$filename
from @classic_db.source.landing_stage/customer/ as t;--210 -- 420

-- order data
select 
    t.$1,t.$2,t.$3,t.$4,t.$5,t.$6,t.$7,t.$8,
    current_timestamp(),
    metadata$file_row_number,
    metadata$filename
from @classic_db.source.landing_stage/order/ as t;--2168 -- 4192
-- select stmt

-- raw
select count(*) from classic_db.bronze.customer_raw; --210
select count(*) from classic_db.bronze.customer_raw_stm; -- 
select count(*) from classic_db.bronze.order_raw; -- 2168
select count(*) from classic_db.bronze.order_raw_stm; -- 
    
-- clean
select count(*) from classic_db.silver.customer_curated;--210
select count(*) from classic_db.silver.customer_curated_stm; -- 
select count(*) from classic_db.silver.order_curated; -- 2168
select count(*) from classic_db.silver.order_curated_stm; -- 

--gold layer
select count(*) from classic_db.gold.dim_customer; --210
select count(*) from classic_db.gold.dim_date;--1424
select count(*) from classic_db.gold.dim_priority;--5
select count(*) from classic_db.gold.fact_order;--2168


-- load additional data
list @classic_db.source.landing_stage/customer/delta/; --

-- order data set
list @classic_db.source.landing_stage/order/delta/; --