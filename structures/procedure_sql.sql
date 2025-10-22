USE ROLE developer;
USE WAREHOUSE WRITER_WH;
USE DATABASE POC;
USE SCHEMA POC;
CREATE OR REPLACE PROCEDURE table_mod
(
    action_type int,
    db_name text,
    schema_name text,
    tbl_name text,
    col_name text,
    col_type text,
    isnullable boolean,
    defaultvalue text,
    new_col_name text
)
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS $$
BEGIN

SYSTEM$LOG('INFO','Starting action type: ' || 
            CASE
                WHEN :action_type = 1 
                THEN 'add column'
                WHEN :action_type = 2 
                THEN 'drop column'
                WHEN :action_type = 3 
                THEN 'rename column'
                ELSE 'unknown'
            END);

    IF (:col_name NOT RLIKE '^[A-Za-z_][A-Za-z0-9_]*$') 
    THEN
        RETURN 'ERROR - INVALID COLUMN NAME';
    END IF;

    LET sqlstat STRING := '';

    LET table_exists BOOLEAN := (
        SELECT COUNT(*) > 0 
            FROM INFORMATION_SCHEMA.TABLES 
        WHERE 
            TABLE_SCHEMA = UPPER(:schema_name) 
        AND TABLE_NAME = UPPER(:tbl_name)
        );

    IF 
        (
            :db_name IS NULL OR 
            :schema_name IS NULL OR 
            :tbl_name IS NULL OR 
            :col_name IS NULL) 
    THEN
        SYSTEM$LOG('error','One or more from given parameters are null: '||
            CASE
                WHEN :db_name IS NULL
                THEN 'db_name'
                WHEN :schema_name IS NULL 
                THEN 'schema_name'
                WHEN :tbl_name IS NULL 
                THEN 'tbl_name'
                ELSE 'col_name'
            END);
        RETURN 'ERROR - REQUIRED PARAMETERS CANNOT BE NULL';
    END IF;    

    IF (NOT table_exists) THEN 
        SYSTEM$LOG('error','Table does not exist: '|| :tbl_name);
        RETURN 'ERROR - TABLE DOES NOT EXIST';
    END IF;

    LET col_exists BOOLEAN := (
        SELECT COUNT(*) > 0
            FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE 
            TABLE_SCHEMA = UPPER(:schema_name)
        AND TABLE_NAME = UPPER(:tbl_name)
        AND COLUMN_NAME = UPPER(:col_name)
        );

    IF (action_type = 1) --add column
    THEN
        IF (col_exists) THEN 
            SYSTEM$LOG('error','Column already exists: '|| :col_name);
            RETURN 'ERROR - COLUMN ALREADY EXISTS';
        END IF;

        sqlstat := 'ALTER TABLE '|| :db_name ||'.'|| :schema_name ||'.'|| :tbl_name ||' ADD COLUMN '|| :col_name||' '|| :col_type;
        
        IF (NOT :isnullable) THEN
                sqlstat := sqlstat ||' NOT NULL';
        END IF;

        IF (:defaultvalue IS NOT NULL AND :defaultvalue != '') THEN
            IF 
                (UPPER(:col_type) LIKE '%CHAR%' OR 
                 UPPER(:col_type) LIKE '%TEXT%' OR 
                 UPPER(:col_type) LIKE '%STRING%') 
            THEN
                sqlstat := sqlstat || ' DEFAULT ''' || :defaultvalue || '''';
            ELSE
                sqlstat := sqlstat || ' DEFAULT ' || :defaultvalue;
            END IF;
        END IF;
        
        EXECUTE IMMEDIATE :sqlstat;
        SYSTEM$LOG('info','Column has been added: '|| :col_name);
        RETURN 'SUCCESS - COLUMN HAS BEEN ADDED: ' || sqlstat;
        
    ELSEIF (action_type = 2) --drop column
    THEN
        IF (NOT :col_exists) THEN 
            SYSTEM$LOG('error','Column does not exist: '|| :col_name);
            RETURN 'ERROR - COLUMN DOES NOT EXIST';
        END IF;

        sqlstat := 'ALTER TABLE '|| :db_name ||'.'|| :schema_name ||'.'|| :tbl_name ||' DROP COLUMN '|| :col_name;

        EXECUTE IMMEDIATE :sqlstat;

        SYSTEM$LOG('info','Column has been dropped: '|| :col_name);
        RETURN 'SUCCESS - COLUMN HAS BEEN DROPPED: ' || sqlstat;
        
    ELSEIF (action_type = 3) THEN --rename column
        IF (:new_col_name IS NULL OR :new_col_name = '') THEN
            SYSTEM$LOG('error','Required parameter new_col_name cannot be null');
            RETURN 'ERROR - REQUIRED PARAMETER new_col_name CANNOT BE NULL';
        END IF;
    
        IF (NOT :col_exists) THEN 
            SYSTEM$LOG('error','Column does not exist: '|| :col_name);
            RETURN 'ERROR - COLUMN DOES NOT EXIST';
        END IF;
    
        sqlstat := 'ALTER TABLE '|| :db_name ||'.'|| :schema_name ||'.'|| :tbl_name ||' RENAME COLUMN '|| :col_name||' TO '||:new_col_name;
        EXECUTE IMMEDIATE :sqlstat;
        
        SYSTEM$LOG('info','Column ' || :col_name ||' has been renamed to: '|| :new_col_name);
        RETURN 'SUCCESS - COLUMN HAS BEEN RENAMED: ' || sqlstat;
    ELSE
        SYSTEM$LOG('error','Invalid action: '|| action_type);
        RETURN 'ERROR - INVALID ACTION_TYPE: ' || action_type;
    END IF;

    EXCEPTION
        WHEN OTHER THEN
            SYSTEM$LOG('error', 'Exception: ' || SQLERRM);
            RETURN 'ERROR - ' || SQLCODE || ': ' || SQLERRM || ' | SQL: ' || sqlstat;
END;
$$;

USE ROLE SECURITYADMIN;
GRANT ROLE developer to SYSADMIN;

USE ROLE DEVELOPER;

SELECT *
    FROM POC.POC.event_table -- adding logs to the table takes time, sometimes it is important to wait a few minutes
ORDER BY TIMESTAMP DESC;

CALL POC.POC.TABLE_MOD(3, 'poc', 'poc', 'test_table', 'temp_col', '', TRUE, '', 'renamed_col');