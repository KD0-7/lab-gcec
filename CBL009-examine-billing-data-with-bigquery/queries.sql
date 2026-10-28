-- ==============================================================================
-- CBL009 - Examine Billing data with BigQuery
-- SQL Queries for Billing Analysis
-- Repository: https://github.com/KD0-7/lab-gcec
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Task 3: Compose a Simple Query
-- Filter billing records where cost > 0 (Returns 104 rows)
-- ------------------------------------------------------------------------------
SELECT *
FROM `billing_dataset.sampleinfotable`
WHERE cost > 0;

-- ------------------------------------------------------------------------------
-- Task 4: Analyze a Large Billing Dataset with SQL
-- ------------------------------------------------------------------------------

-- Query 1: Retrieve key billing attributes across all records
SELECT
    billing_account_id,
    project.id,
    project.name,
    service.description,
    currency,
    currency_conversion_rate,
    cost,
    usage.amount,
    usage.pricing_unit
FROM `billing_dataset.sampleinfotable`;

-- Query 2: Find latest 100 records where there were charges (cost > 0)
SELECT
    service.description,
    sku.description,
    location.country,
    cost,
    project.id,
    project.name,
    currency,
    currency_conversion_rate,
    usage.amount,
    usage.unit
FROM `billing_dataset.sampleinfotable`
WHERE cost > 0
ORDER BY usage_end_time DESC
LIMIT 100;

-- Query 3: Find all charges greater than $10
SELECT
    service.description,
    sku.description,
    location.country,
    cost,
    project.id,
    project.name,
    currency,
    currency_conversion_rate,
    usage.amount,
    usage.unit
FROM `billing_dataset.sampleinfotable`
WHERE cost > 10;

-- Query 4: Find the product with the most records in the billing data
-- Result: Compute Engine has 281136 records
SELECT
    service.description,
    COUNT(*) AS billing_records
FROM `billing_dataset.sampleinfotable`
GROUP BY service.description
ORDER BY billing_records DESC;

-- Query 5: Find the most frequently used product costing more than $1
-- Result: Cloud Storage has 17 charges costing more than 62 dollar
SELECT
    service.description,
    COUNT(*) AS billing_records
FROM `billing_dataset.sampleinfotable`
WHERE cost > 1
GROUP BY service.description
ORDER BY billing_records DESC;

-- Query 6: Find the most commonly charged unit of measure
-- Result: Requests were the most commonly charged unit of measure
SELECT
    usage.unit,
    COUNT(*) AS billing_records
FROM `billing_dataset.sampleinfotable`
WHERE cost > 0
GROUP BY usage.unit
ORDER BY billing_records DESC;

-- Query 7: Find the product with the highest aggregate cost
-- Result: Compute Engine has an aggregate cost of $2548.77
SELECT
    service.description,
    ROUND(SUM(cost), 2) AS total_cost
FROM `billing_dataset.sampleinfotable`
GROUP BY service.description
ORDER BY total_cost DESC;
