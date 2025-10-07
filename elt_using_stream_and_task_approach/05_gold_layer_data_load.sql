
use role sysadmin;
use warehouse compute_wh;
use schema classic_db.gold;

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

-- task to populate 
-- the merge statement
create or replace task classic_db.bronze.populate_dim_customer_task
    warehouse = compute_wh
    after classic_db.bronze.populate_curated_customer_task
    when system$stream_has_data('classic_db.silver.customer_curated_stm')
        as
    merge into classic_db.gold.dim_customer to_dim 
    using (
            select
                cust_key,
                name,
                address,
                nation_name,
                phone,
                acct_bal,
                mkt_segment
            from 
                classic_db.silver.customer_curated_stm
        ) from_clean on
    to_dim.cust_key = from_clean.cust_key
    when matched
    then update set
        to_dim.name = from_clean.name,
        to_dim.address = from_clean.address,
        to_dim.nation_name = from_clean.nation_name,
        to_dim.phone = from_clean.phone,
        to_dim.acct_bal = from_clean.acct_bal,
        to_dim.mkt_segment = from_clean.mkt_segment
    when not matched
    then insert (cust_key,name,address,nation_name,phone,acct_bal,mkt_segment)
    values 
    (
        from_clean.cust_key,
        from_clean.name,
        from_clean.address,
        from_clean.nation_name,
        from_clean.phone,
        from_clean.acct_bal,
        from_clean.mkt_segment
    );


    -- date is populated
    create or replace task classic_db.bronze.populate_dim_date_task
    warehouse = compute_wh
    after classic_db.bronze.populate_curated_order_task
    when system$stream_has_data('classic_db.silver.order_curated_stm_for_dt')
        as
    merge into classic_db.gold.dim_date to_dim 
    using (
            select
                order_date
            from 
                classic_db.silver.order_curated_stm_for_dt 
            group by order_date
        ) from_clean on
    to_dim.order_dt = from_clean.order_date
    when not matched
    then insert (order_dt,order_year,order_quarter,order_month,order_week,order_day )
    values 
    (
        from_clean.order_date,
        year(from_clean.order_date),
        quarter(from_clean.order_date),
        month(from_clean.order_date),
        week(from_clean.order_date),
        dayofmonth(from_clean.order_date)
        
    );

    create or replace task classic_db.bronze.populate_dim_priority_task
    warehouse = compute_wh
    after classic_db.bronze.populate_curated_order_task
    when system$stream_has_data('classic_db.silver.order_curated_stm_for_priority')
        as
    merge into classic_db.gold.dim_priority to_dim 
    using (
            select
                order_priority
            from 
                classic_db.silver.order_curated_stm_for_priority 
            group by order_priority
        ) from_clean on
    to_dim.order_priority = from_clean.order_priority
    when not matched
    then insert (order_priority)
    values 
    (
        from_clean.order_priority
    );


   create or replace task classic_db.bronze.populate_fact_order_task
    warehouse = compute_wh
    after classic_db.bronze.populate_dim_customer_task,classic_db.bronze.populate_dim_date_task,classic_db.bronze.populate_dim_priority_task
    when system$stream_has_data('classic_db.silver.order_curated_stm')
        as
    merge into classic_db.gold.fact_order to_fact 
    using (
            select
                cd.c_dim_id,
                dd.d_dim_id,
                pd.p_dim_id,
                oc.order_key,
                oc.total_price
            from 
                classic_db.silver.order_curated_stm oc
                join classic_db.gold.dim_customer cd on cd.cust_key = oc.cust_key
                join classic_db.gold.dim_date dd on dd.order_dt = oc.order_date
                join classic_db.gold.dim_priority pd on pd.order_priority = oc.order_priority
                
        ) from_clean on
    to_fact.order_key = from_clean.order_key
    when not matched
    then insert (d_dim_id_fk,c_dim_id_fk,p_dim_id_fk,order_key,total_price)
    values 
    (
        from_clean.c_dim_id ,
        from_clean.d_dim_id ,
        from_clean.p_dim_id ,
        from_clean.order_key ,
        from_clean.total_price
        
    );