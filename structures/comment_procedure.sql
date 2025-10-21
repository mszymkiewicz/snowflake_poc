COMMENT ON PROCEDURE table_mod(INT, TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN, TEXT, TEXT) AND py_mod_table (INT, TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN, TEXT, TEXT) IS 
'
Author: Malgorzata Szymkiewicz
A stored procedure for managing columns in tables.
Located in poc.poc.
The procedure is executed as owner. 

Parameters:
- action_type: 1=ADD, 2=DROP, 3=RENAME
- db_name: database name
- schema_name: schema name
- tbl_name: table name
- col_name: column name
- col_type: column type (ADD)
- isnullable: if the column is NULL (ADD)
- defaultvalue: default value for column (ADD)
- new_col_name: new column name (RENAME)

example call:
CALL TABLE_MOD(1,'poc','poc', 'poc','fdgdy', 'int', TRUE,'','');
shows: SUCCESS - COLUMN ADDED: ALTER TABLE poc.poc.poc ADD COLUMN fdgdy int
';