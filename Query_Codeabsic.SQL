CREATE DATABASE Newspaper_survival_analysis;

USE Newspaper_survival_analysis;

SELECT * FROM dim_ad_category;
SELECT * FROM dim_city;
SELECT * FROM fact_ad_revenue;
SELECT * FROM fact_city_readiness;
SELECT * FROM fact_digital_pilot;
SELECT * FROM fact_print_sales;


-- Cleaning and Preprocessing Process :

-- Dim_ad_Category
-- Renaming columns for clarity
ALTER TABLE dim_ad_category
CHANGE COLUMN standard_ad_category standard_category VARCHAR(100),
CHANGE COLUMN example_brands example_brands TEXT;

-- Trim whitespace in all text fields
UPDATE dim_ad_category
SET ad_category_id = TRIM(ad_category_id),
    standard_category = TRIM(standard_category),
    category_group = TRIM(category_group),
    example_brands = TRIM(example_brands);



-- Cleaning on Fact_city_readiness :
-- Drop useless index column
ALTER TABLE fact_city_readiness DROP COLUMN MyUnknownColumn;

SHOW COLUMNS FROM fact_city_readiness;

-- Standardizing quarter (force YYYY-QN format)
UPDATE fact_city_readiness
SET quarter = CONCAT(SUBSTRING(quarter,1,4), '-Q', SUBSTRING(quarter,6,1))
WHERE quarter REGEXP '^[0-9]{4}[- ]?[Qq][1-4]$';


-- Cleaning fact_digital_Pilot :
SELECT * FROM fact_digital_pilot;

--  Dropping MyUnknown Column Field :
ALTER TABLE fact_digital_pilot DROP COLUMN MyUnknownColumn;

-- Renaming long column
ALTER TABLE fact_digital_pilot
CHANGE COLUMN cumulative_feedback_from_customers customer_feedback TEXT;

-- Clean up values
UPDATE fact_digital_pilot
SET launch_month = STR_TO_DATE(CONCAT(launch_month, '-01'), '%Y-%m-%d');




-- Cleaning fact_print_sales :
SELECT * FROM fact_print_sales;

-- Making first Letter capital in Language field :

UPDATE fact_print_sales
SET Language = CONCAT(
    UPPER(LEFT(Language, 1)),
    LOWER(SUBSTRING(Language, 2))
)
WHERE Language IS NOT NULL;

-- Remove underscores from State
UPDATE fact_print_sales
SET State = REPLACE(State, '_', ' ');

-- Making first Letter capital in Language field :
UPDATE fact_print_sales
SET State = CONCAT(
    UPPER(LEFT(State, 1)),
    LOWER(SUBSTRING(State, 2))
)
WHERE State IS NOT NULL;

-- Convert Copies Sold to INT And changing column Name also  :
ALTER TABLE fact_print_sales 
CHANGE `Copies Sold` copies_sold INT;

ALTER TABLE fact_print_sales MODIFY copies_sold INT;

-- Convert Month to DATE
ALTER TABLE fact_print_sales MODIFY Month DATE;






-- Business Request – 1: Monthly Circulation Drop Check 
-- Generate a report showing the top 3 months (2019–2024) where any city recorded the 
-- sharpest month-over-month decline in net_circulation. 
-- Fields: 
-- • city_name 
-- • month (YYYY-MM) 
-- • net_circulation 

WITH Circulation_drop AS (
SELECT dc.City AS city_name, DATE_FORMAT(fps.Month, '%Y-%m') AS month, fps.Net_Circulation AS net_circulation,
(fps.Net_Circulation - LAG(fps.Net_Circulation) OVER(PARTITION BY fps.City_ID ORDER BY fps.Month)
) AS month_change
FROM fact_print_sales fps JOIN dim_city dc ON fps.City_ID = dc.city_id
WHERE YEAR(fps.Month) BETWEEN 2019 AND 2024
)
SELECT city_name, month, net_circulation, month_change
FROM Circulation_drop
WHERE month_change IS NOT NULL 
ORDER BY month_change ASC
LIMIT 3;  --- Negative_values means its declining : Positive means increasing



