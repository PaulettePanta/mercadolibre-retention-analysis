Executive Summary: Funnel & Retention Analysis - MercadoLibre
📌 Project Overview
This project focuses on analyzing user behavior for MercadoLibre using MS SQL Server. The goal was to identify critical drop-off points in the conversion funnel and measure long-term user loyalty through cohort-based retention analysis between January and August 2025.

🔍 Key Analysis & Methodology
1. Conversion Funnel Optimization
Approach: Built a multi-stage funnel using CTEs to track users from their first_visit to the final purchase.

Metrics: Calculated conversion rates across 7 key stages: Item Selection, Cart Addition, Checkout, Shipping, Payment, and Final Transaction.

Segmentation: Segmented the funnel by Country to identify regional friction points in the user journey.

2. Retention & Cohort Analysis
Approach: Analyzed user activity post-signup at specific intervals (D7, D14, D21, and D28).

Strategy: Defined monthly Cohorts (YYYY-MM) to track how different groups of users maintain activity over time.

Calculations: Developed SQL queries to calculate retention percentages (retention_pct), allowing for a comparative analysis of user stickiness across different markets.

💡 Business Insights (Foundations for Decision Making)
Friction Identification: Detected the specific stages where the highest percentage of users drop off, providing a clear target for UX/UI improvements.

Regional Performance: Identified which countries have the most efficient conversion paths and which require localized logistics or payment solutions.

Loyalty Trends: Established a baseline for user retention, enabling the marketing team to evaluate the effectiveness of acquisition campaigns versus long-term engagement.

🛠️ Tech Stack
Language: SQL (PostgreSQL / MS SQL Server)

Key Techniques: Common Table Expressions (CTEs), Window Functions, Data Aggregation, Joins, and NULL handling for robust calculations.
