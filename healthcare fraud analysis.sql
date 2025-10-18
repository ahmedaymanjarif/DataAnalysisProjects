-- Record Overview

SELECT COUNT(*) AS total_claims,
	SUM(Amount_Billed) AS total_billed,
	AVG(Amount_Billed) AS avg_billed,
	ROUND(SUM(CASE WHEN FRAUD_TYPE <> 'No Fraud' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as fraud_rate_pct
FROM portfolioProject..[combined_nhis_dataset_with_fraud_types (1)]


-- Fraud Distribution

SELECT
	FRAUD_TYPE,
	COUNT(*) AS claim_count,
	ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM portfolioProject..[combined_nhis_dataset_with_fraud_types (1)]), 2) AS percentage
FROM portfolioProject..[combined_nhis_dataset_with_fraud_types (1)]
GROUP BY FRAUD_TYPE
ORDER BY claim_count desc


-- Cleaning Gender Data

UPDATE portfolioProject..[combined_nhis_dataset_with_fraud_types (1)]
SET GENDER = 
	CASE 
		WHEN GENDER IN ('F', 'FF') THEN 'F'
		WHEN GENDER IN ('M', 'MF') THEN 'M'
		ELSE 'Unknown'
	END


-- Gender Analysis 

SELECT GENDER,
	COUNT(*) AS total_claims,
	AVG(Amount_Billed) AS avg_claim_amount
FROM portfolioProject..[combined_nhis_dataset_with_fraud_types (1)]
GROUP BY GENDER


-- Age group breakdown

SELECT 
	CASE 
		WHEN Age < 18 THEN 'Under 18'
		WHEN Age BETWEEN 18 AND 35 THEN '18-35'
		WHEN Age BETWEEN 36 and 55 THEN '36-55'
		WHEN AGE > 55 THEN '55+'
	END AS Age_Group,
	COUNT(*) as total_claims,
	AVG(amount_billed) as avg_billed
FROM portfolioProject..[combined_nhis_dataset_with_fraud_types (1)]
GROUP BY 
	CASE
		WHEN Age < 18 THEN 'Under 18'
		WHEN Age BETWEEN 18 AND 35 THEN '18-35'
		WHEN Age BETWEEN 36 and 55 THEN '36-55'
		WHEN AGE > 55 THEN '55+'
	END
ORDER BY total_claims desc


-- Top 10 highest billed claims

SELECT TOP 10 *
FROM portfolioProject..[combined_nhis_dataset_with_fraud_types (1)]
ORDER BY Amount_Billed desc


-- Encounter Duration Analysis

SELECT
	Patient_ID,
	DATEDIFF(DAY, DATE_OF_ENCOUNTER, DATE_OF_DISCHARGE) AS Length_of_Stay,
	Amount_Billed,
	FRAUD_TYPE
FROM portfolioProject..[combined_nhis_dataset_with_fraud_types (1)]
WHERE DATE_OF_ENCOUNTER IS NOT NULL AND DATE_OF_DISCHARGE IS NOT NULL
ORDER BY Length_of_Stay desc


-- Fraud pattern by diagnosis

SELECT
	DIAGNOSIS,
	COUNT(*) AS total_claims,
	SUM (CASE WHEN FRAUD_TYPE <> 'No Fraud' THEN 1 ELSE 0 END) AS fraud_claims,
	ROUND(SUM(CASE WHEN FRAUD_TYPE <> 'No Fraud' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as fraud_rate_pct
FROM portfolioProject..[combined_nhis_dataset_with_fraud_types (1)]
GROUP BY DIAGNOSIS
ORDER BY fraud_rate_pct desc


-- Fraud rate by gender and age group 

SELECT 
    GENDER,
    CASE 
        WHEN Age < 18 THEN 'Under 18'
        WHEN Age BETWEEN 18 AND 35 THEN '18-35'
        WHEN Age BETWEEN 36 and 55 THEN '36-55'
        WHEN AGE > 55 THEN '55+'
    END AS Age_Group,
    COUNT(*) AS total_claims,
    SUM(CASE WHEN FRAUD_TYPE <> 'No Fraud' THEN 1 ELSE 0 END) AS fraud_claims,
    ROUND(SUM(CASE WHEN FRAUD_TYPE <> 'No Fraud' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_rate_pct
FROM portfolioProject..[combined_nhis_dataset_with_fraud_types (1)]
GROUP BY GENDER,
    CASE 
        WHEN Age < 18 THEN 'Under 18'
        WHEN Age BETWEEN 18 AND 35 THEN '18-35'
        WHEN Age BETWEEN 36 and 55 THEN '36-55'
        WHEN AGE > 55 THEN '55+'
    END
ORDER BY fraud_rate_pct DESC;


--average amount billed in fraud vs non fraud claims

SELECT 
    CASE WHEN FRAUD_TYPE <> 'No Fraud' THEN 'Fraud' ELSE 'No Fraud' END AS Fraud_Status,
    COUNT(*) AS total_claims,
    AVG(Amount_Billed) AS avg_billed,
    SUM(Amount_Billed) AS total_billed
FROM portfolioProject..[combined_nhis_dataset_with_fraud_types (1)]
GROUP BY CASE WHEN FRAUD_TYPE <> 'No Fraud' THEN 'Fraud' ELSE 'No Fraud' END


-- staying length vs fraud

SELECT 
    CASE WHEN FRAUD_TYPE <> 'No Fraud' THEN 'Fraud' ELSE 'No Fraud' END AS Fraud_Status,
    AVG(DATEDIFF(DAY, DATE_OF_ENCOUNTER, DATE_OF_DISCHARGE)) AS avg_length_of_stay
FROM portfolioProject..[combined_nhis_dataset_with_fraud_types (1)]
WHERE DATE_OF_ENCOUNTER IS NOT NULL AND DATE_OF_DISCHARGE IS NOT NULL
GROUP BY CASE WHEN FRAUD_TYPE <> 'No Fraud' THEN 'Fraud' ELSE 'No Fraud' END;


-- top fraudulent diagnosis codes

SELECT
    DIAGNOSIS,
    COUNT(*) AS total_claims,
    SUM(CASE WHEN FRAUD_TYPE <> 'No Fraud' THEN 1 ELSE 0 END) AS fraud_claims,
    ROUND(SUM(CASE WHEN FRAUD_TYPE <> 'No Fraud' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_rate_pct,
    AVG(Amount_Billed) AS avg_billed
FROM portfolioProject..[combined_nhis_dataset_with_fraud_types (1)]
GROUP BY DIAGNOSIS
--HAVING COUNT(*) > 15
ORDER BY fraud_rate_pct DESC







