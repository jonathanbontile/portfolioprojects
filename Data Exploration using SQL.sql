/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT *
FROM [Portfolio Project]..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 2,3


--Select the columns we are going to start with
SELECT 
    location,
    date,
    total_cases,
    total_deaths
FROM [Portfolio Project]..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 2,3


--Total Cases vs Total Deaths
--Shows the likelihood of dying if you got infected(% of daily deaths per daily cases) in your country

SELECT 
    location,
    date,
    total_cases,
    total_deaths,
    (total_deaths/total_cases)*100 AS DeathPercentage

FROM [Portfolio Project]..CovidDeaths$
WHERE continent is not NULL
ORDER BY 1,2

-- Total Cases vs Population
--Shows % of population who got COVID
SELECT 
    location,
    date,
    population,
    total_cases,
    (total_cases/population)*100 AS PctPopulation

FROM [Portfolio Project]..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1,2

--Infection rate per Country
--Percentage of Total cases per Population
SELECT 
    location,
    population,
    MAX(total_cases) AS HighestInfectionCount,
    (MAX(total_cases)/MAX(population))*100 AS PctPopulation
FROM [Portfolio Project].[dbo].[CovidDeaths$]
WHERE continent IS NOT NULL
GROUP BY  location, population
ORDER BY PctPopulation DESC

--Total Deaths per Country

SELECT 
    location,
    MAX(CAST(total_deaths as int)) AS TotalDeathCount
FROM [Portfolio Project]..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--Summary per Continent
--Total number of deaths per continent

SELECT 
    location,
    MAX(CAST(total_deaths as int)) AS TotalDeathCount
FROM [Portfolio Project]..CovidDeaths$
WHERE continent IS NULL AND 
    location NOT LIKE '%income' AND
    location NOT IN ('World', 'European Union','International')
    GROUP BY location
ORDER BY TotalDeathCount DESC


--Worldwide Numbers
--Total cases and deaths around the world
SELECT
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths as bigint)) AS total_deaths,
     SUM(CAST(new_deaths as bigint)) / SUM(new_cases)*100 AS DeathPercentage

FROM [Portfolio Project].[dbo].CovidDeaths$
WHERE continent IS NOT NULL 
ORDER BY 1, 2 


--Percentage of Fully Vaccinated People per Country
SELECT
    dea.location,
    MAX(dea.population) AS population,
    MAX(CONVERT(bigint,vax.people_fully_vaccinated)) AS fully_vaccinated,
    MAX((CONVERT(bigint,vax.people_fully_vaccinated))/dea.population)*100 AS PctOfFullyVaccinated

FROM [Portfolio Project]..CovidDeaths$ AS dea
    JOIN [Portfolio Project]..CovidVaccinations$ AS vax
    ON dea.[location] = vax.[location]
    AND dea.[date] = vax.[date]
WHERE dea.continent IS NOT NULL
GROUP BY dea.location
ORDER BY 4 DESC

--Sum of daly new vaccinations 

SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vax.new_vaccinations,
    SUM(CONVERT(bigint,vax.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM [Portfolio Project]..CovidDeaths$ AS dea
    JOIN [Portfolio Project]..CovidVaccinations$ AS vax
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent IS NOT NULL 
    --AND dea.continent = 'Asia'
ORDER BY 1,2,3

--Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVax (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated )
AS
(
SELECT
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vax.new_vaccinations,
    SUM(CONVERT(bigint,vax.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM [Portfolio Project]..CovidDeaths$ AS dea
    JOIN [Portfolio Project]..CovidVaccinations$ AS vax
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent IS NOT NULL
)

SELECT *, (RollingPeopleVaccinated/population)*100 AS PctofFullyVaccinated
FROM PopvsVax

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    continent nvarchar(255),
    location nvarchar(255),
    date DATETIME,
    population numeric,
    new_vaccination numeric,
    RollingPeopleVacccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
     SELECT
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vax.new_vaccinations,
    SUM(CONVERT(bigint,vax.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
    FROM [Portfolio Project]..CovidDeaths$ AS dea
    JOIN [Portfolio Project]..CovidVaccinations$ AS vax
	ON dea.location = vax.location
	AND dea.date = vax.date

SELECT *
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

CREATE VIEW PctofPopulationVaccinated
AS

SELECT
    dea.location,
    MAX(dea.population) AS population,
    MAX(CONVERT(bigint,vax.people_fully_vaccinated)) AS fully_vaccinated,
    MAX((CONVERT(bigint,vax.people_fully_vaccinated))/dea.population)*100 AS PctOfFullyVaccinated

FROM [Portfolio Project]..CovidDeaths$ AS dea
    JOIN [Portfolio Project]..CovidVaccinations$ AS vax
    ON dea.[location] = vax.[location]
    AND dea.[date] = vax.[date]
WHERE dea.continent IS NOT NULL
GROUP BY dea.location