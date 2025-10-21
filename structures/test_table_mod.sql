-- ============================================
-- TEST SUITE FOR table_mod PROCEDURE
-- ============================================

USE ROLE DEVELOPER;
USE DATABASE POC;
USE SCHEMA POC;

-- ============================================
-- SETUP: Create test table
-- ============================================
DROP TABLE IF EXISTS test_table;
CREATE TABLE test_table (
    id INT,
    name VARCHAR(100)
);

-- ============================================
-- TEST 1: ADD COLUMN - Success (INT, nullable)
-- ============================================
CALL TABLE_MOD(1, 'poc', 'poc', 'test_table', 'age', 'INT', TRUE, '', '');
-- Expected: SUCCESS - COLUMN HAS BEEN ADDED

-- Verify
SELECT column_name, data_type, is_nullable 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE table_name = 'TEST_TABLE' AND column_name = 'AGE';
-- Expected: AGE, NUMBER, YES

-- ============================================
-- TEST 2: ADD COLUMN - Success (VARCHAR with DEFAULT)
-- ============================================
CALL TABLE_MOD(1, 'poc', 'poc', 'test_table', 'status', 'VARCHAR', TRUE, 'active', '');
-- Expected: SUCCESS - COLUMN HAS BEEN ADDED

-- Verify
SELECT column_name, column_default 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE table_name = 'TEST_TABLE' AND column_name = 'STATUS';
-- Expected: STATUS, 'active'

-- ============================================
-- TEST 3: ADD COLUMN - Success (NOT NULL with DEFAULT)
-- ============================================
CALL TABLE_MOD(1, 'poc', 'poc', 'test_table', 'created_at', 'TIMESTAMP', TRUE, 'CURRENT_TIMESTAMP', '');
-- Expected: SUCCESS - COLUMN HAS BEEN ADDED

-- Verify
SELECT column_name, is_nullable 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE table_name = 'TEST_TABLE' AND column_name = 'CREATED_AT';
-- Expected: CREATED_AT, NO

-- ============================================
-- TEST 4: ADD COLUMN - Error (column already exists)
-- ============================================
CALL TABLE_MOD(1, 'poc', 'poc', 'test_table', 'age', 'INT', TRUE, '', '');
-- Expected: ERROR - COLUMN ALREADY EXISTS

-- ============================================
-- TEST 5: ADD COLUMN - Error (invalid column name)
-- ============================================
CALL TABLE_MOD(1, 'poc', 'poc', 'test_table', '123invalid', 'INT', TRUE, '', '');
-- Expected: ERROR - INVALID COLUMN NAME

CALL TABLE_MOD(1, 'poc', 'poc', 'test_table', 'col-name', 'INT', TRUE, '', '');
-- Expected: ERROR - INVALID COLUMN NAME

-- ============================================
-- TEST 6: ADD COLUMN - Error (table does not exist)
-- ============================================
CALL TABLE_MOD(1, 'poc', 'poc', 'nonexistent_table', 'col', 'INT', TRUE, '', '');
-- Expected: ERROR - TABLE DOES NOT EXIST

-- ============================================
-- TEST 7: ADD COLUMN - Error (NULL parameters)
-- ============================================
CALL TABLE_MOD(1, NULL, 'poc', 'test_table', 'col', 'INT', TRUE, '', '');
-- Expected: ERROR - REQUIRED PARAMETERS CANNOT BE NULL

CALL TABLE_MOD(1, 'poc', NULL, 'test_table', 'col', 'INT', TRUE, '', '');
-- Expected: ERROR - REQUIRED PARAMETERS CANNOT BE NULL

CALL TABLE_MOD(1, 'poc', 'poc', NULL, 'col', 'INT', TRUE, '', '');
-- Expected: ERROR - REQUIRED PARAMETERS CANNOT BE NULL

CALL TABLE_MOD(1, 'poc', 'poc', 'test_table', NULL, 'INT', TRUE, '', '');
-- Expected: ERROR - REQUIRED PARAMETERS CANNOT BE NULL