SELECT * FROM dim_ad_category;
SELECT * FROM fact_ad_revenue;
-- Business Request – 2: Yearly Revenue Concentration by Category 
-- Identify ad categories that contributed > 50% of total yearly ad revenue. 
-- Fields: 
-- • year 
-- • category_name 
-- • category_revenue  
-- • total_revenue_year  
-- • pct_of_year_total

WITH yearly_category_revenue AS (
    SELECT  YEAR(far.quarter) AS year, dac.standard_ad_category AS category_name, SUM(far.ad_revenue) AS category_revenue
    FROM fact_ad_revenue far JOIN dim_ad_category dac 
	ON far.ad_category = dac.ad_category_id
    GROUP BY YEAR(far.quarter), dac.standard_ad_category
),
yearly_total AS (
    SELECT 
        YEAR(quarter) AS year,
        SUM(ad_revenue) AS total_revenue_year
    FROM fact_ad_revenue
    GROUP BY YEAR(quarter)
)
SELECT ycr.year, ycr.category_name, ycr.category_revenue, yt.total_revenue_year,
    ROUND((ycr.category_revenue / yt.total_revenue_year) * 100, 2) AS pct_of_year_total
FROM yearly_category_revenue ycr JOIN yearly_total yt 
ON ycr.year = yt.year
WHERE (ycr.category_revenue / yt.total_revenue_year) > 0.5
ORDER BY ycr.year, pct_of_year_total DESC;





SELECT * FROM dim_city;
SELECT * FROM fact_print_sales;
-- Business Request – 3: 2024 Print Efficiency Leaderboard 
-- For 2024, rank cities by print efficiency = net_circulation / copies_printed. Return top 5. 
-- Fields: 
-- • city_name 
-- • copies_printed_2024 
-- • net_circulation_2024 
-- • efficiency_ratio = net_circulation_2024 / copies_printed_2024 
-- • efficiency_rank_2024 
WITH efficiency_2024 AS (
SELECT dc.City AS city_name,
SUM(fps.`Copies Sold` + fps.copies_returned) AS copies_printed_2024, -- the column name is not in correct format so we have used paranthesis
SUM(fps.Net_Circulation) AS net_circulation_2024,
ROUND(SUM(fps.Net_Circulation) / SUM(fps.`Copies Sold` + fps.copies_returned), 4) AS efficiency_ratio
    FROM fact_print_sales fps JOIN dim_city dc 
	ON fps.City_ID = dc.city_id
    WHERE YEAR(fps.Month) = 2024
    GROUP BY dc.City
)
SELECT 
    city_name,
    copies_printed_2024,
    net_circulation_2024,
    efficiency_ratio,
    RANK() OVER (ORDER BY efficiency_ratio DESC) AS efficiency_rank_2024
FROM efficiency_2024
ORDER BY efficiency_rank_2024
LIMIT 5;











SELECT * FROM dim_city;
SELECT * FROM fact_city_readiness;
-- Business Request – 4 : Internet Readiness Growth (2021) 
-- For each city, compute the change in internet penetration from Q1-2021 to Q4-2021 
-- and identify the city with the highest improvement. 
-- Fields: 
-- • city_name 
-- • internet_rate_q1_2021 
-- • internet_rate_q4_2021 
-- • delta_internet_rate = internet_rate_q4_2021 − internet_rate_q1_2021 

WITH Readiness AS (
    SELECT
        City_ID,
        CASE WHEN Quarter = '2021-Q1' THEN internet_penetration END AS internet_rate_q1_2021,
        CASE WHEN Quarter = '2021-Q4' THEN internet_penetration END AS internet_rate_q4_2021
    FROM fact_city_readiness
    WHERE Quarter IN ('2021-Q1', '2021-Q4')
)
SELECT
    dim_city.city AS city_name,
    MAX(Readiness.internet_rate_q1_2021) AS internet_rate_q1_2021,
    MAX(Readiness.internet_rate_q4_2021) AS internet_rate_q4_2021,
    MAX(Readiness.internet_rate_q4_2021) - MAX(Readiness.internet_rate_q1_2021) AS delta_internet_rate
