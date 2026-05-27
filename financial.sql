create database financial;
use	financial;

CREATE TABLE dim_geography (
Geo_ID INT NOT NULL PRIMARY KEY,
Region VARCHAR(50) NOT NULL,
Country VARCHAR(80) NOT NULL,
Currency VARCHAR(10) NOT NULL,
INDEX idx_region (Region),
INDEX idx_country (Country)
);

CREATE TABLE dim_customer (
Customer_ID VARCHAR(20) NOT NULL PRIMARY KEY,
Customer_Name VARCHAR(120) NOT NULL,
Account_Tier VARCHAR(50) NOT NULL,
INDEX idx_tier (Account_Tier)
);

CREATE TABLE dim_merchant (
Merchant_ID INT NOT NULL PRIMARY KEY,
Merchant_Name VARCHAR(120) NOT NULL,
Category VARCHAR(60) NOT NULL,
Sub_Category VARCHAR(60) NOT NULL,
INDEX idx_cat (Category),
INDEX idx_sub_cat (Sub_Category)
);

CREATE TABLE dim_date (
Date_ID INT NOT NULL PRIMARY KEY,
Date DATE NOT NULL,
Year SMALLINT NOT NULL,
Quarter TINYINT NOT NULL,
Month TINYINT NOT NULL,
Month_Name VARCHAR(15) NOT NULL,
Day TINYINT NOT NULL,
Day_Of_Week VARCHAR(15) NOT NULL,
Is_Weekend TINYINT(1) NOT NULL DEFAULT 0,
INDEX idx_year (Year),
INDEX idx_yearmon (Year, Month)
);

CREATE TABLE IF NOT EXISTS fact_transactions (
Transaction_ID VARCHAR(20) NOT NULL PRIMARY KEY,
Customer_ID VARCHAR(20) NOT NULL,
Date_ID INT NOT NULL,
Merchant_ID INT NOT NULL,
Geo_ID INT NOT NULL,
Time TIME NOT NULL,
Transaction_Type VARCHAR(20) NOT NULL,
Payment_Method VARCHAR(40) NOT NULL,
Status VARCHAR(20) NOT NULL,
Fraud_Flag VARCHAR(5) NOT NULL DEFAULT 'No',
Amount DECIMAL(15,2) NOT NULL,
Transaction_Fee DECIMAL(10,2) NOT NULL DEFAULT 0.00,
Net_Impact DECIMAL(15,2) NOT NULL,
CONSTRAINT fk_customer FOREIGN KEY (Customer_ID)
REFERENCES dim_customer(Customer_ID),
CONSTRAINT fk_date FOREIGN KEY (Date_ID)
REFERENCES dim_date(Date_ID),
CONSTRAINT fk_merchant FOREIGN KEY (Merchant_ID)
REFERENCES dim_merchant(Merchant_ID),
CONSTRAINT fk_geo FOREIGN KEY (Geo_ID)
REFERENCES dim_geography(Geo_ID),
INDEX idx_customer (Customer_ID),
INDEX idx_date (Date_ID),
INDEX idx_fraud (Fraud_Flag),
INDEX idx_status (Status),
INDEX  idx_type (Transaction_Type)
);

CREATE TABLE financial_ledger (
Transaction_ID VARCHAR(20) NOT NULL PRIMARY KEY,
Date DATE NOT NULL,
Time TIME NOT NULL,
Customer_ID VARCHAR(20) NOT NULL,
Customer_Name VARCHAR(120) NOT NULL,
Account_Tier VARCHAR(50) NOT NULL,
Transaction_Type VARCHAR(20) NOT NULL,
Category VARCHAR(60) NOT NULL,
Sub_Category VARCHAR(60) NOT NULL,
Merchant_Name VARCHAR(120) NOT NULL,
Amount DECIMAL(15,2) NOT NULL,
Currency VARCHAR(10) NOT NULL,
Transaction_Fee DECIMAL(10,2) NOT NULL DEFAULT 0.00,
Net_Impact DECIMAL(15,2) NOT NULL,
Payment_Method VARCHAR(40) NOT NULL,
Status VARCHAR(20) NOT NULL,
Region VARCHAR(50) NOT NULL,
Country VARCHAR(80) NOT NULL,
Fraud_Flag VARCHAR(5) NOT NULL DEFAULT 'No',
INDEX idx_date (Date),
INDEX idx_customer (Customer_ID),
INDEX idx_fraud (Fraud_Flag),
INDEX idx_category (Category),
INDEX idx_region (Region)
);

SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE 'E:/finance/finance/dim_customer.csv'
INTO TABLE dim_customer
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'E:/finance/finance/dim_date.csv'
INTO TABLE dim_date
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'E:/finance/finance/dim_geography.csv'
INTO TABLE dim_geography
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'E:/finance/finance/dim_merchant.csv'
INTO TABLE dim_merchant
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'E:/finance/finance/fact_transactions.csv'
INTO TABLE fact_transactions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'E:/finance/finance/Realistic_Financial_Ledger.csv'
INTO TABLE financial_ledger
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from fact_transactions;
select * from financial_ledger;
select * from dim_date;
select * from dim_geography;
select * from dim_merchant;
select * from dim_customer;

-- ■ BASIC RETRIEVAL & FILTERING
-- Q1. View All Transactions in a Date Range
SELECT t.Transaction_ID,
c.Customer_Name,
d.Date,
t.Amount,
t.Transaction_Type,
t.Status
FROM fact_transactions t
JOIN dim_customer c ON c.Customer_ID = t.Customer_ID
JOIN dim_date d ON d.Date_ID = t.Date_ID
WHERE d.Date BETWEEN '2023-06-01' AND '2023-06-30'
ORDER BY d.Date, t.Time;


-- Q2. Filter Transactions by Status and Payment Method
SELECT Transaction_ID,
Customer_ID,
Amount,
Transaction_Fee,
Net_Impact
FROM fact_transactions
WHERE Status = 'Completed'
AND Payment_Method = 'Credit Card'
ORDER BY Amount DESC
LIMIT 100;


-- Q3. List All Unique Transaction Types and Payment Methods
SELECT DISTINCT Transaction_Type FROM fact_transactions ORDER BY 1;
SELECT DISTINCT Payment_Method FROM fact_transactions ORDER BY 1;
SELECT DISTINCT Status FROM fact_transactions ORDER BY 1;


-- Q4. Find High-Value Transactions Above a Threshold
SELECT t.Transaction_ID,
c.Customer_Name,
c.Account_Tier,
t.Amount,
m.Category,
g.Country,
d.Date
FROM fact_transactions t
JOIN dim_customer c ON c.Customer_ID = t.Customer_ID
JOIN dim_merchant m ON m.Merchant_ID = t.Merchant_ID
JOIN dim_geography g ON g.Geo_ID = t.Geo_ID
JOIN dim_date d ON d.Date_ID = t.Date_ID
WHERE t.Amount > 5000
ORDER BY t.Amount DESC;


-- ■ AGGREGATION & GROUPING
-- Q5. Total Transaction Volume and Count by Year-Month
SELECT d.Year,
d.Month_Name,
COUNT(*) AS txn_count,
SUM(t.Amount) AS total_amount,
AVG(t.Amount) AS avg_amount,
SUM(t.Transaction_Fee) AS total_fees
FROM fact_transactions t
JOIN dim_date d ON d.Date_ID = t.Date_ID
GROUP BY d.Year, d.Month, d.Month_Name
ORDER BY d.Year, d.Month;


-- Q6. Spending by Merchant Category
SELECT m.Category,
COUNT(*) AS txn_count,
SUM(t.Amount) AS total_spend,
round(AVG(t.Amount), 2) AS avg_spend,
MAX(t.Amount) AS max_spend,
MIN(t.Amount) AS min_spend
FROM fact_transactions t
JOIN dim_merchant m ON m.Merchant_ID = t.Merchant_ID
GROUP BY m.Category
ORDER BY total_spend DESC;


