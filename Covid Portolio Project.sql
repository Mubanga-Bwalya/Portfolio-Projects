/*
Covid 19 Data Exploration 

Skills used: Joins, CTEs, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Select basic data for the United Arab Emirates
SELECT Location, date, total_cases, new_cases, total_deaths, population 
FROM covid_deaths
WHERE continent IS NOT NULL AND location ILIKE '%emirates%'
ORDER BY 1,2;

-- Calculate the death percentage in the UAE due to Covid-19
-- Shows the likelihood of dying if you contract covid in the United Arab Emirates
SELECT Location, date, total_cases, total_deaths, (total_deaths::FLOAT/total_cases)*100 AS DeathPercentage
FROM covid_deaths
WHERE location ILIKE '%emirates%'
AND continent IS NOT NULL 
ORDER BY 1,2;

-- Determine what percentage of the UAE's population has been infected with Covid
SELECT Location, date, Population, total_cases,  (total_cases::FLOAT/population)*100 AS PercentPopulationInfected
FROM covid_deaths
WHERE location ILIKE '%emirates%'
ORDER BY 1,2;

-- Identify the highest infection rate in the UAE compared to its population
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases::FLOAT/population))*100 AS PercentPopulationInfected
FROM covid_deaths
WHERE location ILIKE '%emirates%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

-- Find the highest death count per population in the UAE
SELECT Location, MAX(Total_deaths::INT) AS TotalDeathCount
FROM covid_deaths
WHERE continent IS NOT NULL AND location ILIKE '%emirates%'
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- Showing continents with the highest death count per population
SELECT continent, MAX(Total_deaths::INT) AS TotalDeathCount
FROM covid_deaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Global numbers for new cases, new deaths, and death percentage
SELECT 
    SUM(new_cases) AS "Total New Cases", 
    SUM(new_deaths::INT) AS "Total New Deaths", 
    (SUM(new_deaths::INT)::FLOAT / SUM(new_cases)) * 100 AS "Death Percentage of New Cases"
FROM 
    covid_deaths
WHERE 
    continent IS NOT NULL;


-- Calculate the percentage of the UAE population that has received at least one Covid vaccine
--Percentage exceeds 100 due to the fact that the rollingpeoplevaccinated field is a cumulative calculation and the data set from from https://ourworldindata.org/covid-deaths does not account for the possible intra annual population increase of population
WITH PopvsVac AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INTEGER)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
    FROM covid_deaths dea
    JOIN covid_vaccinations vac ON dea.location = vac.location AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL AND dea.location ILIKE '%emirates%'
)
SELECT *, (RollingPeopleVaccinated::FLOAT/Population)*100 AS VaccinationPercentage
FROM PopvsVac;

-- Create or replace a view focused on the vaccination percentage for the UAE
-- This view is specifically tailored for later visualization of vaccination data in the UAE
CREATE OR REPLACE VIEW PercentPopulationVaccinated_UAE AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INTEGER)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.location ILIKE '%emirates%';
