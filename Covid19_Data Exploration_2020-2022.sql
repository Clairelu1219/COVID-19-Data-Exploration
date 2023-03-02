/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Checking data in these two tables
SELECT  *
FROM Covid19.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date
LIMIT 50

SELECT  *
FROM Covid19.CovidVaccinations
WHERE continent IS NOT NULL
ORDER BY location, date
LIMIT 50


-- Select the data we are going to use
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Covid19.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date


-- Totla Cases vs Total Deaths
-- Use wildcard to check likehood of dying if you contract covid in your country
SELECT 
  location, 
  date, 
  total_cases, 
  total_deaths,
  ROUND((total_deaths/total_cases) * 100,2) AS death_percentage
FROM Covid19.CovidDeaths
WHERE location LIKE '%States%'
  AND continent IS NOT NULL
ORDER BY location, date


-- Cases vs Population
-- Shows what percentage of population infected with Covid
SELECT 
  location, 
  date,  
  population,
  total_cases,
  (total_cases/population) * 100 AS infection_rate
FROM Covid19.CovidDeaths
-- WHERE location LIKE '%States%'
--   AND continent IS NOT NULL
ORDER BY location, date


-- Countries with Highest Infection Rate compared to Population
SELECT 
  location, 
  population,
  MAX(total_cases) AS max_infection_count,
  MAX((total_cases/population) * 100) AS max_infection_rate
FROM Covid19.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY max_infection_rate DESC


-- Showing Countries with Highest Death Count per Pupulation
SELECT 
  location,
  MAX(total_deaths) AS max_deaths_count
FROM Covid19.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY max_deaths_count DESC


-- Showing Continents with Highest Death Count per Pupulation
SELECT 
  continent,
  MAX(total_deaths) AS max_total_deaths
FROM Covid19.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY max_total_deaths DESC


-- Global Numbers: total cases, total deaths and death rate per day
SELECT
  date,
  SUM(new_cases) AS totl_cases,
  SUM(new_deaths) AS total_deaths,
  SUM(new_deaths)/SUM(new_cases)*100 AS death_rate
FROM Covid19.CovidDeaths
WHERE new_cases > 0 AND continent IS NOT NULL
GROUP BY date
ORDER BY date


-- Global Numbers: 2020 - 2022 total cases, total deaths and death rate
SELECT
  SUM(new_cases) AS totl_cases,
  SUM(new_deaths) AS total_deaths,
  SUM(new_deaths)/SUM(new_cases)*100 AS death_rate
FROM Covid19.CovidDeaths
WHERE new_cases > 0 AND continent IS NOT NULL


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT 
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations,
  SUM(CAST(vac.new_vaccinations AS INT64))
      OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date)
      AS rolling_people_vaccinated,
FROM Covid19.CovidDeaths AS dea
JOIN Covid19.CovidVaccinations AS vac
  ON dea.iso_code = vac.iso_code
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date


-- Use CTE to perform Calculation on Partition By in previous query
WITH PopulationvsVaccination AS (
  SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INT64))
      OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date)
      AS rolling_people_vaccinated,
  FROM Covid19.CovidDeaths AS dea
  JOIN Covid19.CovidVaccinations AS vac
    ON dea.iso_code = vac.iso_code
    AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL
  ORDER BY dea.location, dea.date
)

SELECT *, (rolling_people_vaccinated/population)*100 AS rolling_vaccination_rate
FROM PopulationvsVaccination


-- Using Temp Table to perform Calculation on Partition By in previous query
CREATE OR REPLACE TEMP TABLE PercentPopulationvsVaccinated AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INT64))
      OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date)
      AS rolling_people_vaccinated
  FROM Covid19.CovidDeaths AS dea
  JOIN Covid19.CovidVaccinations AS vac
    ON dea.iso_code = vac.iso_code
    AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL
  ORDER BY dea.location, dea.date

SELECT *, (rolling_people_vaccinated/Population)*100
FROM PercentPopulationvsVaccinated




-- Creating View to store data for later visualizations

CREATE VIEW Covid19.PercentPopulationVaccinatedView AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INT64))
      OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date)
      AS rolling_people_vaccinated
  FROM Covid19.CovidDeaths AS dea
  JOIN Covid19.CovidVaccinations AS vac
    ON dea.iso_code = vac.iso_code
    AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL
  ORDER BY dea.location, dea.date