-- Q7. Revenue by Account Tier
SELECT c.Account_Tier,
COUNT(DISTINCT t.Customer_ID) AS customer_count,
COUNT(*) AS txn_count,
SUM(t.Amount) AS total_amount,
ROUND(AVG(t.Amount), 2) AS avg_txn_amount
FROM fact_transactions t
JOIN dim_customer c ON c.Customer_ID = t.Customer_ID
GROUP BY c.Account_Tier
ORDER BY total_amount DESC;


-- Q8. Transaction Volume by Region and Country
SELECT g.Region,
g.Country,
g.Currency,
COUNT(*) AS txn_count,
SUM(t.Amount) AS total_volume,
AVG(t.Amount) AS avg_amount
FROM fact_transactions t
JOIN dim_geography g ON g.Geo_ID = t.Geo_ID
GROUP BY g.Region, g.Country, g.Currency
ORDER BY g.Region, total_volume DESC;


-- Q9. Weekday vs Weekend Transaction Patterns
SELECT CASE d.Is_Weekend
WHEN 1 THEN 'Weekend'
ELSE 'Weekday'
END AS day_type,
COUNT(*) AS txn_count,
SUM(t.Amount) AS total_amount,
ROUND(AVG(t.Amount),2) AS avg_amount
FROM fact_transactions t
JOIN dim_date d ON d.Date_ID = t.Date_ID
GROUP BY d.Is_Weekend
ORDER BY day_type;


-- Q10. Hourly Transaction Distribution
SELECT HOUR(t.Time) AS hour_of_day,
COUNT(*) AS txn_count,
SUM(t.Amount) AS total_amount
FROM fact_transactions t
GROUP BY HOUR(t.Time)
ORDER BY hour_of_day;


-- ■ CUSTOMER ANALYSIS
-- Q11. Top 10 Customers by Total Spend
SELECT c.Customer_ID,
c.Customer_Name,
c.Account_Tier,
COUNT(*) AS txn_count,
SUM(t.Amount) AS total_spend,
ROUND(AVG(t.Amount),2) AS avg_spend,
MAX(t.Amount) AS largest_txn
FROM fact_transactions t
JOIN dim_customer c ON c.Customer_ID = t.Customer_ID
GROUP BY c.Customer_ID, c.Customer_Name, c.Account_Tier
ORDER BY total_spend DESC
LIMIT 10;


-- Q12. Customer Lifetime Value (CLV) Approximation
SELECT c.Customer_ID,
c.Customer_Name,
c.Account_Tier,
COUNT(*) AS total_transactions,
SUM(t.Amount) AS gross_spend,
SUM(t.Transaction_Fee) AS fees_generated,
SUM(t.Net_Impact) AS net_impact,
MIN(d.Date) AS first_txn_date,
MAX(d.Date) AS last_txn_date,
DATEDIFF(MAX(d.Date),MIN(d.Date)) AS active_days
FROM fact_transactions t
JOIN dim_customer c ON c.Customer_ID = t.Customer_ID
JOIN dim_date d ON d.Date_ID = t.Date_ID
GROUP BY c.Customer_ID, c.Customer_Name, c.Account_Tier
ORDER BY gross_spend DESC;


-- Q12. Customer Transaction Frequency Segmentation
WITH cust_freq AS (
SELECT Customer_ID,
COUNT(*) AS txn_count
FROM fact_transactions
GROUP BY Customer_ID
)
SELECT CASE
WHEN txn_count >= 100 THEN 'High Frequency'
WHEN txn_count >= 30 THEN 'Medium Frequency'
ELSE 'Low Frequency'
END AS segment,
COUNT(*) AS customer_count,
AVG(txn_count) AS avg_txns_per_customer,
SUM(txn_count) AS total_txns
FROM cust_freq
GROUP BY segment
ORDER BY avg_txns_per_customer DESC;

