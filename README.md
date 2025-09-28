# Covid_Survival_Analysis_CodeBasic
Data-driven analysis to help a legacy newspaper, Bharat Herald, transition from print to digital in a post-COVID era. This project includes SQL-based data cleaning, business insights, and strategic recommendations to boost digital engagement, regain advertiser trust, and optimize revenue models.


📰 Newspaper Survival in a Post-COVID Digital Era

Project Type: Business Analytics & Digital Transformation Strategy
Challenge By: Code Basics
Author: Farhan Hussain

📌 Overview

The Bharat Herald, a legacy newspaper company operating across five Indian states, is facing an existential crisis due to the post-COVID digital shift.

From 2019 to 2024, the print circulation plummeted by 53%, dropping from 1.2M copies to 560K copies.
The pandemic accelerated digital news consumption, with competitors like DigiHindi Post, NewsZilla, and InShorts dominating the mobile-first ecosystem.

This project provides data-driven insights and a strategic roadmap to help Bharat Herald transition to a digital-first model while maintaining its legacy print audience.

🎯 Problem Statement

“How can Bharat Herald recover from declining print circulation and revenue while successfully transitioning to a sustainable digital future?”

Key Challenges:

Rapid digital adoption by competitors.

Failed e-paper pilot due to poor mobile usability (2021).

Declining advertiser confidence and unpaid vendor dues.

Closure of multiple city bureaus and 60+ employee layoffs.

Financial distress flagged by a recent internal audit.

🗂 Dataset Information

All datasets were loaded into MySQL for analysis.

Dataset Name	Description
dim_ad_category.csv	Metadata about advertisement categories.
dim_city.csv	City-level demographic and geographic details.
fact_ad_revenue.csv	Advertisement revenue by city and category.
fact_city_readiness.csv	City-level internet, smartphone, literacy data.
fact_digital_pilot.csv	Engagement metrics for digital pilot program.
fact_print_sales.csv	Print sales and circulation data.
🔧 Data Cleaning & Preprocessing

Performed extensive data cleaning to ensure consistency and accuracy.

1. dim_ad_category

Trimmed whitespace using TRIM().

Renamed ambiguous columns for clarity.

2. fact_city_readiness

Removed unnecessary auto-generated index columns.

Standardized quarter format to YYYY-QN.

3. fact_digital_pilot

Converted launch_month to proper DATE format.

Renamed long column names (e.g., customer_feedback).

4. fact_print_sales

Standardized capitalization for Language and State.

Converted copies_sold to INT and Month to DATE.

Removed unwanted underscores in State names.

📊 Key Business Analysis
1. Top 3 Monthly Print Circulation Drops (2019–2024)

Identified sharpest month-over-month declines using LAG() and CTE.

Provides actionable periods for intervention campaigns.

2. Ad Revenue Concentration

No single ad category contributed >50% revenue.

Indicates diversified ad revenue base.

3. 2024 Print Efficiency Leaderboard

Calculated efficiency as:

efficiency = net_circulation / copies_printed


Top 5 most efficient cities identified for operational optimization.

4. Internet Readiness Growth (2021)

Measured improvement in internet penetration by city between Q1 and Q4.

City with highest growth identified for digital-first rollout.

5. Consistent Multi-Year Decline (2019–2024)

Strict check for cities with yearly declines in both circulation and ad revenue.

No city met the stringent criteria, indicating mixed performance trends.

6. Digital Readiness vs. Pilot Engagement Outlier

Found cities with high digital readiness but low engagement in digital pilots.

These cities are prime targets for digital marketing campaigns.

🧩 Strategic Recommendations
1. Phased Digital Transition Strategy

Cities segmented into three tiers:

Segment	Examples	Strategy
High-Potential Growth Markets	Jaipur, Bhopal, Patna	Full-scale digital relaunch targeting untapped audience.
Optimization & Monetization Markets	Delhi, Mumbai, Ahmedabad	Deepen engagement, introduce premium features, optimize monetization.
Foundational Markets	Ranchi	Build digital literacy, release free mobile-friendly content gradually.
2. Regaining Advertiser Trust

Target declining cities & categories with tailored recovery plans.

Highlight digital audience analytics to showcase ROI.

Launch hybrid ad packages combining print + digital.

3. Content & Delivery Innovations

Mobile-first articles: Quick, scannable, media-rich.

Community-driven features: Polls, Q&A, WhatsApp updates.

Personalized local news via geo-targeting.

4. Monetization Models

Print + Digital subscription bundles.

Loyalty rewards for active engagement.

Pay-per-article to attract low-commitment users.

5. Influencer & Journalist Partnerships

Build local contributor network to boost credibility.

Host digital community events like webinars and live Q&A.

Showcase regional success stories.

📈 Key Insights

Print circulation dropped by 53% between 2019–2024.

Cities like Jaipur, Bhopal, Patna have high readiness but low engagement, representing untapped opportunities.

Diversified ad revenue base – no single category dominates.

Need to bridge readiness and engagement gaps with targeted strategies.

🛠 Tech Stack

Database: MySQL

Data Cleaning: SQL Queries

Visualization: Power BI / Tableau (if integrated)

Documentation: Markdown, PDF

🚀 How to Run

Import provided CSV files into MySQL.

Run preprocessing SQL scripts (cleaning.sql).

Execute analysis queries step-by-step in the provided query notebook.

Visualize results in a BI tool of your choice.

📌 Final Outcome

The project delivers:

A comprehensive data-driven strategy for Bharat Herald’s survival.

Prioritized city-level recommendations for phased digital rollout.

Actionable insights for revenue recovery and audience engagement.

📜 License

This project is for educational purposes as part of the Code Basics Challenge.
All datasets and analysis are simulated for demonstration.
