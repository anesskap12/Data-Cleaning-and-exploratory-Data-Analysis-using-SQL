
select*
from layoffs;

create table layoffs_staging
like layoffslayoffs_staging;


with duplicate_cte as
(
select *,row_number() over(partition by company,location,stage,country,funds_raised_millions,industry,total_laid_off,percentage_laid_off,'date')
as row_num
from layoffs_staging
)
select *
from duplicate_cte
where row_num>1;

select *
from layoffs_staging
where company="casper";

delete
from duplicate_cte
where row_num>1;

-- creating a third table in order to delete all the duplicate rows
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


select *
from layoffs_staging2
where row_num>1;

insert into
layoffs_staging2
select *,
row_number() over(
partition by company, location,industry,total_laid_off,percentage_laid_off,stage,country,funds_raised_millions,`date`)
as row_num
from layoffs_staging;


delete
from layoffs_staging2
where row_num>1;

select *
from layoffs_staging2;

-- Standardizing data
select
company,trim(company)
from layoffs_staging2;

update layoffs_staging2
set company=trim(company);

-- changing industries names that represent the same industry
select
distinct(industry)
from layoffs_staging2
order by 1;

select
*
from layoffs_staging2
where industry like "Crypto%" ;

update layoffs_staging2
set industry="Crypto"
where industry like "Crypto%";

select
distinct(country)
from layoffs_staging2
order by 1;

update layoffs_staging2
set country="United States"
where country like "United States%";

/* This is a specefic case where i know the country that has it's name written
differently in different rows so i used the upper command to fix the issue, in case 
this was more generalised and i had more than one country with this problem, i would have used 
trim(trailing '.' from country instead*/


select `date`,
str_to_date(`date`,'%m/%d/%Y')
from layoffs_staging2;

update layoffs_staging2
set `date`=str_to_date(`date`,'%m/%d/%Y');

alter table layoffs_staging2
modify column `date` date;

select *
from layoffs_staging
where total_laid_off is null
and percentage_laid_off is null;


select *
from layoffs_staging2
where industry is null
or industry="";

-- so there is some companies with blank industry column, which means because its not by nature null, we can populate it

update
layoffs_staging2
set industry=null
where industry='';



select *
from layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company=t2.company
where (t1.industry is null or t1.industry='')
and t2.industry is not null;

update layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company=t2.company
set t1.industry=t2.industry   
where (t1.industry is null or t1.industry='')
and t2.industry is not null; 

delete
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;


alter table
layoffs_staging2
drop column row_num;

select *
from layoffs_staging2;

select
max(percentage_laid_off),
max(total_laid_off)
from layoffs_staging2;

select *
from layoffs_staging2
where percentage_laid_off=1
order by total_laid_off desc;

select company,sum(total_laid_off)
from layoffs_staging2
group by(company)
order by 2 desc;

select industry,sum(total_laid_off)
from layoffs_staging2
group by(industry)
order by 2 desc;

select country,sum(total_laid_off)
from layoffs_staging2
group by(country)
order by 2 desc;

select YEAR(`date`),sum(total_laid_off)
from layoffs_staging2
group by YEAR(`date`)
order by 2 desc;

-- selecting substrings from the date column

select substring(`date`,1,7) as Months,sum(total_laid_off)
from layoffs_staging2
where substring(`date`,1,7) is not null
group by Months
order by 1;


-- computing the rolling total

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


select company,year(`date`) as Monthly,sum(total_laid_off) as total_off
from layoffs_staging2
group by company,year(`date`)
order by 1 desc;

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




