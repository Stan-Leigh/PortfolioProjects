/*
Covid 19 Data Exploration

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/


-- Preview of the CovidDeaths data
SELECT *
FROM PortfolioProject.dbo.CovidDeaths
-- Removes rows where continents were put under the country column
WHERE continent <> ''
ORDER BY Location, date;

-- View data types of columns
SELECT * 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_CATALOG = 'PortfolioProject';
-- Seems all the columns are of type VARCHAR

-- Change column names from VARCHAR to FLOAT for further calculations
ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths float;
ALTER TABLE CovidDeaths
ALTER COLUMN total_cases float;
ALTER TABLE CovidDeaths
ALTER COLUMN date date;
ALTER TABLE CovidDeaths
ALTER COLUMN Population bigint;

-- Total cases vs Total Deaths
-- Shows the likelihood of dying if you are tested positive from covid19
SELECT Location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
-- Avoiding Division by zero error
WHERE total_cases <> 0 
ORDER BY Location, date;

SELECT Location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
-- Avoiding Division by zero error
WHERE total_cases <> 0 AND Location = 'Nigeria'
ORDER BY date;

-- Total cases by Population
-- Shows what percentage of the population has covid19
SELECT Location, date, total_cases, Population, (total_cases / Population) * 100 AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE Location = 'Nigeria'
ORDER BY date;

-- Countries with highest infection rate compared to Population
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / Population) * 100) AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE Population <> 0
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

-- Countries with highest death count compared to Population
SELECT Location, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent <> ''
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- Running this query by continent...
SELECT Location, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent = ''
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- GLOBAL NUMBERS
SELECT date, SUM(CAST(new_cases AS float)) as total_cases, SUM(CAST(new_deaths AS float)) as total_deaths,
		SUM(CAST(new_deaths AS float)) / SUM(CAST(new_cases AS float)) * 100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent = ''
GROUP BY date
HAVING SUM(CAST(new_cases AS float)) <> 0
ORDER BY date;

-- Overall
SELECT SUM(CAST(new_cases AS float)) as total_cases, SUM(CAST(new_deaths AS float)) as total_deaths,
		SUM(CAST(new_deaths AS float)) / SUM(CAST(new_cases AS float)) * 100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent = '' 
HAVING SUM(CAST(new_cases AS float)) <> 0;


-- Preview of the CovidVaccinations data
SELECT *
FROM PortfolioProject..CovidVaccinations;

-- Join both tables
SELECT * 
FROM PortfolioProject..CovidDeaths AS cd
JOIN PortfolioProject..CovidVaccinations AS cv
	ON cd. location = cv.location AND cd.date = cv.date;

-- Total Population and Vaccinations
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations 
FROM PortfolioProject..CovidDeaths AS cd
JOIN PortfolioProject..CovidVaccinations AS cv
	ON cd. location = cv.location AND cd.date = cv.date
WHERE cd.continent <> ''
ORDER by 2, 3;

-- Running total of Vaccinations 
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
		SUM(CONVERT(bigint, cv.new_vaccinations)) OVER(PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingCountVaccinated
FROM PortfolioProject..CovidDeaths AS cd
JOIN PortfolioProject..CovidVaccinations AS cv
	ON cd. location = cv.location AND cd.date = cv.date
WHERE cd.continent <> ''
ORDER by 2, 3;

-- Finding percentage of population vaccinated using CTE
WITH PopsvsVac (Continent, Location, Date, Population, New_vaccinations, RollingCountVaccinated)
AS (
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
		SUM(CONVERT(bigint, cv.new_vaccinations)) OVER(PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingCountVaccinated
FROM PortfolioProject..CovidDeaths AS cd
JOIN PortfolioProject..CovidVaccinations AS cv
	ON cd. location = cv.location AND cd.date = cv.date
WHERE cd.continent <> ''
)
SELECT *, (CONVERT(float, RollingCountVaccinated) / Population) * 100
FROM PopsvsVac
WHERE Population <> 0;

-- Filter out the maximum percentage of population vaccinated
WITH PopsvsVac (Continent, Location, Date, Population, New_vaccinations, RollingCountVaccinated)
AS (
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
		SUM(CONVERT(bigint, cv.new_vaccinations)) OVER(PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingCountVaccinated
FROM PortfolioProject..CovidDeaths AS cd
JOIN PortfolioProject..CovidVaccinations AS cv
	ON cd. location = cv.location AND cd.date = cv.date
WHERE cd.continent <> ''
)
SELECT Location, MAX((CONVERT(float, RollingCountVaccinated) / Population) * 100) AS PercentageVaccinated
FROM PopsvsVac
WHERE Population <> 0
GROUP BY Location
ORDER BY PercentageVaccinated DESC;


-- Finding percentage of population vaccinated using TEMP TABLES
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated (
	Continent NVARCHAR(255),
	Location NVARCHAR(255),
	Date DATETIME,
	Population BIGINT,
	New_vaccinations NVARCHAR(255),
	RollingCountVaccinated NUMERIC
	)

INSERT INTO #PercentPopulationVaccinated

SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
		SUM(CONVERT(bigint, cv.new_vaccinations)) OVER(PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingCountVaccinated
FROM PortfolioProject..CovidDeaths AS cd
JOIN PortfolioProject..CovidVaccinations AS cv
	ON cd. location = cv.location AND cd.date = cv.date
WHERE cd.continent <> ''

SELECT *, (CONVERT(float, RollingCountVaccinated) / Population) * 100 AS PercentageVaccinated
FROM #PercentPopulationVaccinated
WHERE Population <> 0;

GO

-- Creating Views to store data for later Visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
		SUM(CONVERT(bigint, cv.new_vaccinations)) OVER(PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingCountVaccinated
FROM PortfolioProject..CovidDeaths AS cd
JOIN PortfolioProject..CovidVaccinations AS cv
	ON cd. location = cv.location AND cd.date = cv.date
WHERE cd.continent <> '';

GO

SELECT * 
FROM PercentPopulationVaccinated;