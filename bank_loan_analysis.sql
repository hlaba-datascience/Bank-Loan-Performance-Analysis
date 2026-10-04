/* ==============================================================================
   PROJECT: Bank Loan Performance & Risk Analysis
   PURPOSE: Extract core financial KPIs, evaluate portfolio risk, and compute 
            Month-over-Month (MoM) growth benchmarks for Power BI validation.
   ============================================================================== */

-- 1. OVERALL PORTFOLIO KPIs
SELECT 
    COUNT(id) AS Total_Loan_Applications,
    SUM(loan_amount) AS Total_Funded_Amount,
    SUM(total_payment) AS Total_Amount_Received,
    ROUND(AVG(int_rate) * 100, 2) AS Avg_Interest_Rate_Pct,
    ROUND(AVG(dti) * 100, 2) AS Avg_DTI_Pct
FROM bank_loan_data;

-- 2. GOOD LOAN VS BAD LOAN PERFORMANCE
SELECT
    CASE 
        WHEN loan_status IN ('Fully Paid', 'Current') THEN 'Good Loan'
        WHEN loan_status = 'Charged Off' THEN 'Bad Loan'
    END AS Loan_Category,
    COUNT(id) AS Applications,
    ROUND(COUNT(id) * 100.0 / (SELECT COUNT(*) FROM bank_loan_data), 2) AS Portfolio_Share_Pct,
    SUM(loan_amount) AS Funded_Amount,
    SUM(total_payment) AS Received_Amount,
    ROUND(SUM(total_payment) - SUM(loan_amount), 2) AS Net_Cash_Flow
FROM bank_loan_data
GROUP BY 
    CASE 
        WHEN loan_status IN ('Fully Paid', 'Current') THEN 'Good Loan'
        WHEN loan_status = 'Charged Off' THEN 'Bad Loan'
    END;

-- 3. MONTH-OVER-MONTH (MoM) TREND ANALYSIS (Using Window Functions)
WITH MonthlyMetrics AS (
    SELECT 
        CAST(SUBSTR(issue_date, 4, 2) AS INTEGER) AS Month_Number,
        COUNT(id) AS Monthly_Applications,
        SUM(loan_amount) AS Monthly_Funded_Amount,
        SUM(total_payment) AS Monthly_Received_Amount
    FROM bank_loan_data
    GROUP BY CAST(SUBSTR(issue_date, 4, 2) AS INTEGER)
)
SELECT 
    Month_Number,
    Monthly_Applications,
    Monthly_Funded_Amount,
    Monthly_Received_Amount,
    LAG(Monthly_Applications) OVER (ORDER BY Month_Number) AS Prev_Month_Applications,
    ROUND(
        (Monthly_Applications - LAG(Monthly_Applications) OVER (ORDER BY Month_Number)) * 100.0 / 
        LAG(Monthly_Applications) OVER (ORDER BY Month_Number), 2
    ) AS Applications_MoM_Growth_Pct
FROM MonthlyMetrics
ORDER BY Month_Number;

-- 4. RISK BREAKDOWN BY CREDIT GRADE
SELECT 
    grade,
    COUNT(id) AS Total_Applications,
    SUM(loan_amount) AS Total_Funded_Amount,
    ROUND(AVG(int_rate) * 100, 2) AS Avg_Interest_Rate,
    ROUND(SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(id), 2) AS Default_Rate_Pct
FROM bank_loan_data
GROUP BY grade
ORDER BY grade ASC;

-- 5. GEOGRAPHIC CONCENTRATION & RECOVERY
SELECT 
    address_state,
    COUNT(id) AS Total_Applications,
    SUM(loan_amount) AS Total_Funded_Amount,
    SUM(total_payment) AS Total_Received_Amount,
    ROUND(SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(id), 2) AS Default_Rate_Pct
FROM bank_loan_data
GROUP BY address_state
ORDER BY Total_Applications DESC;