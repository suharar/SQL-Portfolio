TRUNCATE TABLE covid_deaths;
COPY covid_deaths
FROM 'C:\Users\Ryo\Desktop\Data_Analysis\SQL\SQL-Portfolio\CovidDeaths.csv'
DELIMITER ','
CSV HEADER;

