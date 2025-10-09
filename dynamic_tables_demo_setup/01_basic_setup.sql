-- Select role and warehoue
-- --------------------------------
use role sysadmin;
use warehouse compute_wh;

-- Create databsae and schema.
-- ----------------------------------
create or replace database modern_db
comment = 'this is modern_db database for pipeline using dynamic tables';

use database modern_db;

create or replace schema source
comment = 'this is stage schema in modern_db database';
create or replace schema bronze
comment = 'this is bronze schema in modern_db database';
create or replace schema silver
comment = 'this is silver schema in modern_db database';
create or replace schema gold
comment = 'this is gold schema in modern_db database';


-- Create file format.
-- --------------------------
create or replace file format modern_db.source.csv_format
    type = 'csv' 
    compression = 'auto' 
    field_delimiter = ',' 
    record_delimiter = '\n'  
    field_optionally_enclosed_by = '\042' 
    skip_header = 1;

-- Create an internal stage location
-- -----------------------------------------
create or replace stage modern_db.source.landing_stage
file_format = (format_name = 'modern_db.source.csv_format')
directory = (enable = true)
comment = 'this is snowflake internal stage to stage the data files under the modern_db/source schema';


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


-- Create the Snowpipe for customers data
CREATE OR REPLACE PIPE copy_customer_raw_data_pipe
AUTO_INGEST = TRUE
AS
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

-- Create the Snowpipe for order data
CREATE OR REPLACE PIPE copy_order_raw_data_pipe
AUTO_INGEST = TRUE
AS
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

-- Check pipe status
SELECT SYSTEM$PIPE_STATUS('copy_customer_raw_data_pipe');

SELECT SYSTEM$PIPE_STATUS('copy_order_raw_data_pipe');

-- Manually trigger pipe for existing files (if needed)
-- ALTER PIPE copy_customer_raw_data_pipe REFRESH;

-- Pause/Resume pipe
-- ALTER PIPE copy_customer_raw_data_pipe SET PIPE_EXECUTION_PAUSED = TRUE;
-- ALTER PIPE copy_customer_raw_data_pipe SET PIPE_EXECUTION_PAUSED = FALSE;