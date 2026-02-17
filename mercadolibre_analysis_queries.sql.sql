FUNNEL AND RETENTION ANALYSIS FOR MERCADOLIBRE
PART 1: EXPLORE THE SCHEMA AND UNDERSTAND THE FLOW
1.1. LIST COLUMNS AND DATA TYPES
Objective: Understand the structure of the mercadolibre_funnel table.

SQL

SELECT *
FROM mercadolibre_funnel
LIMIT 5;
Objective: Understand the structure of the mercadolibre_retention table.

SQL

SELECT *
FROM mercadolibre_retention
LIMIT 5;
1.2 EXPLORE EVENT TYPES
Objective: Confirm the funnel sequence in the mercadolibre_funnel table.

SQL

SELECT DISTINCT 
    event_name
FROM 
    mercadolibre_funnel
ORDER BY 
    event_name ASC;
PART 2: BUILD THE CONVERSION FUNNEL
2.1 CREATE CTES BY STAGE
Objective: Build unique user blocks per event (CTEs) within the range 2025-01-01 → 2025-08-31, join them, and count users per funnel stage.

SQL

-- 1) Create a CTE per event with the desired date range
-- 2) Join the CTEs anchoring on signup and count users per stage

WITH first_visit AS (
    SELECT DISTINCT user_id 
    FROM mercadolibre_funnel 
    WHERE event_name = 'first_visit' 
      AND event_date BETWEEN '2025-01-01' AND '2025-08-31'
),
select_item AS (
    SELECT DISTINCT user_id 
    FROM mercadolibre_funnel 
    WHERE (event_name = 'select_item' OR event_name = 'select_promotion')
      AND event_date BETWEEN '2025-01-01' AND '2025-08-31'
),
add_to_cart AS (
    SELECT DISTINCT user_id 
    FROM mercadolibre_funnel 
    WHERE event_name = 'add_to_cart' 
      AND event_date BETWEEN '2025-01-01' AND '2025-08-31'
),
begin_checkout AS (
    SELECT DISTINCT user_id 
    FROM mercadolibre_funnel 
    WHERE event_name = 'begin_checkout' 
      AND event_date BETWEEN '2025-01-01' AND '2025-08-31'
),
add_shipping_info AS (
    SELECT DISTINCT user_id 
    FROM mercadolibre_funnel 
    WHERE event_name = 'add_shipping_info' 
      AND event_date BETWEEN '2025-01-01' AND '2025-08-31'
),
add_payment_info AS (
    SELECT DISTINCT user_id 
    FROM mercadolibre_funnel 
    WHERE event_name = 'add_payment_info' 
      AND event_date BETWEEN '2025-01-01' AND '2025-08-31'
),
purchase AS (
    SELECT DISTINCT user_id 
    FROM mercadolibre_funnel 
    WHERE event_name = 'purchase' 
      AND event_date BETWEEN '2025-01-01' AND '2025-08-31'
)

-- The FROM must start with the first table defined above
SELECT 
    COUNT(fv.user_id) AS usuarios_first_visit,
    COUNT(si.user_id) AS usuarios_select_item,
    COUNT(ac.user_id) AS usuarios_add_to_cart,
    COUNT(bc.user_id) AS usuarios_begin_checkout,
    COUNT(ash.user_id) AS usuarios_add_shipping_info,
    COUNT(api.user_id) AS usuarios_add_payment_info,
    COUNT(p.user_id) AS usuarios_purchase
FROM first_visit fv
LEFT JOIN select_item si ON fv.user_id = si.user_id
LEFT JOIN add_to_cart ac ON si.user_id = ac.user_id
LEFT JOIN begin_checkout bc ON ac.user_id = bc.user_id
LEFT JOIN add_shipping_info ash ON bc.user_id = ash.user_id
LEFT JOIN add_payment_info api ON ash.user_id = api.user_id
LEFT JOIN purchase p ON api.user_id = p.user_id;
2.2 CALCULATE CONVERSIONS BETWEEN STAGES
Objective: Using the counts per funnel stage, calculate the conversion percentage from the initial stage (first_visit) to each subsequent stage.

SQL

