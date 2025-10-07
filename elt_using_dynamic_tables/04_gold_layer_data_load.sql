-- changing the context
use role sysadmin;
use warehouse compute_wh;
use schema modern_db.gold;

-- customer dimension dim table
CREATE OR REPLACE DYNAMIC TABLE modern_db.gold.dim_customer_dt
    TARGET_LAG='downstream'
    WAREHOUSE=dt_transform_wh
AS
select
    cust_key,
    name,
    address,
    nation_name,
    phone,
    acct_bal,
    mkt_segment
from 
    modern_db.silver.customer_curated_dt;

-- date dim table
CREATE OR REPLACE DYNAMIC TABLE modern_db.gold.dim_date_dt
    TARGET_LAG='downstream'
    WAREHOUSE=dt_transform_wh
AS
select
    order_date,
    year(order_date) as order_year,
    quarter(order_date) as order_quarter,
    month(order_date) as order_month,
    week(order_date) as order_week,
    dayofmonth(order_date) as order_day
from 
    modern_db.silver.order_curated_dt 
group by 
    order_date,
    order_year,
    order_quarter,
    order_month,
    order_week,
    order_day;

-- priority dim table
CREATE OR REPLACE DYNAMIC TABLE modern_db.gold.dim_priority_dt
    TARGET_LAG='downstream'
    WAREHOUSE=dt_transform_wh
AS
select
    order_priority
from 
    modern_db.silver.order_curated_dt 
group by order_priority;


-- fact table
CREATE OR REPLACE DYNAMIC TABLE modern_db.gold.order_fact_dt
    TARGET_LAG='5 minutes'
    WAREHOUSE=dt_transform_wh
    REFRESH_MODE=INCREMENTAL 
AS
select
    oc.cust_key,
    oc.order_date,
    pd.order_priority,
    oc.order_key,
    oc.total_price
from 
    modern_db.silver.order_curated_dt oc
    join modern_db.gold.dim_customer_dt cd on cd.cust_key = oc.cust_key
    join modern_db.gold.dim_date_dt dd on dd.order_date = oc.order_date
    join modern_db.gold.dim_priority_dt pd on pd.order_priority = oc.order_priority;