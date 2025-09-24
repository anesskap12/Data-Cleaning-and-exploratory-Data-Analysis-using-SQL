# Data-Cleaning-and-exploratory-Data-Analysis-using-SQL
Data cleaning and preparation, and exploratory data analysis of the layoffs Dataset
### project Overview

This project focuses on data cleaning, standardization, and analysis of a layoffs dataset using MySQL.
The goal is to transform raw data into a reliable and structured format for meaningful analysis, and then extract insights about global layoffs across companies, industries, and countries.

### Dataset

Source: Layoffs dataset which you can [Download here](https://www.kaggle.com/datasets/theakhilb/layoffs-data-2022).

Content: Information about companies that experienced layoffs, including:

Company name

Location

Industry

Stage (startup, post-IPO, etc.)

Total laid off

Percentage laid off

Funds raised (in millions)

Country

Date of layoff

### Process

The project is divided into two major parts:

1. Data Cleaning

- Removing duplicates
 ```sql
WITH duplicate_cte AS (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY company, location, industry, stage, country, funds_raised_millions, `date`
         ) AS row_num
  FROM layoffs_staging
)
DELETE
FROM duplicate_cte
WHERE row_num > 1;
```
-Standardizing company names
```
UPDATE layoffs_staging2
SET company = TRIM(company);
```
-Standardizing industry names
```sql
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
```
-Fixing inconsistent country names
```sql
UPDATE layoffs_staging2
SET country = 'United States'
WHERE country LIKE 'United States%';
```
-Converting date column to the proper format
```sql
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;
```
2. Data Analysis
-Companies with most layoffs
```sql
SELECT company, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
GROUP BY company
ORDER BY total_off DESC;
```
-Rolling total of layoffs over time
```sql
with rolling_total as
(
select substring(`date`,1,7) as `Months`,sum(total_laid_off) as total_off
from layoffs_staging2
where substring(`date`,1,7) is not null
group by `Months`
order by 1
)
select `Months`,total_off,sum(total_off) over(order by `Months`) as cumulative_sum
from rolling_total;
```
-Top 5 companies each year by layoffs
```sql
with companies_rolling(company,years,total_off)
as
(
select company,year(`date`),sum(total_laid_off)
from layoffs_staging2
group by company,year(`date`)
order by 1 desc
),company_year_rank as
(
select *,
dense_rank() over(partition by years order by total_off desc) as Ranking
from companies_rolling
where years is not null
)
select *
from company_year_rank
where ranking <=5;
```
### Tools 
SQL(MySQL)

