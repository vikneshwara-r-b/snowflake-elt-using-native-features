use role sysadmin;
use warehouse compute_wh;
use schema classic_db.bronze;

use role accountadmin;
grant execute task, execute managed task on account to role sysadmin;
use role sysadmin;

-- resume statements..
alter task classic_db.bronze.populate_fact_order_task resume;
alter task classic_db.bronze.populate_dim_priority_task resume;
alter task classic_db.bronze.populate_dim_date_task resume;
alter task classic_db.bronze.populate_dim_customer_task resume;
alter task classic_db.bronze.populate_curated_order_task resume;
alter task classic_db.bronze.populate_curated_customer_task resume;
alter task classic_db.bronze.copy_to_order_bronze_task resume;
alter task classic_db.bronze.copy_to_customer_bronze_task resume;
alter task classic_db.bronze.root_task resume;

-- suspend statements..
alter task classic_db.bronze.root_task suspend;
alter task classic_db.bronze.copy_to_customer_bronze_task suspend;
alter task classic_db.bronze.copy_to_order_bronze_task suspend;
alter task classic_db.bronze.populate_curated_customer_task suspend;
alter task classic_db.bronze.populate_curated_order_task suspend;
alter task classic_db.bronze.populate_dim_customer_task suspend;  
alter task classic_db.bronze.populate_dim_date_task suspend;
alter task classic_db.bronze.populate_dim_priority_task suspend;
alter task classic_db.bronze.populate_fact_order_task suspend;