-- Q13. Customers with No Transactions in Last 90 Days (Churned)
SELECT c.Customer_ID,
c.Customer_Name,
c.Account_Tier,
MAX(d.Date) AS last_txn_date,
DATEDIFF(CURDATE(), MAX(d.Date)) AS days_since_last_txn
FROM dim_customer c
JOIN fact_transactions t ON t.Customer_ID = c.Customer_ID
JOIN dim_date d ON d.Date_ID = t.Date_ID
GROUP BY c.Customer_ID, c.Customer_Name, c.Account_Tier
HAVING MAX(d.Date) < DATE_SUB(CURDATE(), INTERVAL 90 DAY)
ORDER BY days_since_last_txn DESC;


-- ■ FRAUD DETECTION & RISK ANALYSIS
-- Q14. Overall Fraud Rate by Count and Amount
SELECT Fraud_Flag,
COUNT(*) AS txn_count,
ROUND(COUNT(*) * 100.0
/ SUM(COUNT(*)) OVER(), 2) AS pct_of_count,
SUM(Amount) AS total_amount,
ROUND(SUM(Amount) * 100.0
/ SUM(SUM(Amount)) OVER(), 2) AS pct_of_amount
FROM fact_transactions
GROUP BY Fraud_Flag;

-- Q15. Fraud Rate by Merchant Category
SELECT m.Category,
COUNT(*) AS total_txns,
SUM(t.Fraud_Flag = 'Yes') AS fraud_count,
ROUND(SUM(t.Fraud_Flag = 'Yes') * 100.0
/ COUNT(*), 2) AS fraud_rate_pct,
SUM(CASE WHEN t.Fraud_Flag = 'Yes'
 THEN t.Amount ELSE 0 END) AS fraud_amount
FROM fact_transactions t
JOIN dim_merchant m ON m.Merchant_ID = t.Merchant_ID
GROUP BY m.Category
ORDER BY fraud_rate_pct DESC;


-- Q16. Fraud by Country
SELECT g.Country,
g.Region,
COUNT(*) AS total_txns,
SUM(t.Fraud_Flag = 'Yes') AS fraud_count,
ROUND(SUM(t.Fraud_Flag = 'Yes') * 100.0
/ COUNT(*), 2) AS fraud_rate_pct,
SUM(CASE WHEN t.Fraud_Flag = 'Yes'
 THEN t.Amount ELSE 0 END) AS fraud_exposure
FROM fact_transactions t
JOIN dim_geography g ON g.Geo_ID = t.Geo_ID
GROUP BY g.Country, g.Region
ORDER BY fraud_rate_pct DESC;


-- Q17. High-Risk Customers (Multiple Fraud Incidents)
SELECT c.Customer_ID,
c.Customer_Name,
c.Account_Tier,
COUNT(*) AS fraud_txn_count,
SUM(t.Amount) AS total_fraud_amount
FROM fact_transactions t
JOIN dim_customer c ON c.Customer_ID = t.Customer_ID
WHERE t.Fraud_Flag = 'Yes'
GROUP BY c.Customer_ID, c.Customer_Name, c.Account_Tier
HAVING COUNT(*) >= 2
ORDER BY fraud_txn_count DESC;

-- Q18. Fraud Rate by Payment Method
SELECT Payment_Method,
COUNT(*) AS total_txns,
SUM(Fraud_Flag = 'Yes') AS fraud_count,
ROUND(SUM(Fraud_Flag = 'Yes') * 100.0
/ COUNT(*), 2) AS fraud_rate_pct
FROM fact_transactions
GROUP BY Payment_Method
ORDER BY fraud_rate_pct DESC;


