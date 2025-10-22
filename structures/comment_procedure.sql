COMMENT ON PROCEDURE table_mod(INT, TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN, TEXT, TEXT) AND py_mod_table (INT, TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN, TEXT, TEXT) IS 
'
A stored procedure for managing columns in tables.
Located in poc.poc.
The procedure is executed as owner. 

Parameters:
- action_type: 1 = ADD COLUMN, 2 = DROP COLUMN, 3 = RENAME COLUMN 
- db_name: database in which the action type will be executed (all Action Types)
- schema_name: schema name in which the action type will be executed (all Action Types)
- tbl_name: table name in which the action type will be executed (all Action Types)
- col_name: column name that will be added, dropped or renamed (all Action Types)
- col_type: column type for the column that will be added (only for Action Type = 1)
- isnullable: if the column is NULL (only for Action Type = 1) (Boolean)
- defaultvalue: default value for column that will be added (only for Action Type = 1) (Boolean)
- new_col_name: new column name (only for Action Type = 3 )

example call:
CALL TABLE_MOD(1,'poc','poc', 'poc','fdgdy', 'int', TRUE,'','');
shows: SUCCESS - COLUMN ADDED: ALTER TABLE poc.poc.poc ADD COLUMN fdgdy int
';