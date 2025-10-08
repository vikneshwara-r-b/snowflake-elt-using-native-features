-- Select role and warehoue
-- --------------------------------
use role sysadmin;
use warehouse compute_wh;

-- Make sure that you have privileges to resume the task
-- and following commands needs to be executed using accountadmin role
use role accountadmin;
grant execute task, execute managed task on account to role sysadmin;
use role sysadmin;

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

-- run show command
show databases like 'classic_db';
show schemas;

-- change context
use schema classic_db.source;

-- Create file format.
-- --------------------------
create or replace file format classic_db.source.csv_format
    type = 'csv' 
    compression = 'auto' 
    field_delimiter = ',' 
    record_delimiter = '\n'  
    field_optionally_enclosed_by = '\042' 
    skip_header = 1;

-- check file format
show file formats;
desc file format classic_db.source.csv_format;

-- Create an internal stage location
-- -----------------------------------------
create or replace stage classic_db.source.landing_stage
DIRECTORY = (ENABLE = TRUE)
file_format = (format_name = 'classic_db.source.csv_format')
comment = 'this is snowflake internal stage to stage the data files under the classic_db/source schema';

-- check the stage
show stages;
desc stage classic_db.source.landing_stage;
    -- no URL value means it is internal stage.
