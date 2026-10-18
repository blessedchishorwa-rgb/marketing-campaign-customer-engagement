============================================================
Marketing Campaign Performance & Customer Engagement Analysis
Author: Blessed Chishorwa 
Database: SQL Server
Source table: marketing_campaign
Dataset: Kaggle Customer Personality Analysis

Purpose:
Validate customer data and calculate campaign acceptance,
purchase-channel, spending, complaint, and recency KPIs.
============================================================
*/

--------------------------------------------------------------
-1. DATA VALIDATION
------------------------------------------------------------

-- Checking total number of customer records
SELECT
    COUNT(*) AS Total_Customers
FROM marketing_campaign;

-- Checking for duplicate customer IDs
SELECT
    ID,
    COUNT(*) AS Duplicate_Count
FROM marketing_campaign
GROUP BY ID
HAVING COUNT(*) > 1;

-- Checkin missing income values
SELECT
    COUNT(*) AS Missing_Income_Count
FROM marketing_campaign
WHERE Income IS NULL;

-- Checkin minimum and maximum purchase recency
SELECT
    MIN(Recency) AS Min_Recency,
    MAX(Recency) AS Max_Recency
FROM marketing_campaign;

-- ------------------------------------------------------------
-- 2. CREATING ANALYSIS-READY FIELDS
-- ------------------------------------------------------------

-- Creating a view with cleaned and calculated fields
CREATE OR ALTER VIEW vw_marketing_analysis AS
SELECT
    ID,
    Year_Birth,
    Education,
    Marital_Status,
    Income,
    Dt_Customer,
    Recency,
    Complain,

    -- Total spending across all product categories
    MntWines +
    MntFruits +
    MntMeatProducts +
    MntFishProducts +
    MntSweetProducts +
    MntGoldProds AS Total_Spend,

    -- Total recorded purchases across all channels
    NumDealsPurchases +
    NumWebPurchases +
    NumCatalogPurchases +
    NumStorePurchases AS Total_Purchases,

    NumDealsPurchases,
    NumWebPurchases,
    NumCatalogPurchases,
    NumStorePurchases,
    NumWebVisitsMonth,

    AcceptedCmp1,
    AcceptedCmp2,
    AcceptedCmp3,
    AcceptedCmp4,
    AcceptedCmp5,
    Response,

    -- Analyst-defined engagement segment based on recency
    CASE
        WHEN Recency > 80 THEN 'High Recency - Low Engagement'
        WHEN Recency > 50 THEN 'Medium Recency'
        ELSE 'Low Recency - Active'
    END AS Engagement_Flag

FROM marketing_campaign;
GO

-- ------------------------------------------------------------
-- 3. CAMPAIGN ACCEPTANCE KPIs
-- ------------------------------------------------------------

-- Acceptance rate for each of the five campaigns
SELECT
    'Campaign 1' AS Campaign,
    AVG(CAST(AcceptedCmp1 AS FLOAT)) * 100 AS Acceptance_Rate
FROM marketing_campaign

UNION ALL

SELECT
    'Campaign 2',
    AVG(CAST(AcceptedCmp2 AS FLOAT)) * 100
FROM marketing_campaign

UNION ALL

SELECT
    'Campaign 3',
    AVG(CAST(AcceptedCmp3 AS FLOAT)) * 100
FROM marketing_campaign

UNION ALL

SELECT
    'Campaign 4',
    AVG(CAST(AcceptedCmp4 AS FLOAT)) * 100
FROM marketing_campaign

UNION ALL

SELECT
    'Campaign 5',
    AVG(CAST(AcceptedCmp5 AS FLOAT)) * 100
FROM marketing_campaign

ORDER BY Acceptance_Rate DESC;

-- Latest campaign response KPI
SELECT
    AVG(CAST(Response AS FLOAT)) * 100 AS Last_Campaign_Acceptance_Rate,
    SUM(Response) AS Total_Last_Campaign_Acceptances,
    COUNT(*) AS Total_Customers
FROM marketing_campaign;

