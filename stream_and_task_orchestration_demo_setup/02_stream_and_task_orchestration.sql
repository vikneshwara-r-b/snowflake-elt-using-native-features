-- run copy command and check data set
 create or replace task classic_db.orchestration.root_task
	warehouse=compute_wh
	schedule='60 minutes'
	as select current_role();

    

    create or replace task classic_db.orchestration.copy_to_customer_bronze_task
    warehouse = compute_wh
    after classic_db.orchestration.root_task
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
    create or replace task classic_db.orchestration.copy_to_order_bronze_task
    warehouse = compute_wh
    after classic_db.orchestration.root_task
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

    -- creating task to copy data from stream to clean customer table
create or replace task classic_db.orchestration.populate_curated_customer_task
    warehouse = compute_wh
    after classic_db.orchestration.copy_to_customer_bronze_task
    when system$stream_has_data('classic_db.bronze.customer_raw_stm')
        as
    merge into classic_db.silver.customer_curated target_clean 
    using (
            select
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
            from 
                classic_db.bronze.customer_raw_stm 
            qualify row_number() over (partition by cust_key order by load_ts desc) = 1
        ) source_raw on
    target_clean.cust_key = source_raw.cust_key
    when matched
    then update set
        target_clean.cust_key = source_raw.cust_key,
        target_clean.name = source_raw.name,
        target_clean.address = source_raw.address,
        target_clean.nation_name = source_raw.nation_name,
        target_clean.phone = source_raw.phone,
        target_clean.acct_bal = source_raw.acct_bal,
        target_clean.mkt_segment = source_raw.mkt_segment,
        target_clean.load_ts = source_raw.load_ts,
        target_clean.load_row_number = source_raw.load_row_number,
        target_clean.load_file_name = source_raw.load_file_name
    when not matched
    then insert (cust_key,name,address,nation_name,phone,acct_bal,mkt_segment,load_ts,load_row_number,load_file_name)
    values 
    (
        source_raw.cust_key,
        source_raw.name,
        source_raw.address,
        source_raw.nation_name,
        source_raw.phone,
        source_raw.acct_bal,
        source_raw.mkt_segment,
        source_raw.load_ts,
        source_raw.load_row_number,
        source_raw.load_file_name
    );


    
-- clean order task 
    create or replace task classic_db.orchestration.populate_curated_order_task
    warehouse = compute_wh
    after classic_db.orchestration.copy_to_order_bronze_task
    when system$stream_has_data('classic_db.bronze.order_raw_stm')
        as
    merge into classic_db.silver.order_curated target_clean 
    using (
            select
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
            from 
                classic_db.bronze.order_raw_stm
                qualify row_number() over (partition by order_key order by load_ts desc) = 1
        ) source_raw on
    target_clean.cust_key = source_raw.cust_key
    when matched
    then update set
            target_clean.cust_key = source_raw.cust_key,
            target_clean.order_status = source_raw.order_status,
            target_clean.total_price = source_raw.total_price,
            target_clean.order_date = source_raw.order_date,
            target_clean.order_priority = source_raw.order_priority,
            target_clean.clerk = source_raw.clerk,
            target_clean.ship_priority = source_raw.ship_priority,
            target_clean.load_ts = source_raw.load_ts,
            target_clean.load_row_number = source_raw.load_row_number,
            target_clean.load_file_name  = source_raw.load_file_name
    when not matched
    then insert (order_key,cust_key,order_status,total_price,order_date,order_priority,clerk,ship_priority,load_ts,load_row_number,load_file_name  )
    values 
    (
        source_raw.order_key,
        source_raw.cust_key,
        source_raw.order_status,
        source_raw.total_price,
        source_raw.order_date,
        source_raw.order_priority,
        source_raw.clerk,
        source_raw.ship_priority,
        source_raw.load_ts,
        source_raw.load_row_number,
        source_raw.load_file_name  
    );


-- task to populate 
-- the merge statement
create or replace task classic_db.orchestration.populate_dim_customer_task
    warehouse = compute_wh
    after classic_db.orchestration.populate_curated_customer_task
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
    create or replace task classic_db.orchestration.populate_dim_date_task
    warehouse = compute_wh
    after classic_db.orchestration.populate_curated_order_task
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

    create or replace task classic_db.orchestration.populate_dim_priority_task
    warehouse = compute_wh
    after classic_db.orchestration.populate_curated_order_task
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


   create or replace task classic_db.orchestration.populate_fact_order_task
    warehouse = compute_wh
    after classic_db.orchestration.populate_dim_customer_task,classic_db.orchestration.populate_dim_date_task,classic_db.orchestration.populate_dim_priority_task
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