FROM Readiness JOIN dim_city 
ON Readiness.City_ID = dim_city.city_id
GROUP BY city_name
ORDER BY delta_internet_rate DESC;
    
    
    
    
    
    
    

    
-- Business Request – 5: Consistent Multi-Year Decline (2019→2024) 
-- Find cities where both net_circulation and ad_revenue decreased every year from 2019 
-- through 2024 (strictly decreasing sequences). 
-- Fields: 
-- • city_name 
-- • year 
-- • yearly_net_circulation 
-- • yearly_ad_revenue 
-- • is_declining_print (Yes/No per city over 2019–2024) 
-- • is_declining_ad_revenue (Yes/No) 
-- • is_declining_both (Yes/No)    
    

  WITH yearly_aggregates AS (
    SELECT
      dc.city AS city_name,
      YEAR(fps.Month) AS year,
      SUM(fps.Net_Circulation) AS yearly_net_circulation,
      SUM(
        CASE
          WHEN far.currency = 'INR' THEN far.ad_revenue
          ELSE 0
        END
      ) AS yearly_ad_revenue
    FROM fact_print_sales AS fps JOIN dim_city AS dc 
      ON fps.city_id = dc.city_id
      JOIN fact_ad_revenue AS far ON fps.edition_id = far.edition_id
    WHERE YEAR(fps.Month) BETWEEN 2019 AND 2024
    GROUP BY 1, 2
  ),
  lag_data AS (
    SELECT city_name, year, yearly_net_circulation, yearly_ad_revenue,
      LAG(yearly_net_circulation, 1) OVER (
        PARTITION BY city_name
        ORDER BY
          year
      ) AS prev_net_circulation,
      LAG(yearly_ad_revenue, 1) OVER (
        PARTITION BY city_name
        ORDER BY
          year
      ) AS prev_ad_revenue
    FROM
      yearly_aggregates
  ),
  decline_check AS (
   SELECT
      city_name,
      SUM(
        CASE
          WHEN yearly_net_circulation < prev_net_circulation THEN 1
          ELSE 0
        END
      ) AS declining_print_count,
      SUM(
        CASE
          WHEN yearly_ad_revenue < prev_ad_revenue THEN 1
          ELSE 0
        END
      ) AS declining_ad_revenue_count
    FROM lag_data
    GROUP BY city_name
    HAVING COUNT(year) = 6 -- Ensure the city has data for all 6 years (2019 to 2024)
  )
SELECT T1.city_name, T1.year, T1.yearly_net_circulation, T1.yearly_ad_revenue,
  CASE
    WHEN T2.declining_print_count = 5 THEN 'Yes'
    ELSE 'No'
  END AS is_declining_print,
  CASE
    WHEN T2.declining_ad_revenue_count = 5 THEN 'Yes'
    ELSE 'No'
  END AS is_declining_ad_revenue,
  CASE
    WHEN T2.declining_print_count = 5
    AND T2.declining_ad_revenue_count = 5 THEN 'Yes'
    ELSE 'No'
  END AS is_declining_both
FROM yearly_aggregates AS T1 JOIN decline_check AS T2 
ON T1.city_name = T2.city_name
WHERE T2.declining_print_count = 5 AND T2.declining_ad_revenue_count = 5
ORDER BY T1.city_name, T1.year;
  





-- Business Request – 6 : 2021 Readiness vs Pilot Engagement Outlier 
-- In 2021, identify the city with the highest digital readiness score but among the bottom 3 
-- in digital pilot engagement. 
-- readiness_score = AVG(smartphone_rate, internet_rate, literacy_rate) 
-- “Bottom 3 engagement” uses the chosen engagement metric provided (e.g., 
-- engagement_rate, active_users, or sessions). 
-- Fields: 
-- • city_name 
-- • readiness_score_2021 
-- • engagement_metric_2021 
-- • readiness_rank_desc 
-- • engagement_rank_asc 
-- • is_outlier (Yes/No)