WITH first_visit AS (
  SELECT DISTINCT user_id
  FROM mercadolibre_funnel
  WHERE event_name = 'first_visit'
    AND event_date BETWEEN '2025-01-01' AND '2025-08-31'
),
-- ... (Intermediate CTEs: select_item, add_to_cart, begin_checkout, add_shipping_info, add_payment_info, purchase)
funnel_counts AS (
  SELECT
    COUNT(fv.user_id) AS usuarios_first_visit,
    COUNT(si.user_id) AS usuarios_select_item,
    COUNT(a.user_id) AS usuarios_add_to_cart,
    COUNT(bc.user_id) AS usuarios_begin_checkout,
    COUNT(asi.user_id) AS usuarios_add_shipping_info,
    COUNT(api.user_id) AS usuarios_add_payment_info,
    COUNT(p.user_id) AS usuarios_purchase
  FROM first_visit fv
  LEFT JOIN select_item si         ON fv.user_id = si.user_id
  LEFT JOIN add_to_cart a          ON fv.user_id = a.user_id
  LEFT JOIN begin_checkout bc      ON fv.user_id = bc.user_id
  LEFT JOIN add_shipping_info asi ON fv.user_id = asi.user_id
  LEFT JOIN add_payment_info api  ON fv.user_id = api.user_id
  LEFT JOIN purchase p             ON fv.user_id = p.user_id
)

SELECT
    ROUND(usuarios_select_item * 100.0 / NULLIF(usuarios_first_visit, 0), 2) AS conversion_select_item,
    ROUND(usuarios_add_to_cart * 100.0 / NULLIF(usuarios_first_visit, 0), 2) AS conversion_add_to_cart,
    ROUND(usuarios_begin_checkout * 100.0 / NULLIF(usuarios_first_visit, 0), 2) AS conversion_begin_checkout,
    ROUND(usuarios_add_shipping_info * 100.0 / NULLIF(usuarios_first_visit, 0), 2) AS conversion_add_shipping_info,
    ROUND(usuarios_add_payment_info * 100.0 / NULLIF(usuarios_first_visit, 0), 2) AS conversion_add_payment_info,
    ROUND(usuarios_purchase * 100.0 / NULLIF(usuarios_first_visit, 0), 2) AS conversion_purchase
FROM funnel_counts;
2.3 SEGMENT THE FINAL FUNNEL BY COUNTRY
Objective: Group funnel conversions by country to detect at which stage the most users are lost.

SQL

WITH first_visits AS (
  SELECT DISTINCT user_id, country
  FROM mercadolibre_funnel
  WHERE event_name = 'first_visit'
    AND event_date BETWEEN '2025-01-01' AND '2025-08-31'
),
-- ... (Intermediate CTEs including country)
funnel_counts AS (
  SELECT
    fv.country,
    COUNT(DISTINCT fv.user_id) AS usuarios_first_visit,
    COUNT(DISTINCT si.user_id) AS usuarios_select_item,
    COUNT(DISTINCT a.user_id) AS usuarios_add_to_cart,
    COUNT(DISTINCT bc.user_id) AS usuarios_begin_checkout,
    COUNT(DISTINCT asi.user_id) AS usuarios_add_shipping_info,
    COUNT(DISTINCT api.user_id) AS usuarios_add_payment_info,
    COUNT(DISTINCT p.user_id) AS usuarios_purchase
  FROM first_visits fv
  LEFT JOIN select_item si         ON fv.user_id = si.user_id AND fv.country = si.country
  LEFT JOIN add_to_cart a          ON fv.user_id = a.user_id  AND fv.country = a.country
  LEFT JOIN begin_checkout bc      ON fv.user_id = bc.user_id AND fv.country = bc.country
  LEFT JOIN add_shipping_info asi ON fv.user_id = asi.user_id AND fv.country = asi.country
  LEFT JOIN add_payment_info api  ON fv.user_id = api.user_id AND fv.country = api.country
  LEFT JOIN purchase p             ON fv.user_id = p.user_id  AND fv.country = p.country
  GROUP BY fv.country
)

