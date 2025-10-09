use role sysadmin;
use warehouse compute_wh;
use schema classic_db.orchestration;

use role accountadmin;
grant execute task, execute managed task on account to role sysadmin;
use role sysadmin;

-- resume statements..
alter task classic_db.orchestration.populate_fact_order_task resume;
alter task classic_db.orchestration.populate_dim_priority_task resume;
alter task classic_db.orchestration.populate_dim_date_task resume;
alter task classic_db.orchestration.populate_dim_customer_task resume;
alter task classic_db.orchestration.populate_curated_order_task resume;
alter task classic_db.orchestration.populate_curated_customer_task resume;
alter task classic_db.orchestration.copy_to_order_orchestration_task resume;
alter task classic_db.orchestration.copy_to_customer_orchestration_task resume;
alter task classic_db.orchestration.root_task resume;

-- suspend statements..
alter task classic_db.orchestration.root_task suspend;
alter task classic_db.orchestration.copy_to_customer_orchestration_task suspend;
alter task classic_db.orchestration.copy_to_order_orchestration_task suspend;
alter task classic_db.orchestration.populate_curated_customer_task suspend;
alter task classic_db.orchestration.populate_curated_order_task suspend;
alter task classic_db.orchestration.populate_dim_customer_task suspend;  
alter task classic_db.orchestration.populate_dim_date_task suspend;
alter task classic_db.orchestration.populate_dim_priority_task suspend;
alter task classic_db.orchestration.populate_fact_order_task suspend;