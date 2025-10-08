
use role sysadmin;
use warehouse compute_wh;
use schema classic_db.bronze;


-- create tables inside the bronze layer
-- ----------------------------------
create or replace table classic_db.bronze.customer_raw (
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

-- creating stream on customer_raw to track the changes
create or replace stream classic_db.bronze.customer_raw_stm 
    on table classic_db.bronze.customer_raw
    append_only = true;

-- creating order table with 11 columns
create or replace table classic_db.bronze.order_raw (
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

-- creating stream
create or replace stream classic_db.bronze.order_raw_stm 
    on table classic_db.bronze.order_raw
    append_only = true;

-- run copy command and check data set
 create or replace task classic_db.bronze.root_task
	warehouse=compute_wh
	schedule='60 minutes'
	as select current_role();

    

    create or replace task classic_db.bronze.copy_to_customer_bronze_task
    warehouse = compute_wh
    after classic_db.bronze.root_task
    as
    copy into classic_db.bronze.customer_raw from 
    (
    select 
        t.$1,t.$2,t.$3,t.$4,t.$5,t.$6,t.$7,
        current_timestamp(),
        metadata$file_row_number,
        metadata$filename
    from @classic_db.source.landing_stage/customer/ as t
    )
    file_format = (format_name = 'classic_db.source.csv_format');

    -- order data
    create or replace task classic_db.bronze.copy_to_order_bronze_task
    warehouse = compute_wh
    after classic_db.bronze.root_task
    as
    copy into classic_db.bronze.order_raw from 
    (
    select 
        t.$1,t.$2,t.$3,t.$4,t.$5,t.$6,t.$7,t.$8,
        current_timestamp(),
        metadata$file_row_number,
        metadata$filename
    from @classic_db.source.landing_stage/order/ as t
    )
    file_format = (format_name = 'classic_db.source.csv_format');

-- vist the home page and validate the objects