SELECT
    country,
    usuarios_select_item * 100.0 / NULLIF(usuarios_first_visit, 0) AS conversion_select_item,
    usuarios_add_to_cart * 100.0 / NULLIF(usuarios_first_visit, 0) AS conversion_add_to_cart,
    usuarios_begin_checkout * 100.0 /NULLIF(usuarios_first_visit, 0) AS conversion_begin_checkout,
    usuarios_add_shipping_info * 100.0 / NULLIF(usuarios_first_visit, 0) AS conversion_add_shipping_info,
    usuarios_add_payment_info * 100.0 / NULLIF(usuarios_first_visit, 0) AS conversion_add_payment_info,
    usuarios_purchase * 100.0 / NULLIF(usuarios_first_visit, 0) AS conversion_purchase
FROM funnel_counts
ORDER BY conversion_purchase DESC;
PART 3: ANALYZE RETENTION AND COHORTS
3.1 COUNT CUMULATIVE ACTIVE USERS BY COUNTRY (D7, D14, D21, D28)
Objective: For each country, count cumulative active users since their registration (range 2025-01-01 → 2025-08-31) at day 7, 14, 21, and 28.

SQL

SELECT 
    country,
    -- Count unique users active on or after day 7
    COUNT(DISTINCT CASE 
        WHEN active = 1 AND day_after_signup >= 7 THEN user_id 
    END) AS users_d7,
    
    -- Count unique users active on or after day 14
    COUNT(DISTINCT CASE 
        WHEN active = 1 AND day_after_signup >= 14 THEN user_id 
    END) AS users_d14,
    
    -- Count unique users active on or after day 21
    COUNT(DISTINCT CASE 
        WHEN active = 1 AND day_after_signup >= 21 THEN user_id 
    END) AS users_d21,
    
    -- Count unique users active on or after day 28
    COUNT(DISTINCT CASE 
        WHEN active = 1 AND day_after_signup >= 28 THEN user_id 
    END) AS users_d28
FROM 
    mercadolibre_retention
WHERE 
    activity_date BETWEEN '2025-01-01' AND '2025-08-31'
GROUP BY 
    country
ORDER BY 
    country ASC;
3.2 CONVERT COUNTS TO RETENTION % BY COUNTRY
Objective: Convert the counts from the previous task into retention percentages by country for D7, D14, D21, and D28.

SQL

SELECT 
    country,
    -- Retention D7 %
    ROUND(
        COUNT(DISTINCT CASE WHEN active = 1 AND day_after_signup >= 7 THEN user_id END) * 100.0 / 
        NULLIF(COUNT(DISTINCT user_id), 0), 1
    ) AS retention_d7_pct,
    
    -- Retention D14 %
    ROUND(
        COUNT(DISTINCT CASE WHEN active = 1 AND day_after_signup >= 14 THEN user_id END) * 100.0 / 
        NULLIF(COUNT(DISTINCT user_id), 0), 1
    ) AS retention_d14_pct,
    
    -- Retention D21 %
    ROUND(
        COUNT(DISTINCT CASE WHEN active = 1 AND day_after_signup >= 21 THEN user_id END) * 100.0 / 
        NULLIF(COUNT(DISTINCT user_id), 0), 1
    ) AS retention_d21_pct,
    
    -- Retention D28 %
    ROUND(
        COUNT(DISTINCT CASE WHEN active = 1 AND day_after_signup >= 28 THEN user_id END) * 100.0 / 
        NULLIF(COUNT(DISTINCT user_id), 0), 1
    ) AS retention_d28_pct
FROM 
    mercadolibre_retention
WHERE 
    activity_date BETWEEN '2025-01-01' AND '2025-08-31'
GROUP BY 
    country
ORDER BY 
    country ASC;
3.3 DEFINE THE REGISTRATION COHORT
Objective: Now we analyze retention by cohort. The first step is to create a SQL query that assigns a cohort in YYYY-MM format to each user based on their first registration date.

SQL

-- STRATEGY:
--   1) Group by user
--   2) Take the FIRST registration date per user: MIN(signup_date)
--   3) Truncate to month and format: TO_CHAR(DATE_TRUNC('month', MIN(signup_date::date)), 'YYYY-MM')
--   4) Group by user
--   5) Return 5 rows for validation

SELECT 
    user_id,
    MIN(signup_date) AS signup_date,
    TO_CHAR(DATE_TRUNC('month', MIN(signup_date)), 'YYYY-MM') AS cohort
FROM 
    mercadolibre_retention
GROUP BY 
    user_id
LIMIT 5;