WITH readiness_data AS (
    SELECT
      city_id, AVG((literacy_rate + smartphone_penetration + internet_penetration) / 3) AS readiness_score_2021
    FROM fact_city_readiness
    WHERE quarter LIKE '%2021%'
    GROUP BY city_id
  ),
  engagement_data AS (
   SELECT
      city_id, SUM(users_reached) AS engagement_metric_2021
    FROM fact_digital_pilot
    WHERE launch_month LIKE '%2021%'
    GROUP BY city_id
  ),
  ranked_data AS (
    SELECT dc.city AS city_name, rd.readiness_score_2021, ed.engagement_metric_2021,
      RANK() OVER (ORDER BY rd.readiness_score_2021 DESC) AS readiness_rank_desc,
      RANK() OVER (ORDER BY ed.engagement_metric_2021 ASC) AS engagement_rank_asc
    FROM readiness_data AS rd
      JOIN engagement_data AS ed ON rd.city_id = ed.city_id
      JOIN dim_city AS dc ON rd.city_id = dc.city_id
  )

SELECT city_name, readiness_score_2021, engagement_metric_2021, readiness_rank_desc, engagement_rank_asc,
  CASE
    WHEN readiness_rank_desc = 1
    AND engagement_rank_asc <= 3 THEN 'Yes'
    ELSE 'No'
  END AS is_outlier
FROM ranked_data
ORDER BY readiness_rank_desc;










-- Primary and Secondary_Analysis:

/*1.  Print Circulation Trends 
What is the trend in copies printed, copies sold, and net circulation across all 
cities from 2019 to 2024? How has this changed year-over-year? */

SELECT
    YEAR(Month) AS year,
    SUM(copies_sold) AS total_copies_sold,
    SUM(copies_returned) AS total_copies_returned,
    SUM(Net_Circulation) AS total_net_circulation
FROM fact_print_sales
WHERE YEAR(Month) BETWEEN 2019 AND 2024
GROUP BY YEAR(Month)
ORDER BY YEAR(Month);


/* 2. To Performing Cities 
Which cities contributed the highest to net circulation and copies sold in 2024? 
Are these cities still profitable to operate in? */

SELECT
    d.city,
    SUM(f.copies_sold) AS total_copies_sold_2024,
    SUM(f.Net_Circulation) AS total_net_circulation_2024
FROM fact_print_sales f JOIN dim_city d
ON f.City_ID = d.city_id
WHERE YEAR(f.Month) = 2024
GROUP BY d.city
ORDER BY total_net_circulation_2024 DESC, total_copies_sold_2024 DESC;



/* 3. Print Waste Analysis 
Which cities have the largest gap between copies printed and net circulation, and 
how has that gap changed over time? */

SELECT
    d.city,
    YEAR(f.Month) AS year,
    (SUM(f.copies_sold) + SUM(f.copies_returned)) AS total_copies_printed,
    SUM(f.Net_Circulation) AS total_net_circulation,
    (SUM(f.copies_sold) + SUM(f.copies_returned)) - SUM(f.Net_Circulation) AS gap_in_circulation
FROM fact_print_sales f JOIN dim_city d
ON f.City_ID = d.city_id
GROUP BY d.city, YEAR(f.Month)
ORDER BY gap_in_circulation DESC;




/*4. Ad Revenue Trends by Category 
How has ad revenue evolved across different ad categories between 2019 and 
2024? Which categories have remained strong, and which have declined? */

SELECT
    d.standard_category AS ad_category,
    CASE
        WHEN a.quarter LIKE '%2019%' THEN 2019
        WHEN a.quarter LIKE '%2020%' THEN 2020
        WHEN a.quarter LIKE '%2021%' THEN 2021
        WHEN a.quarter LIKE '%2022%' THEN 2022
        WHEN a.quarter LIKE '%2023%' THEN 2023
        WHEN a.quarter LIKE '%2024%' THEN 2024
        ELSE NULL
    END AS year,
    SUM(CAST(a.ad_revenue AS DECIMAL)) AS total_ad_revenue
FROM fact_ad_revenue a JOIN dim_ad_category d ON a.ad_category = d.ad_category_id
WHERE a.quarter LIKE '%201%' OR a.quarter LIKE '%202%'
GROUP BY d.standard_category , year
ORDER BY d.standard_category , year;




/* 5. City-Level Ad Revenue Performance 
Which cities generated the most ad revenue, and how does that correlate with 
their print circulation?  */

SELECT
    d.city,
    SUM(CAST(a.ad_revenue AS DECIMAL)) AS total_ad_revenue,
    SUM(f.Net_Circulation) AS total_net_circulation