-- ■ WINDOW FUNCTIONS & RANKINGS
-- Q19. Rank Customers by Spend Within Each Account Tier
SELECT c.Customer_ID,
c.Customer_Name,
c.Account_Tier,
SUM(t.Amount) AS total_spend,
RANK() OVER (
PARTITION BY c.Account_Tier
ORDER BY SUM(t.Amount) DESC
) AS rank_in_tier
FROM fact_transactions t
JOIN dim_customer c ON c.Customer_ID = t.Customer_ID
GROUP BY c.Customer_ID, c.Customer_Name, c.Account_Tier
ORDER BY c.Account_Tier, rank_in_tier;


-- Q20. Running Total of Transaction Amount per Customer
SELECT t.Transaction_ID,
t.Customer_ID,
d.Date,
t.Amount,
SUM(t.Amount) OVER (
PARTITION BY t.Customer_ID
ORDER BY d.Date, t.Time
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS running_total
FROM fact_transactions t
JOIN dim_date d ON d.Date_ID = t.Date_ID
ORDER BY t.Customer_ID, d.Date, t.Time;


-- Q21. Month-over-Month Revenue Growth
WITH monthly AS (
SELECT d.Year,
d.Month,
d.Month_Name,
SUM(t.Amount) AS revenue
FROM fact_transactions t
JOIN dim_date d ON d.Date_ID = t.Date_ID
GROUP BY d.Year, d.Month, d.Month_Name
)
SELECT Year,
Month_Name,
revenue,
LAG(revenue) OVER (ORDER BY Year, Month) AS prev_month_revenue,
ROUND(
(revenue - LAG(revenue) OVER (ORDER BY Year, Month))
/ LAG(revenue) OVER (ORDER BY Year, Month) * 100, 2
) AS mom_growth_pct
FROM monthly
ORDER BY Year, Month;


-- Q22. Percentile Distribution of Transaction Amounts
SELECT Transaction_ID,
Customer_ID,
Amount,
NTILE(4) OVER (ORDER BY Amount) AS quartile,
NTILE(10) OVER (ORDER BY Amount) AS decile,
PERCENT_RANK() OVER (ORDER BY Amount) AS pct_rank
FROM fact_transactions
WHERE Status = 'Completed'
ORDER BY Amount;

-- Q23. Top 3 Merchants by Spend per Category
WITH merchant_spend AS (
SELECT m.Category,
m.Merchant_Name,
SUM(t.Amount) AS total_spend,
DENSE_RANK() OVER (
PARTITION BY m.Category
ORDER BY SUM(t.Amount) DESC
) AS dr
FROM fact_transactions t
JOIN dim_merchant m ON m.Merchant_ID = t.Merchant_ID
GROUP BY m.Category, m.Merchant_Name
)
SELECT Category, Merchant_Name, total_spend, dr AS category_rank
FROM merchant_spend
WHERE dr <= 3
ORDER BY Category, dr;


-- ■ TREND & TIME-SERIES ANALYSIS
-- Q24. Quarterly Revenue Summary
SELECT d.Year,
CONCAT('Q', d.Quarter) AS quarter,
COUNT(*) AS txn_count,
SUM(t.Amount) AS revenue,
SUM(t.Transaction_Fee) AS fees,
ROUND(AVG(t.Amount), 2) AS avg_txn_value
FROM fact_transactions t
JOIN dim_date d ON d.Date_ID = t.Date_ID
GROUP BY d.Year, d.Quarter
ORDER BY d.Year, d.Quarter;


-- Q25. 7-Day Rolling Average Transaction Amount
WITH daily AS (
SELECT d.Date,
SUM(t.Amount) AS daily_revenue,
COUNT(*) AS daily_txns
FROM fact_transactions t
JOIN dim_date d ON d.Date_ID = t.Date_ID
GROUP BY d.Date
)
SELECT Date,
daily_revenue,
daily_txns,
ROUND(AVG(daily_revenue) OVER (
ORDER BY Date
ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
), 2) AS rolling_7d_avg
FROM daily
ORDER BY Date;

-- Q26. Year-over-Year Comparison by Category
SELECT m.Category,
d.Year,
SUM(t.Amount) AS total_spend
FROM fact_transactions t
JOIN dim_merchant m ON m.Merchant_ID = t.Merchant_ID
JOIN dim_date d ON d.Date_ID = t.Date_ID
GROUP BY m.Category, d.Year
ORDER BY m.Category, d.Year;


-- Q27. Daily Peak Transaction Hour Trend
WITH hourly_monthly AS (
SELECT d.Year,
d.Month,
HOUR(t.Time) AS hour_of_day,
COUNT(*) AS txn_count,
RANK() OVER (
PARTITION BY d.Year, d.Month
ORDER BY COUNT(*) DESC
) AS rnk
FROM fact_transactions t
JOIN dim_date d ON d.Date_ID = t.Date_ID
GROUP BY d.Year, d.Month, HOUR(t.Time)
)
SELECT Year, Month, hour_of_day AS peak_hour, txn_count
FROM hourly_monthly
WHERE rnk = 1
ORDER BY Year, Month;


-- ■ MERCHANT ANALYSIS
-- Q28. Top 20 Merchants by Transaction Volume
SELECT m.Merchant_Name,
m.Category,
m.Sub_Category,
COUNT(*) AS txn_count,
SUM(t.Amount) AS total_volume,
AVG(t.Amount) AS avg_amount,
SUM(t.Transaction_Fee) AS total_fees
FROM fact_transactions t
JOIN dim_merchant m ON m.Merchant_ID = t.Merchant_ID
GROUP BY m.Merchant_ID, m.Merchant_Name, m.Category, m.Sub_Category
ORDER BY total_volume DESC
LIMIT 20;

-- Q29. Merchant Category Share of Wallet
SELECT m.Category,
SUM(t.Amount) AS category_spend,
ROUND(SUM(t.Amount) * 100.0
/ SUM(SUM(t.Amount)) OVER(), 2) AS share_of_wallet_pct
FROM fact_transactions t
JOIN dim_merchant m ON m.Merchant_ID = t.Merchant_ID
GROUP BY m.Category
ORDER BY category_spend DESC;


-- Q30. Merchants Generating the Most Fees
SELECT m.Merchant_Name,
m.Category,
SUM(t.Transaction_Fee) AS total_fees,
COUNT(*) AS txn_count,
ROUND(SUM(t.Transaction_Fee)
/ COUNT(*), 4) AS avg_fee_per_txn
FROM fact_transactions t
JOIN dim_merchant m ON m.Merchant_ID = t.Merchant_ID
WHERE t.Transaction_Fee > 0
GROUP BY m.Merchant_ID, m.Merchant_Name, m.Category
ORDER BY total_fees DESC
LIMIT 20;


-- ■ CTEs, SUBQUERIES & ADVANCED JOINS
-- Q31. Customers Above Average Transaction Amount
SELECT c.Customer_ID,
c.Customer_Name,
c.Account_Tier,
ROUND(AVG(t.Amount), 2) AS avg_txn
FROM fact_transactions t
JOIN dim_customer c ON c.Customer_ID = t.Customer_ID
GROUP BY c.Customer_ID, c.Customer_Name, c.Account_Tier
HAVING AVG(t.Amount) > (
SELECT AVG(Amount) FROM fact_transactions
)
ORDER BY avg_txn DESC;

-- Q32. RFM (Recency, Frequency, Monetary) Segmentation
WITH rfm_base AS (
SELECT t.Customer_ID,
DATEDIFF(CURDATE(), MAX(d.Date)) AS recency,
COUNT(*) AS frequency,
SUM(t.Amount) AS monetary
FROM fact_transactions t
JOIN dim_date d ON d.Date_ID = t.Date_ID
WHERE t.Status = 'Completed'
GROUP BY t.Customer_ID
),
rfm_scored AS (
SELECT Customer_ID,
recency, frequency, monetary,
NTILE(5) OVER (ORDER BY recency ASC) AS r_score,
NTILE(5) OVER (ORDER BY frequency DESC) AS f_score,
NTILE(5) OVER (ORDER BY monetary DESC) AS m_score
FROM rfm_base
)
SELECT r.Customer_ID,
c.Customer_Name,
c.Account_Tier,
recency, frequency,
ROUND(monetary, 2) AS monetary,
r_score, f_score, m_score,
(r_score + f_score + m_score) AS rfm_total,
CASE
WHEN (r_score + f_score + m_score) >= 13 THEN 'Champions'
WHEN (r_score + f_score + m_score) >= 10 THEN 'Loyal'
WHEN r_score >= 4 THEN 'Recent'
WHEN f_score >= 4 THEN 'Frequent'
ELSE 'At Risk'
END AS rfm_segment
FROM rfm_scored r
JOIN dim_customer c ON c.Customer_ID = r.Customer_ID
ORDER BY rfm_total DESC;


-- Q33. First and Last Transaction per Customer
WITH bounds AS (
SELECT t.Customer_ID,
MIN(d.Date) AS first_txn_date,
MAX(d.Date) AS last_txn_date,
COUNT(*) AS total_txns
FROM fact_transactions t
JOIN dim_date d ON d.Date_ID = t.Date_ID
GROUP BY t.Customer_ID
)
SELECT b.*,
c.Customer_Name,
c.Account_Tier,
DATEDIFF(b.last_txn_date, b.first_txn_date) AS tenure_days
FROM bounds b
JOIN dim_customer c ON c.Customer_ID = b.Customer_ID
ORDER BY tenure_days DESC;


-- Q34. Cohort Retention — Monthly Active Customers
WITH first_txn AS (
SELECT t.Customer_ID,
DATE_FORMAT(MIN(d.Date), '%Y-%m') AS cohort_month
FROM fact_transactions t
JOIN dim_date d ON d.Date_ID = t.Date_ID
GROUP BY t.Customer_ID
),
activity AS (
SELECT t.Customer_ID,
DATE_FORMAT(d.Date, '%Y-%m') AS active_month
FROM fact_transactions t
JOIN dim_date d ON d.Date_ID = t.Date_ID
GROUP BY t.Customer_ID, active_month
)
SELECT f.cohort_month,
a.active_month,
COUNT(DISTINCT a.Customer_ID) AS active_customers
FROM first_txn f
JOIN activity a ON a.Customer_ID = f.Customer_ID
GROUP BY f.cohort_month, a.active_month
ORDER BY f.cohort_month, a.active_month;


-- ■ FINANCIAL METRICS & KPIs
-- Q35. Average Transaction Value (ATV) by Account Tier
SELECT c.Account_Tier,
COUNT(*) AS txn_count,
ROUND(SUM(t.Amount),2) AS total_amount,
ROUND(AVG(t.Amount),2) AS atv,
ROUND(STDDEV(t.Amount),2) AS stddev_amount
FROM fact_transactions t
JOIN dim_customer c ON c.Customer_ID = t.Customer_ID
WHERE t.Status = 'Completed'
GROUP BY c.Account_Tier
ORDER BY atv DESC;


-- Q36. Fee Revenue by Month
SELECT d.Year,
d.Month_Name,
COUNT(*) AS txns_with_fees,
ROUND(SUM(t.Transaction_Fee),2) AS total_fee_revenue,
ROUND(AVG(t.Transaction_Fee),4) AS avg_fee
FROM fact_transactions t
JOIN dim_date d ON d.Date_ID = t.Date_ID
WHERE t.Transaction_Fee > 0
GROUP BY d.Year, d.Month, d.Month_Name
ORDER BY d.Year, d.Month;


-- Q37. Net Impact Analysis — Credit vs Debit
SELECT Transaction_Type,
COUNT(*) AS txn_count,
ROUND(SUM(Amount), 2) AS gross_amount,
ROUND(SUM(Net_Impact), 2) AS net_impact,
ROUND(AVG(Net_Impact), 2) AS avg_net_impact
FROM fact_transactions
WHERE Status = 'Completed'
GROUP BY Transaction_Type
ORDER BY net_impact DESC;


-- Q38. Failed / Pending Transaction Loss Exposure
SELECT Status,
COUNT(*) AS txn_count,
ROUND(SUM(Amount),2) AS at_risk_amount,
ROUND(AVG(Amount),2) AS avg_amount
FROM fact_transactions
WHERE Status <> 'Completed'
GROUP BY Status
ORDER BY at_risk_amount DESC;


-- Q39. Currency-wise Volume Summary
SELECT g.Currency,
COUNT(*) AS txn_count,
SUM(t.Amount) AS total_amount,
AVG(t.Amount) AS avg_amount,
MAX(t.Amount) AS max_amount
FROM fact_transactions t
JOIN dim_geography g ON g.Geo_ID = t.Geo_ID
GROUP BY g.Currency
ORDER BY total_amount DESC;


-- ■ FINANCIAL LEDGER ANALYSIS
-- Q40. Category-wise Debit vs Credit Summary from Ledger
SELECT Category,
Sub_Category,
Transaction_Type,
COUNT(*) AS txn_count,
SUM(Amount) AS total_amount,
SUM(Net_Impact) AS net_impact
FROM financial_ledger
WHERE Status = 'Completed'
GROUP BY Category, Sub_Category, Transaction_Type
ORDER BY Category, Sub_Category, Transaction_Type;


-- Q41. Monthly Cash Flow Statement from Ledger
SELECT DATE_FORMAT(Date, '%Y-%m') AS month,
SUM(CASE WHEN Net_Impact > 0
 THEN Net_Impact ELSE 0 END) AS total_credits,
SUM(CASE WHEN Net_Impact < 0
 THEN Net_Impact ELSE 0 END) AS total_debits,
SUM(Net_Impact) AS net_cash_flow
FROM financial_ledger
WHERE Status = 'Completed'
GROUP BY month
ORDER BY month;


-- Q42. Top Spending Customers in the Ledger with Fraud Flag
SELECT Customer_ID,
Customer_Name,
Account_Tier,
COUNT(*) AS total_txns,
SUM(Amount) AS total_spend,
SUM(Fraud_Flag = 'Yes') AS fraud_txns,
ROUND(SUM(Fraud_Flag='Yes')
* 100.0 / COUNT(*),2) AS fraud_rate_pct
FROM financial_ledger
WHERE Status = 'Completed'
GROUP BY Customer_ID, Customer_Name, Account_Tier
ORDER BY total_spend DESC
LIMIT 25;


-- Q43. Sub-Category Drill-Down within Housing
SELECT Sub_Category,
COUNT(*) AS txn_count,
SUM(Amount) AS total_spend,
AVG(Amount) AS avg_spend,
COUNT(DISTINCT Customer_ID) AS unique_customers
FROM financial_ledger
WHERE Category = 'Housing'
AND Status = 'Completed'
GROUP BY Sub_Category
ORDER BY total_spend DESC;


-- Create a Summary View for Reporting
CREATE OR REPLACE VIEW vw_transaction_full AS
SELECT t.Transaction_ID,
t.Transaction_Type,
t.Payment_Method,
t.Status,
t.Fraud_Flag,
t.Amount,
t.Transaction_Fee,
t.Net_Impact,
t.Time,
c.Customer_ID,
c.Customer_Name,
c.Account_Tier,
d.Date,
d.Year,
d.Quarter,
d.Month_Name,
d.Day_Of_Week,
d.Is_Weekend,
m.Merchant_Name,
m.Category,
m.Sub_Category,
g.Region,
g.Country,
g.Currency
FROM fact_transactions t
JOIN dim_customer c ON c.Customer_ID = t.Customer_ID
JOIN dim_date d ON d.Date_ID = t.Date_ID
JOIN dim_merchant m ON m.Merchant_ID = t.Merchant_ID
JOIN dim_geography g ON g.Geo_ID = t.Geo_ID;



