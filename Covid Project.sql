--data check
SELECT * FROM CovidVaccinations
ORDER BY 3,4
SELECT * FROM CovidDeaths
ORDER BY 3,4

--Select the data I am going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
order by 1,2

--Looking at Total Cases vs. Total Deaths in the United States
--this shows the likelihood of death if one had covid in your country
SELECT location, date, total_cases, total_deaths, (CONVERT(DECIMAL(18,2), total_deaths) / CONVERT(DECIMAL(18,2), total_cases) )*100 AS DeathRate
from CovidDeaths
where location like '%states%' and continent is not NULL
order by 1,2

--Looking at Total Cases vs Population
--Shows what percentage of population got covid
SELECT location, date, total_cases, population, (CONVERT(DECIMAL(18,2), total_cases) / CONVERT(DECIMAL(18,2), population) )*100 AS InfectedRate
from CovidDeaths
where location like '%states%' and continent is not NULL
order by 1,2

--Looking at countries with highest infection rate compared to the population
SELECT location, MAX(total_cases) as HighestInfectionCount, population, (CONVERT(DECIMAL(18,2), MAX(total_cases)) / CONVERT(DECIMAL(18,2), population) )*100 AS Highest_Infection_Rate_by_Country
from CovidDeaths
--where location like '%states%'
GROUP BY location, population
order by Highest_Infection_Rate_by_Country DESC

--Showing Countries with Highest Death Count per Population
SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
from CovidDeaths
--where location like '%states%'
WHERE continent is not null
GROUP BY location
order by TotalDeathCount DESC

	--breaking it down by continent
	SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCountperContinent
from CovidDeaths
--where location like '%states%'
WHERE continent is not null
GROUP BY continent
order by TotalDeathCountperContinent DESC

		--to find the correct numbers for the continent, I needed to use location instead of continent as location field values were populated in continent 
	SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCountperContinent
	from CovidDeaths
	WHERE continent is null and location IN ('North America', 'South America', 'Asia', 'Europe', 'Africa', 'Oceania')
	GROUP BY location
	order by TotalDeathCountperContinent DESC

	--showing the continents with the highest death count
	SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCountperContinent
	from CovidDeaths
	WHERE continent is null and location IN ('North America', 'South America', 'Asia', 'Europe', 'Africa', 'Oceania')
	GROUP BY location
	order by TotalDeathCountperContinent DESC


--GLOBAL NUMBERS
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as totaldeaths, SUM(cast(new_deaths as int)) /nullif(SUM(new_cases),0)*100 AS DeathRate
from CovidDeaths
where continent IS NOT NULL
--group by date
order by 1,2

--Looking at total population vs. vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) AS PeopleVaccinatedRolling
from CovidDeaths as dea
JOIN CovidVaccinations as vac
	ON dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--CTE
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100 as PercentPeopleVaccinated
From PopvsVac

--TEMP TABLE

Drop Table if exists #PercentPopulationVaccinated
Create Table  #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100 as PercentPeopleVaccinated
From #PercentPopulationVaccinated


--Creating View to store data for later visualization

Create view PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

Select *
From PercentPopulationVaccinated