FROM fact_ad_revenue a
JOIN fact_print_sales f ON a.edition_id = f.edition_ID
JOIN dim_city d  ON f.City_ID = d.city_id
GROUP BY d.city
ORDER BY total_ad_revenue DESC, total_net_circulation DESC;




/* 6. Digital Readiness vs. Performance 
Which cities show high digital readiness (based on smartphone, internet, and 
literacy rates) but had low digital pilot engagement? */

SELECT
    dc.city,
    (AVG(fcr.literacy_rate) + AVG(fcr.smartphone_penetration) + AVG(fcr.internet_penetration)) / 3 AS digital_readiness_score,
    SUM(fdp.users_reached + fdp.downloads_or_accesses) AS digital_engagement_score
FROM dim_city dc
JOIN fact_city_readiness fcr ON dc.city_id = fcr.city_id
JOIN fact_digital_pilot fdp ON dc.city_id = fdp.city_id
GROUP BY dc.city
ORDER BY digital_readiness_score DESC, digital_engagement_score ASC;





/* 7. Ad Revenue vs. Circulation ROI 
Which cities had the highest ad revenue per net circulated copy? Is this ratio 
improving or worsening over time? */

SELECT
    d.city,
    CASE
        WHEN a.quarter LIKE '%2019%' THEN 2019
        WHEN a.quarter LIKE '%2020%' THEN 2020
        WHEN a.quarter LIKE '%2021%' THEN 2021
        WHEN a.quarter LIKE '%2022%' THEN 2022
        WHEN a.quarter LIKE '%2023%' THEN 2023
        WHEN a.quarter LIKE '%2024%' THEN 2024
        ELSE NULL
    END AS year,
    SUM(CAST(a.ad_revenue AS DECIMAL)) AS total_ad_revenue,
    SUM(f.Net_Circulation) AS total_net_circulation,
    (SUM(CAST(a.ad_revenue AS DECIMAL)) / SUM(f.Net_Circulation)) AS revenue_per_copy
FROM fact_ad_revenue a
JOIN fact_print_sales f ON a.edition_id = f.edition_ID
JOIN dim_city d ON f.City_ID = d.city_id
WHERE a.quarter LIKE '%201%' OR a.quarter LIKE '%202%'
GROUP BY d.city, year
ORDER BY revenue_per_copy DESC, year;





/* 8. Digital Relaunch City Prioritization 
Based on digital readiness, pilot engagement, and print decline, which 3 cities should be 
prioritized for Phase 1 of the digital relaunch? */

SELECT
    dc.city,
    AVG(fcr.literacy_rate + fcr.smartphone_penetration + fcr.internet_penetration) / 3 AS digital_readiness_score,
    SUM(fdp.users_reached + fdp.downloads_or_accesses) AS digital_engagement_score,
    SUM(fps.Net_Circulation) AS total_net_circulation
FROM dim_city dc
LEFT JOIN fact_city_readiness fcr ON dc.city_id = fcr.city_id
LEFT JOIN fact_digital_pilot fdp ON dc.city_id = fdp.city_id
LEFT JOIN fact_print_sales fps ON dc.city_id = fps.City_ID
GROUP BY dc.city
ORDER BY digital_readiness_score DESC, digital_engagement_score ASC, total_net_circulation ASC
LIMIT 3;




-- Additional Analysis

/*1. Which cities or demographics show a strong positive 
correlation between declining print circulation and increasing digital pilot engagement? */

WITH PrintTrends AS (
    SELECT
        City_ID,
        SUM(Net_Circulation) AS total_net_circulation,
        LAG(SUM(Net_Circulation), 1, 0) OVER (PARTITION BY City_ID ORDER BY YEAR(Month)) AS previous_year_circulation,
        (SUM(Net_Circulation) - LAG(SUM(Net_Circulation), 1, 0) OVER (PARTITION BY City_ID ORDER BY YEAR(Month))) AS circulation_change
    FROM fact_print_sales
    GROUP BY City_ID, YEAR(Month)
),
DigitalEngagement AS (
    SELECT city_id,
        SUM(users_reached + downloads_or_accesses) AS digital_engagement_score
    FROM fact_digital_pilot
    GROUP BY city_id
)
SELECT d.city, pt.circulation_change AS print_circulation_change,
    de.digital_engagement_score
