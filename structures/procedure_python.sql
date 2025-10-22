USE ROLE SYSADMIN;
USE WAREHOUSE WRITER_WH;
USE DATABASE POC;
USE SCHEMA POC;
CREATE OR REPLACE PROCEDURE py_mod_table(
    action_type INT,
    db_name STRING,
    schema_name STRING,
    tbl_name STRING,
    col_name STRING,
    col_type STRING,
    isnullable BOOLEAN,
    defaultvalue STRING,
    new_col_name STRING
)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.13'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'py_mod_table'
EXECUTE AS OWNER
AS
$$
import logging
import re

logger = logging.getLogger("snowflake.stored_procedure")

def py_mod_table(session, action_type, db_name, schema_name, tbl_name, col_name, col_type, isnullable, defaultvalue, new_col_name):
    action_names = {1: 'add column', 2: 'drop column', 3: 'rename column'}
    action_name = action_names.get(action_type, 'unknown')
    
    logger.info(f'Starting action type: {action_name}')
    
    if not all([db_name, schema_name, tbl_name, col_name]):
        logger.error(f'One of the required parameters is null: {db_name}, {schema_name}, {tbl_name}, {col_name}')
        return "ERROR - REQUIRED PARAMETERS CANNOT BE NULL"
    
    if not re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', col_name):
        logger.warning(f'Invalid column name: {col_name}')
        return "WARNING - INVALID COLUMN NAME"
    
    table_check = session.sql(f"""
        SELECT COUNT(*) as cnt
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_SCHEMA = UPPER('{schema_name}')
          AND TABLE_NAME = UPPER('{tbl_name}')
    """).collect()
    
    if table_check[0]['CNT'] == 0:
        logger.error(f'Table does not exist: {tbl_name}')
        return "ERROR - TABLE DOES NOT EXIST"
    
    col_check = session.sql(f"""
        SELECT COUNT(*) as cnt
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = UPPER('{schema_name}')
          AND TABLE_NAME = UPPER('{tbl_name}')
          AND COLUMN_NAME = UPPER('{col_name}')
    """).collect()
    
    col_exists = col_check[0]['CNT'] > 0
    
    try:
        if action_type == 1:
            if col_exists:
                logger.error(f'Column already exists: {col_name}')
                return "ERROR - COLUMN ALREADY EXISTS"
            
            sql = f"ALTER TABLE {db_name}.{schema_name}.{tbl_name} ADD COLUMN {col_name} {col_type}"
            
            if not isnullable:
                sql += " NOT NULL"
            
            if defaultvalue:
                if any(x in col_type.upper() for x in ['CHAR', 'TEXT', 'STRING']):
                    sql += f" DEFAULT '{defaultvalue}'"
                else:
                    sql += f" DEFAULT {defaultvalue}"
            
            session.sql(sql).collect()
            logger.info(f'Column has been added: {col_name}')
            return f"SUCCESS - COLUMN ADDED: {sql}"
        
        elif action_type == 2:
            if not col_exists:
                logger.error(f'Column {col_name} does not exist')
                return "ERROR - COLUMN DOES NOT EXIST"
            
            sql = f"ALTER TABLE {db_name}.{schema_name}.{tbl_name} DROP COLUMN {col_name}"
            session.sql(sql).collect()
            logger.info(f'Column has been dropped: {col_name}')
            return f"SUCCESS - COLUMN DROPPED: {sql}"
        
        elif action_type == 3:
            if not new_col_name:
                logger.error(f'New column cannot be null')
                return "ERROR - new_col_name CANNOT BE NULL"
            if not col_exists:
                logger.error(f'Column {col_name} does not exist')
                return "ERROR - COLUMN DOES NOT EXIST"
            if not re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', new_col_name):
                logger.warning(f'Invalid new column name: {new_col_name}')
                return "WARNING - INVALID NEW COLUMN NAME"
            
            sql = f"ALTER TABLE {db_name}.{schema_name}.{tbl_name} RENAME COLUMN {col_name} TO {new_col_name}"
            session.sql(sql).collect()
            logger.info(f'Column has been renamed')
            return f"SUCCESS - COLUMN RENAMED: {sql}"
        
        else:
            logger.error(f'Action type {action_type} is invalid')
            return f"ERROR - INVALID ACTION_TYPE: {action_type}"
    
    except Exception as e:
        logger.error(f'Exception')
        return f"ERROR - {str(e)}"
$$;
ALTER PROCEDURE py_mod_table(INT, STRING, STRING, STRING, STRING, STRING, BOOLEAN, STRING, STRING) 
SET LOG_LEVEL = 'INFO';

SELECT *
    FROM POC.POC.event_table -- adding logs to the table takes time, sometimes it is important to wait a few minutes
WHERE SCOPE:name::STRING ='snowflake.stored_procedure'
ORDER BY TIMESTAMP DESC;

TRUNCATE POC.POC.event_table ;

CALL poc.poc.py_mod_table(2, 'poc', 'poc', 'test_table', 'renamed_col', '', TRUE, '', '');