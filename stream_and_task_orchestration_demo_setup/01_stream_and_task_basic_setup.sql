-- Select role and warehoue
-- --------------------------------
use role sysadmin;
use warehouse compute_wh;

-- Create databsae and schema.
-- ----------------------------------
create or replace database classic_db
comment = 'this is classic_db database for stream & task demo';

use database classic_db;

create or replace schema source
comment = 'this is stage schema in classic_db database';
create or replace schema bronze
comment = 'this is bronze schema in classic_db database';
create or replace schema silver
comment = 'this is silver schema in classic_db database';
create or replace schema gold
comment = 'this is gold schema in classic_db database';
create or replace schema orchestration
comment = 'this schema would store all task definitions and orchestration metadata'
-- Create file format.
-- --------------------------
create or replace file format classic_db.source.csv_format
    type = 'csv' 
    compression = 'auto' 
    field_delimiter = ',' 
    record_delimiter = '\n'  
    field_optionally_enclosed_by = '\042' 
    skip_header = 1;

-- Create an internal stage location
-- -----------------------------------------
create or replace stage classic_db.source.landing_stage
DIRECTORY = (ENABLE = TRUE)
file_format = (format_name = 'classic_db.source.csv_format')
comment = 'this is snowflake internal stage to stage the data files under the classic_db/source schema';

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


-- creating tables in silver layer
create or replace table classic_db.silver.customer_curated (
    c_id int primary key autoincrement,
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

create or replace stream classic_db.silver.customer_curated_stm 
    on table classic_db.silver.customer_curated;

-- silver order table
create or replace table classic_db.silver.order_curated (
    o_id int primary key autoincrement,
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


-- customer dim table
create or replace table classic_db.gold.dim_customer (
    c_dim_id int primary key autoincrement,
    cust_key number,
    name text,
    address text,
    nation_name text,
    phone text,
    acct_bal number,
    mkt_segment text
);

-- date dim table
create or replace table classic_db.gold.dim_date (
    d_dim_id int primary key autoincrement,
    order_dt date,
    order_year number(4) default -1,
    order_quarter number(1) default -1,
    order_month number(2) default -1,
    order_week number(2) default -1,
    order_day number(2) default -1
);

-- priority dim table
create or replace table classic_db.gold.dim_priority (
    p_dim_id int primary key autoincrement,
    order_priority text
);

--- order fact table
create or replace table classic_db.gold.fact_order (
    o_fact_id int primary key autoincrement,
    d_dim_id_fk number,
    c_dim_id_fk number,
    p_dim_id_fk number,
    order_key number,
    total_price number
);


