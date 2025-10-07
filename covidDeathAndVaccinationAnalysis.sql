/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

--Changing data type

ALTER TABLE portfolioProject..CovidDeaths
ALTER COLUMN total_cases BIGINT

ALTER TABLE portfolioProject..CovidDeaths
ALTER COLUMN total_deaths BIGINT

ALTER TABLE portfolioProject..CovidDeaths
ALTER COLUMN date DATE;

ALTER TABLE portfolioProject..CovidVaccinations
ALTER COLUMN new_vaccinations BIGINT

--Looking at Total Cases vs Total Deaths
--Shows the likelihood of dying if you get covid in a certrain country

SELECT location, date, total_cases, total_deaths, CAST(total_deaths as FLOAT) / NULLIF(total_cases, 0)*100 AS deathPercentage
FROM portfolioProject..CovidDeaths
where continent is not null
and location like '%Bangladesh%'
ORDER BY 1, 2

--Looking at Total Cases vs Population
--Shows what percentage of population got covid
SELECT location, date, population, total_cases, CAST(total_cases as FLOAT) / NULLIF(population, 0)*100 AS InfectedPopulationPercentage
FROM portfolioProject..CovidDeaths
where continent is not null
and location like '%states%'
ORDER BY 1, 2

--Looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(CAST(total_cases as FLOAT) / NULLIF(population, 0))*100 AS MaxInfectedPopulationPercentage
FROM portfolioProject..CovidDeaths
where continent is not null
GROUP BY location, population
ORDER BY MaxInfectedPopulationPercentage DESC

--Showing the countries with the highest death count per population
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM portfolioProject..CovidDeaths
where continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

--Showing the continents with the highest death count per population
SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM portfolioProject..CovidDeaths
where continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

--Global Numbers
--Looking at global death percentage by dead

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, CAST(SUM(new_deaths) as FLOAT) / NULLIF(SUM(new_cases), 0)*100 AS deathPercentage
FROM portfolioProject..CovidDeaths
where continent is not null
GROUP BY date
ORDER BY 1, 2

--Looking at total global deaths

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, CAST(SUM(new_deaths) as FLOAT) / NULLIF(SUM(new_cases), 0)*100 AS deathPercentage
FROM portfolioProject..CovidDeaths
where continent is not null
ORDER BY 1, 2

-- Comparing with vaccination numbers
-- Looking at population vs vaccinations (USING CTE)

With PopVsVac(continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER(
PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM portfolioProject..CovidDeaths dea
JOIN portfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
where dea.continent is not null
)
SELECT *, (CAST(RollingPeopleVaccinated AS FLOAT) / NULLIF(population, 0)) * 100 AS VaccinationPercentage
FROM PopVsVac
ORDER BY location, date

-- Looking at population vs vaccinations (USING Temp Table)

DROP TABLE IF EXISTS #PercentagePopulationVaccinated
CREATE TABLE #PercentagePopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentagePopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER(
PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM portfolioProject..CovidDeaths dea
JOIN portfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
where dea.continent is not null
SELECT *, (CAST(RollingPeopleVaccinated AS FLOAT) / NULLIF(population, 0)) * 100 AS VaccinationPercentage
FROM #PercentagePopulationVaccinated
ORDER BY location, date

-- Creating View to store data for later visualization

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER(
PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM portfolioProject..CovidDeaths dea
JOIN portfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
where dea.continent is not null
