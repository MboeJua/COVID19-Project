-- The subsequent analysis is on Covid19 data 
-- Data Exploration CovidDeaths Table

--country level
select *
from CovidDeaths
Where continent is not null 
order by 3,4;

--continent level
select *
from CovidDeaths
Where continent is null 
order by 3,4;

--Descriptive Statistics  based on selected variables of interest
Select Location, date, total_cases, new_cases, total_deaths, total_vaccinations, gdp_per_capita,  population
From CovidDeaths
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country (My scenario Cameroon)

Select Location, date, total_cases,total_deaths, round((total_deaths/total_cases)*100,4) as DeathPercentage
From CovidDeaths
Where location like '%roon%' and total_deaths is not null
and continent is not null 
order by 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in developed versus developing countries
Select Location, max(total_cases) as TotalCases,max(total_deaths) as TotalDeaths, round((max(total_deaths)/max(total_cases))*100,4) as DeathPercentage, 
avg(gdp_per_capita) as GDPperCapita,
case when gdp_per_capita > 25000 then 'Developed'
else 'Developing'
end as GrowthStatus
From CovidDeaths
Where continent is not null  and total_cases is not null and gdp_per_capita is not null
group by Location, case when gdp_per_capita > 25000 then 'Developed'
else 'Developing'
end 
order by 6,1,2

-- Shows likelihood of dying if you contract covid in developed versus developing countries
Select  sum(new_cases) as TotalCases,sum(new_deaths) as TotalDeaths, round((sum(new_deaths)/sum(new_cases))*100,4) as DeathPercentage, 
avg(gdp_per_capita) as GDPperCapita,
case when gdp_per_capita > 25000 then 'Developed'
else 'Developing'
end as GrowthStatus
From CovidDeaths
Where continent is not null  and total_cases is not null and gdp_per_capita is not null
group by case when gdp_per_capita > 25000 then 'Developed'
else 'Developing'
end 
order by 5,1


-- Shows likelihood of dying if you contract covid in Cameroon versus Rest of the World
Select  sum(new_cases) as TotalCases,sum(new_deaths) as TotalDeaths, round((sum(new_deaths)/sum(new_cases))*100,4) as DeathPercentage, 
avg(gdp_per_capita) as GDPperCapita,
case when Location =  'Cameroon' then 'Cameroon'
else 'Rest of the World'
end as LocationStatus
From CovidDeaths
Where continent is not null  and total_cases is not null and gdp_per_capita is not null
group by case when Location =  'Cameroon' then 'Cameroon'
else 'Rest of the World'
end 
order by 5,1


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  round((total_deaths/total_cases)*100,4) as PercentPopulationInfected
From CovidDeaths
--Where location like '%states%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount, max(gdp_per_capita) as GDPPerCapita, round(Max((total_cases/population))*100,4) as PercentPopulationInfected
From CovidDeaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc, GDPPerCapita


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using Temp Table to perform Calculation on Partition By in previous query --

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
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
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date


Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac


-- Creating View to store data for later visualizations

CREATE VIEW  PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
