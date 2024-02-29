-- 1. Quickly check all the tables
select *
from covid_deaths
limit 10;

select *
from covid_vaccinations
limit 10;


-- 2. Looking at total cases vs total death by year/month in Japan
select 
	location 
	, EXTRACT(YEAR FROM date) AS year
	, EXTRACT(MONTH FROM date) AS month
	, max(total_cases) AS cumulative_cases
	, max(total_deaths) AS cumulative_deaths
	, ROUND(CAST(max(total_deaths) AS DECIMAL) / NULLIF(CAST(max(total_cases) AS DECIMAL), 0) * 100, 2) AS death_percentage
from covid_deaths
where location = 'Japan'
group by location, EXTRACT(YEAR FROM date), EXTRACT(MONTH FROM date)
order by 1,2,3


-- 3. Looking at total cases vs population by year/month in Japan
select 
	location 
	, EXTRACT(YEAR FROM date) as year
	, EXTRACT(MONTH FROM date) as month
	, max(total_cases) as cumulative_cases
	, max(population) as population
	, ROUND(CAST(max(total_cases) AS DECIMAL) / NULLIF(CAST(max(population) AS DECIMAL), 0) * 100, 2) AS infected_percentage
from covid_deaths
where location = 'Japan'
group by location, EXTRACT(YEAR FROM date), EXTRACT(MONTH FROM date)
order by 1,2,3


-- 4. Finding top 5 countries which have the highest infection rate(total_cases/population) overall
select 
	location 
	, max(total_cases) as cumulative_cases
	, max(population) as population
	, ROUND(CAST(max(total_cases) AS DECIMAL) / NULLIF(CAST(max(population) AS DECIMAL), 0) * 100, 2) AS infected_percentage
from covid_deaths
group by location
having ROUND(CAST(max(total_cases) AS DECIMAL) / NULLIF(CAST(max(population) AS DECIMAL), 0) * 100, 2) is not NULL
order by 4 DESC


-- 5. Finding countries which have the highest infection rate(total_cases/population) for each recorded year
WITH rankedLoc AS (
	select 
		location 
		, EXTRACT(YEAR FROM date) as year
		, max(total_cases) as cumulative_cases
		, max(population) as population
		, ROUND(CAST(max(total_cases) AS DECIMAL) / NULLIF(CAST(max(population) AS DECIMAL), 0) * 100, 2) AS infected_percentage
		,RANK() OVER(PARTITION BY EXTRACT(YEAR FROM date) ORDER BY ROUND(CAST(MAX(total_cases) AS DECIMAL) / NULLIF(CAST(MAX(population) AS DECIMAL), 0) * 100, 2) DESC) as rank
	from covid_deaths
	group by 
		location 
		, EXTRACT(YEAR FROM date)
	having ROUND(CAST(max(total_cases) AS DECIMAL) / NULLIF(CAST(MAX(population) AS DECIMAL), 0)* 100, 2) IS NOT NULL
)

select 
	year
	,  location
	, cumulative_cases
	, population
	, infected_percentage
from rankedLoc
where rank = 1
order by 1


-- 6. Finding top 5 countries which have the highest deaths rate(total_deaths/population) overall
select 
	location 
	, max(total_deaths) as cumulative_deaths
	, max(population) as population
	, ROUND(CAST(max(total_deaths) AS DECIMAL) / NULLIF(CAST(max(population) AS DECIMAL), 0) * 100, 2) AS deaths_percentage
from covid_deaths
group by location
having ROUND(CAST(max(total_deaths) AS DECIMAL) / NULLIF(CAST(max(population) AS DECIMAL), 0) * 100, 2) is not NULL
order by 4 DESC


-- 7. Finding Population, # Infected, # Death, Infected/Population %, Death/Population %, Infected/Death by Continent
select 
	location 
	, max(population) as population
	, max(total_cases) as cumulative_cases
	, max(total_deaths) as cumulative_deaths
	, ROUND(CAST(max(total_cases) AS DECIMAL) / NULLIF(CAST(max(population) AS DECIMAL), 0) * 100, 2) AS infection_per_population
	, ROUND(CAST(max(total_deaths) AS DECIMAL) / NULLIF(CAST(max(population) AS DECIMAL), 0) * 100, 2) AS deaths_per_population
	, ROUND(CAST(max(total_deaths) AS DECIMAL) / NULLIF(CAST(max(total_cases) AS DECIMAL), 0) * 100, 2) AS death_rate_per_infection
from covid_deaths
where continent is null -- in this dataset, when location = continent data, continent is null
and location not in ('Low income', 'Lower middle income', 'Upper middle income', 'High income', 'European Union')
group by location
order by 2 DESC


-- 8. Look at daily rolling_infection, rolling_death, and rolling_vaccinations per location
--    .1 covid_vaccinations table is joined as covid_deaths table does not contain necessary data
--    .2 use CTE to avoid duplicate entry per date
WITH tmp as (
select distinct * 
from covid_vaccinations v 
inner join covid_deaths d using (iso_code, continent, location, date, population) 
order by 1,2,3,4
)
select
	continent
	, location
	, date
	, population
	, new_cases
	, new_deaths
	, new_vaccinations
	, sum(cast(new_cases as int)) OVER (PARTITION BY location Order by date) as rolling_infections
	, sum(cast(new_deaths as int)) OVER (PARTITION BY location Order by date) as rolling_deaths
	, sum(cast(new_vaccinations as int)) OVER (PARTITION BY location Order by date) as rolling_vaccinations
from tmp
where continent is not null
order by 1,2,3


-- 9. Generate view based on 8. for visualization
Create view visualization1 as
WITH tmp as (
select distinct * 
from covid_vaccinations v 
inner join covid_deaths d using (iso_code, continent, location, date, population) 
order by 1,2,3,4
)
select
	continent
	, location
	, date
	, population
	, new_cases
	, new_deaths
	, new_vaccinations
	, sum(cast(new_cases as int)) OVER (PARTITION BY location Order by date) as rolling_infections
	, sum(cast(new_deaths as int)) OVER (PARTITION BY location Order by date) as rolling_deaths
	, sum(cast(new_vaccinations as int)) OVER (PARTITION BY location Order by date) as rolling_vaccinations
from tmp
where continent is not null
order by 1,2,3


-- checking the view created
select *
from visualization1
where extract(year from date) = 2022
and location = 'Japan'
limit 10;
