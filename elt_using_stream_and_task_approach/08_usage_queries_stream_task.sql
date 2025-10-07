use role sysadmin;
use warehouse compute_wh;
use schema classic_db.bronze;

select *
  from table(information_schema.task_history())
  order by scheduled_time;

select 
    "NAME",
    "QUERY_ID",
    "STATE",
    "ERROR_CODE",
    "ERROR_MESSAGE"
  from table(information_schema.task_history())
  where 
    "DATABASE_NAME" = 'classic_db' and
    "SCHEMA_NAME" = 'BRONZE' 
    -- and "STATE" = 'SCHEDULED'
  order by scheduled_time;

  select 
    "NAME",
    "QUERY_ID",
    "STATE",
    "ERROR_CODE",
    "ERROR_MESSAGE"
  from table(information_schema.task_history())
  where 
    "DATABASE_NAME" = 'classic_db' and
    "SCHEMA_NAME" = 'BRONZE' 
    and "STATE" = 'SCHEDULED'
  order by scheduled_time;

  
select * from snowflake.account_usage.task_history
where 
database_name = 'classic_db' and schema_name = 'bronze'
order by scheduled_time;


SET task_run_id = (
select run_id from snowflake.account_usage.task_history
where 
database_name = 'classic_db' and schema_name = 'bronze'
and name = 'POPULATE_fact_order_TASK' and state = 'SUCCEEDED'
QUALIFY ROW_NUMBER() OVER(order by scheduled_time) = 1
)

select * from snowflake.account_usage.task_history
where 
database_name = 'classic_db' and schema_name = 'bronze'
and run_id = $task_run_id
order by query_start_time;

-- execution duration
select 
name,
query_start_time,
TIMESTAMPDIFF('second',query_start_time,completed_time)
from snowflake.account_usage.task_history
where 
database_name = 'classic_db' and schema_name = 'bronze'
and run_id = $task_run_id
order by query_start_time;

-- calculate avg
select 
name,
min (TIMESTAMPDIFF('second',query_start_time,completed_time)) as min_lag,
max (TIMESTAMPDIFF('second',query_start_time,completed_time)) as max_lag,
avg (TIMESTAMPDIFF('second',query_start_time,completed_time)) as avg_lag
from snowflake.account_usage.task_history
where 
database_name = 'classic_db' and schema_name = 'bronze'
group by name;