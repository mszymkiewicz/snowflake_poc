CREATE OR REPLACE DATABASE poc;
CREATE OR REPLACE SCHEMA poc;
CREATE OR REPLACE TABLE poc
(
    id int,
    description text
);

-- Normally I would differentiate these warehouses with size etc. 
-- For exaxmple the one for a writer would be bigger, but for now I am looking at the cost of the test account. 
CREATE WAREHOUSE READER_WH WITH 
WAREHOUSE_SIZE = 'X-SMALL'
AUTO_SUSPEND = 60
AUTO_RESUME = TRUE;

CREATE WAREHOUSE WRITER_WH WITH 
WAREHOUSE_SIZE = 'X-SMALL'
AUTO_SUSPEND = 60
AUTO_RESUME = TRUE;

--cleaning up
DROP WAREHOUSE WRITER_WH;
DROP WAREHOUSE READER_WH;
DROP DATABASE poc;