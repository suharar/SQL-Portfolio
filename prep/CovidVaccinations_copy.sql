TRUNCATE TABLE covid_vaccinations;
COPY covid_vaccinations
FROM 'C:\Users\Ryo\Desktop\Data_Analysis\SQL\SQL-Portfolio\CovidVaccinations.csv'
DELIMITER ','
CSV HEADER;