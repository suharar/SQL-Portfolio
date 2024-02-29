ALTER TABLE covid_deaths
ALTER COLUMN total_tests TYPE numeric USING total_tests::numeric;

ALTER TABLE covid_deaths
RENAME COLUMN population_density TO population;

ALTER TABLE covid_deaths
ALTER COLUMN population TYPE numeric USING population::numeric;