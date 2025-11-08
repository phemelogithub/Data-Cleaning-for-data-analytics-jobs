USE datacleaning;

-- Step 1: Inspect data
SELECT * 
FROM raw_dataset
LIMIT 10;

-- =============================================================
-- STEP 2: Standardize text formats (trim spaces, uppercase cities/provinces)
-- =============================================================
UPDATE raw_dataset
SET City = UPPER(TRIM(City)),
    Province = UPPER(TRIM(Province)),
    `Company Name` = TRIM(`Company Name`),
    `Job Title` = TRIM(`Job Title`),
    `Language and Tools` = TRIM(`Language and Tools`);

-- =============================================================
-- STEP 3: Handle missing or blank values
-- =============================================================

-- Replace missing Job Salary with 'Not Specified'
UPDATE raw_dataset
SET `Job Salary` = 'Not Specified'
WHERE `Job Salary` IS NULL OR TRIM(`Job Salary`) = '';

-- Replace missing City or Province with 'UNKNOWN'
UPDATE raw_dataset
SET City = 'UNKNOWN'
WHERE City IS NULL OR TRIM(City) = '';

UPDATE raw_dataset
SET Province = 'UNKNOWN'
WHERE Province IS NULL OR TRIM(Province) = '';

-- =============================================================
-- STEP 4: Create standardized salary column (extract numbers if needed)
-- =============================================================

-- Example: create a clean numeric salary column if it exists in strings
ALTER TABLE raw_dataset ADD COLUMN salary_clean DECIMAL(10,2);

UPDATE raw_dataset
SET salary_clean = CAST(REPLACE(REPLACE(SUBSTRING_INDEX(`Job Salary`, ' ', 1), '$', ''), ',', '') AS DECIMAL(10,2))
WHERE `Job Salary` REGEXP '^[0-9]';

-- =============================================================
-- STEP 5: Clean "Language and Tools" column (remove extra spaces, standardize separators)
-- =============================================================

UPDATE raw_dataset
SET `Language and Tools` = REPLACE(`Language and Tools`, ';', ','),
    `Language and Tools` = REPLACE(`Language and Tools`, ' ,', ','),
    `Language and Tools` = REPLACE(`Language and Tools`, ', ', ',');

-- =============================================================
-- STEP 6: Remove duplicates
-- =============================================================

DELETE t1 FROM raw_dataset t1
JOIN raw_dataset t2
ON t1.`Job Title` = t2.`Job Title`
   AND t1.`Company Name` = t2.`Company Name`
   AND t1.City = t2.City
   AND t1.`Job ID` > t2.`Job ID`;

-- =============================================================
-- STEP 7: Split Company Name into Parent Name and Subsidiary (optional)
-- =============================================================

-- Example: if company names have commas (e.g., "Amazon, Inc.")
ALTER TABLE raw_dataset ADD COLUMN company_main VARCHAR(255);
ALTER TABLE raw_dataset ADD COLUMN company_type VARCHAR(255);

UPDATE raw_dataset
SET company_main = SUBSTRING_INDEX(`Company Name`, ',', 1),
    company_type = TRIM(SUBSTRING_INDEX(`Company Name`, ',', -1))
WHERE `Company Name` LIKE '%,%';

-- =============================================================
-- STEP 8: Check final cleaned data
-- =============================================================

SELECT *
FROM raw_dataset
LIMIT 20;

-- =============================================================


