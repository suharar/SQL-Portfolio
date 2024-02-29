# SQL-Project #1 - COVID-19 Data Analysis
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Microsoft Excel](https://img.shields.io/badge/Microsoft_Excel-217346?style=for-the-badge&logo=microsoft-excel&logoColor=white)
![GitHub](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)

![covid19](https://github.com/suharar/SQL-Portfolio/assets/74327995/1f527259-83c7-4222-ac4d-431c6f430dd4)

<br>

## 1. Quickly check the tables to be used
````sql
select *
from covid_deaths
limit 10;
````
![image](https://github.com/suharar/SQL-Portfolio/assets/74327995/c19b6612-7a56-4c99-a54b-f0bcb5154c66)

````sql
select *
from covid_vaccinations
limit 10;
````
![image](https://github.com/suharar/SQL-Portfolio/assets/74327995/23af65fb-1163-475c-afad-e9421c2a918c)

<br>

## 2. Looking at total cases vs total death by year/month in Japan

````sql
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
order by 1,2,3;
````
Observations:
- death rates peaked on 2020 May at 5.29%
- slow but continuous decline in death rates since its peaked.
- stable around 0.2% after 2022 August to today

<br>

## 3. Looking at total cases vs population by year/month in Japan

````sql
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
order by 1,2,3;
````

Observations:
- today, >27% of people in Japan infected COVID at least once
- faster growth in infection percentage since 2022 Febuary
- infected percentage stablized after 2023 January

<br>

## 4. Finding top 5 countries which have the highest infection rate(total_cases/population) overall

````sql
select 
	location 
	, max(total_cases) as cumulative_cases
	, max(population) as population
	, ROUND(CAST(max(total_cases) AS DECIMAL) / NULLIF(CAST(max(population) AS DECIMAL), 0) * 100, 2) AS infected_percentage
from covid_deaths
group by location
having ROUND(CAST(max(total_cases) AS DECIMAL) / NULLIF(CAST(max(population) AS DECIMAL), 0) * 100, 2) is not NULL
order by 4 DESC;
````

Observation:
1. Brunei	      76.3%
2. Cyprus	      76.02%
3. San Marino	  75.07%
4. Austria	      68.03%
5. South Korea	  66.72%

<br>

##  5. Finding countries which have the highest infection rate(total_cases/population) for each recorded year

````sql
select 
	location 
	, max(total_cases) as cumulative_cases
	, max(population) as population
	, ROUND(CAST(max(total_cases) AS DECIMAL) / NULLIF(CAST(max(population) AS DECIMAL), 0) * 100, 2) AS infected_percentage
from covid_deaths
group by location
having ROUND(CAST(max(total_cases) AS DECIMAL) / NULLIF(CAST(max(population) AS DECIMAL), 0) * 100, 2) is not NULL
order by 4 DESC;
````

Observation:
Countires with the highest infected rate per year are as follows:
- 2020: Andorra (9.78%)
- 2021: Andorra (27.22%)
- 2022: Cyprus  (70.15%)
- 2023: Cyprus  (75.35%)
- 2024: Brunei  (76.35%)

<br>

## 6. Finding top 5 countries which have the highest deaths rate(total_deaths/population) overall
````sql
select 
	location 
	, max(total_deaths) as cumulative_deaths
	, max(population) as population
	, ROUND(CAST(max(total_deaths) AS DECIMAL) / NULLIF(CAST(max(population) AS DECIMAL), 0) * 100, 2) AS deaths_percentage
from covid_deaths
group by location
having ROUND(CAST(max(total_deaths) AS DECIMAL) / NULLIF(CAST(max(population) AS DECIMAL), 0) * 100, 2) is not NULL
order by 4 DESC;
````

Obsearvation:
1. Peru	                       0.65%
2. Bulgaria                    0.57%
3. Bosnia and Herzegovina	     0.51%
4. Hungary	                   0.49%
5. North Macedonia	           0.48%

<br>

## 7. Finding Population, # Infected, # Death, Infected/Population %, Death/Population %, Infected/Death by Continent

````sql
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
order by 2 DESC;
````

Observation:
- approx. 10% of the people in the world got infected to COVID at least once.
- COVID killed 7 millions people (0.09% of ttl population) on the earth
- Europe has the highest infection/population rate with 33.84%
- Africa has the lowest infection/population rate with 0.92%
- However, when comparing the deaths/infection rate between Europe and Africa,
  Africa has much higher rate (1.97%) against Europe (0.83%)

<br>

## 8. Look at daily rolling_infection, rolling_death, and rolling_vaccinations per location
- 8.1 covid_vaccinations table is joined as covid_deaths table does not contain necessary data
- 8.2 use CTE to avoid duplicate entry per date

````sql
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
order by 1,2,3;
````

<br>

## 9. Generate view based on 8. for visualization

````sql
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
````

````sql
-- checking the view created
select *
from visualization1
limit 10;
````

![image](https://github.com/suharar/SQL-Portfolio/assets/74327995/2a848fde-0c34-44b9-9e07-36b318851bee)

<br>
