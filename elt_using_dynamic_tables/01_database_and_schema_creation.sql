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