FROM PrintTrends pt
JOIN DigitalEngagement de ON pt.City_ID = de.city_id
JOIN dim_city d ON pt.City_ID = d.city_id
WHERE pt.circulation_change < 0
ORDER BY pt.circulation_change ASC, de.digital_engagement_score DESC;





/*2. Is there a time lag between changes in print circulation and changes in 
ad revenue for specific cities or ad categories? */

WITH YearlyMetrics AS (
    -- Calculate total print circulation and ad revenue per city, per year
    SELECT dc.city_id, YEAR(fpt.Month) AS year,
        SUM(fpt.Net_Circulation) AS total_net_circulation,
        SUM(CAST(far.ad_revenue AS DECIMAL)) AS total_ad_revenue
    FROM dim_city dc JOIN fact_print_sales fpt ON dc.city_id = fpt.City_ID
    JOIN fact_ad_revenue far ON fpt.edition_ID = far.edition_id
    GROUP BY dc.city_id, YEAR(fpt.Month)
),
LaggedMetrics AS (
    -- Calculate the year-over-year change for each metric and the lag
    SELECT city_id, year, total_net_circulation, total_ad_revenue,
        LAG(total_net_circulation, 1) OVER (PARTITION BY city_id ORDER BY year) AS prev_year_circulation,
        LAG(total_ad_revenue, 1) OVER (PARTITION BY city_id ORDER BY year) AS prev_year_ad_revenue
    FROM YearlyMetrics
)
SELECT dc.city, lm.year, lm.total_net_circulation, lm.total_ad_revenue, lm.prev_year_circulation,
    lm.prev_year_ad_revenue,
    CASE
        WHEN lm.prev_year_circulation IS NULL OR lm.prev_year_circulation = 0 THEN 'No Previous Data'
        ELSE (lm.total_net_circulation - lm.prev_year_circulation) / lm.prev_year_circulation
    END AS circulation_yoy_change,
    CASE
        WHEN lm.prev_year_ad_revenue IS NULL OR lm.prev_year_ad_revenue = 0 THEN 'No Previous Data'
        ELSE (lm.total_ad_revenue - lm.prev_year_ad_revenue) / lm.prev_year_ad_revenue
    END AS ad_revenue_yoy_change,
    CASE
        WHEN (lm.total_net_circulation < lm.prev_year_circulation AND lm.total_ad_revenue < lm.prev_year_ad_revenue)
        THEN 'Potential Lag: Both Declined'
        WHEN (lm.total_net_circulation < lm.prev_year_circulation AND lm.total_ad_revenue >= lm.prev_year_ad_revenue)
        THEN 'No Lag: Print Decline, Ad Revenue Stable/Grew'
        ELSE 'Other'
    END AS lag_analysis
FROM LaggedMetrics lm
JOIN dim_city dc ON lm.city_id = dc.city_id
ORDER BY dc.city, lm.year;




/* 3. Do the most profitable cities (based on ad revenue per net circulated copy) align with the 
cities that have the highest digital readiness scores? */

WITH Profitability AS (
    SELECT f.City_ID,
        SUM(CAST(a.ad_revenue AS DECIMAL)) / SUM(f.Net_Circulation) AS profitability_ratio
    FROM fact_print_sales f JOIN fact_ad_revenue a ON f.edition_ID = a.edition_id
    GROUP BY f.City_ID
),
DigitalReadiness AS (
    SELECT City_ID,
        AVG(literacy_rate + smartphone_penetration + internet_penetration) / 3 AS digital_readiness_score
    FROM fact_city_readiness
    GROUP BY City_ID
)
SELECT d.city, p.profitability_ratio, r.digital_readiness_score,
    RANK() OVER (ORDER BY p.profitability_ratio DESC) AS profitability_rank,
    RANK() OVER (ORDER BY r.digital_readiness_score DESC) AS readiness_rank
FROM Profitability p JOIN DigitalReadiness r ON p.City_ID = r.City_ID
JOIN dim_city d ON p.City_ID = d.city_id
ORDER BY profitability_rank, readiness_rank;


