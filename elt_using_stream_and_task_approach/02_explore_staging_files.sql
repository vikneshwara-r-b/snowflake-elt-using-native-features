use role sysadmin;
use warehouse compute_wh;
use schema classic_db.source;

-- check the data load before quering them

-- customer data set
list @classic_db.source.landing_stage/customer/;
list @classic_db.source.landing_stage/customer/bulk/;
list @classic_db.source.landing_stage/customer/delta/;

-- order data set
list @classic_db.source.landing_stage/order/;
list @classic_db.source.landing_stage/order/bulk/;
list @classic_db.source.landing_stage/order/delta/;

select 
    t.$1,t.$2,t.$3,t.$4,t.$5,t.$6,t.$7,
    current_timestamp(),
    metadata$file_row_number,
    metadata$filename
from @classic_db.source.landing_stage/customer/ as t;

-- order data
select 
    t.$1,t.$2,t.$3,t.$4,t.$5,t.$6,t.$7,t.$8,
    current_timestamp(),
    metadata$file_row_number,
    metadata$filename
from @classic_db.source.landing_stage/order/ as t;