-- ============================================
-- TEST 8: RENAME COLUMN - Success
-- ============================================
CALL TABLE_MOD(3, 'poc', 'poc', 'test_table', 'age', '', TRUE, '', 'person_age');
-- Expected: SUCCESS - COLUMN HAS BEEN RENAMED

-- Verify
SELECT column_name 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE table_name = 'TEST_TABLE' AND column_name = 'PERSON_AGE';
-- Expected: PERSON_AGE

-- ============================================
-- TEST 9: RENAME COLUMN - Error (column does not exist)
-- ============================================
CALL TABLE_MOD(3, 'poc', 'poc', 'test_table', 'nonexistent_col', '', TRUE, '', 'new_name');
-- Expected: ERROR - COLUMN DOES NOT EXIST

-- ============================================
-- TEST 10: RENAME COLUMN - Error (new_col_name is NULL)
-- ============================================
CALL TABLE_MOD(3, 'poc', 'poc', 'test_table', 'person_age', '', TRUE, '', NULL);
-- Expected: ERROR - REQUIRED PARAMETER CANNOT BE NULL

-- ============================================
-- TEST 11: DROP COLUMN - Success
-- ============================================
CALL TABLE_MOD(2, 'poc', 'poc', 'test_table', 'person_age', '', TRUE, '', '');
-- Expected: SUCCESS - COLUMN HAS BEEN DROPPED

-- Verify
SELECT column_name 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE table_name = 'TEST_TABLE' AND column_name = 'PERSON_AGE';
-- Expected: No rows

-- ============================================
-- TEST 12: DROP COLUMN - Error (column does not exist)
-- ============================================
CALL TABLE_MOD(2, 'poc', 'poc', 'test_table', 'nonexistent_col', '', TRUE, '', '');
-- Expected: ERROR - COLUMN DOES NOT EXIST

-- ============================================
-- TEST 13: Invalid action_type
-- ============================================
CALL TABLE_MOD(99, 'poc', 'poc', 'test_table', 'col', 'INT', TRUE, '', '');
-- Expected: ERROR - INVALID ACTION_TYPE: 99

-- ============================================
-- TEST 14: ADD COLUMN with numeric DEFAULT
-- ============================================
CALL TABLE_MOD(1, 'poc', 'poc', 'test_table', 'score', 'INT', TRUE, '0', '');
-- Expected: SUCCESS - COLUMN HAS BEEN ADDED

-- Verify
SELECT column_name, column_default 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE table_name = 'TEST_TABLE' AND column_name = 'SCORE';
-- Expected: SCORE, 0

-- ============================================
-- TEST 15: Full workflow (ADD -> RENAME -> DROP)
-- ============================================
-- Add
CALL TABLE_MOD(1, 'poc', 'poc', 'test_table', 'temp_col', 'VARCHAR', TRUE, '', '');
-- Expected: SUCCESS

-- Rename
CALL TABLE_MOD(3, 'poc', 'poc', 'test_table', 'temp_col', '', TRUE, '', 'renamed_col');
-- Expected: SUCCESS

-- Drop
CALL TABLE_MOD(2, 'poc', 'poc', 'test_table', 'renamed_col', '', TRUE, '', '');
-- Expected: SUCCESS

-- Verify all gone
SELECT column_name 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE table_name = 'TEST_TABLE' AND column_name IN ('TEMP_COL', 'RENAMED_COL');
-- Expected: No rows

-- ============================================
-- CLEANUP
-- ============================================
DROP TABLE IF EXISTS test_table;

-- ============================================
-- TEST SUMMARY QUERY
-- ============================================
-- Check all columns in test_table after tests
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE table_name = 'TEST_TABLE'
ORDER BY ordinal_position;

-- ============================================
-- CHECK LOGS (wait 2-5 minutes after running tests)
-- ============================================
SELECT 
    *
FROM POC.POC.event_table
ORDER BY TIMESTAMP DESC;