-- ------------------------------------------------------------
-- 4. PURCHASE CHANNEL KPIs
-- ------------------------------------------------------------

-- Share of recorded purchases by channel
SELECT
    SUM(NumWebPurchases) * 100.0 /
        NULLIF(SUM(NumDealsPurchases + NumWebPurchases +
                   NumCatalogPurchases + NumStorePurchases), 0)
        AS Web_Purchase_Share,

    SUM(NumCatalogPurchases) * 100.0 /
        NULLIF(SUM(NumDealsPurchases + NumWebPurchases +
                   NumCatalogPurchases + NumStorePurchases), 0)
        AS Catalog_Purchase_Share,

    SUM(NumStorePurchases) * 100.0 /
        NULLIF(SUM(NumDealsPurchases + NumWebPurchases +
                   NumCatalogPurchases + NumStorePurchases), 0)
        AS Store_Purchase_Share,

    SUM(NumDealsPurchases) * 100.0 /
        NULLIF(SUM(NumDealsPurchases + NumWebPurchases +
                   NumCatalogPurchases + NumStorePurchases), 0)
        AS Deal_Purchase_Share

FROM marketing_campaign;

-- ------------------------------------------------------------
-- 5. CUSTOMER SPENDING KPIs
-- ------------------------------------------------------------

-- Overall spending summary
SELECT
    COUNT(*) AS Total_Customers,
    AVG(MntWines + MntFruits + MntMeatProducts +
        MntFishProducts + MntSweetProducts + MntGoldProds)
        AS Average_Total_Spend,

    SUM(MntWines + MntFruits + MntMeatProducts +
        MntFishProducts + MntSweetProducts + MntGoldProds)
        AS Total_Customer_Spend

FROM marketing_campaign;

-- Spending by education level
SELECT
    Education,
    COUNT(*) AS Customer_Count,
    AVG(MntWines + MntFruits + MntMeatProducts +
        MntFishProducts + MntSweetProducts + MntGoldProds)
        AS Average_Total_Spend
FROM marketing_campaign
GROUP BY Education
ORDER BY Average_Total_Spend DESC;

-- ------------------------------------------------------------
-- 6. COMPLAINT KPIs
-- ------------------------------------------------------------

-- Overall complaint rate
SELECT
    COUNT(*) AS Total_Customers,
    SUM(Complain) AS Total_Complaints,
    AVG(CAST(Complain AS FLOAT)) * 100 AS Complaint_Rate
FROM marketing_campaign;

-- Complaint rate and average recency by marital status
SELECT
    Marital_Status,
    COUNT(*) AS Customer_Count,
    AVG(CAST(Complain AS FLOAT)) * 100 AS Complaint_Rate,
    AVG(Recency) AS Average_Recency
FROM marketing_campaign
GROUP BY Marital_Status
ORDER BY Complaint_Rate DESC;

-- Complaint rate and average recency by education level
SELECT
    Education,
    COUNT(*) AS Customer_Count,
    AVG(CAST(Complain AS FLOAT)) * 100 AS Complaint_Rate,
    AVG(Recency) AS Average_Recency
FROM marketing_campaign
GROUP BY Education
ORDER BY Complaint_Rate DESC;

-- ------------------------------------------------------------
-- 7. ENGAGEMENT REVIEW GROUP
-- ------------------------------------------------------------

-- Customers with no purchase for more than 80 days
SELECT
    ID,
    Recency,
    NumWebVisitsMonth,
    MntWines + MntFruits + MntMeatProducts +
        MntFishProducts + MntSweetProducts + MntGoldProds
        AS Total_Spend,
    'High Recency - Low Engagement' AS Engagement_Flag
FROM marketing_campaign
WHERE Recency > 80
ORDER BY Recency DESC;

-- Count of customers in the high-recency engagement-review group
SELECT
    COUNT(*) AS High_Recency_Customers,
    AVG(CAST(Recency AS FLOAT)) AS Average_Recency
FROM marketing_campaign
WHERE Recency > 80;

