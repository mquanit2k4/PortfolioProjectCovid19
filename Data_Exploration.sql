CREATE TABLE coviddeaths (
    iso_code VARCHAR(10),
    continent VARCHAR(50),
    location VARCHAR(100),
    date DATE,
    total_cases NUMERIC,
    new_cases NUMERIC,
    new_cases_smoothed NUMERIC,
    total_deaths NUMERIC,
    new_deaths NUMERIC,
    new_deaths_smoothed NUMERIC,
    total_cases_per_million NUMERIC,
    new_cases_per_million NUMERIC,
    new_cases_smoothed_per_million NUMERIC,
    total_deaths_per_million NUMERIC,
    new_deaths_per_million NUMERIC,
    new_deaths_smoothed_per_million NUMERIC,
    reproduction_rate NUMERIC,
    icu_patients NUMERIC,
    icu_patients_per_million NUMERIC,
    hosp_patients NUMERIC,
    hosp_patients_per_million NUMERIC,
    weekly_icu_admissions NUMERIC,
    weekly_icu_admissions_per_million NUMERIC,
    weekly_hosp_admissions NUMERIC,
    weekly_hosp_admissions_per_million NUMERIC,
    new_tests NUMERIC,
    total_tests NUMERIC,
    total_tests_per_thousand NUMERIC,
    new_tests_per_thousand NUMERIC,
    new_tests_smoothed NUMERIC,
    new_tests_smoothed_per_thousand NUMERIC,
    positive_rate NUMERIC,
    tests_per_case NUMERIC,
    tests_units VARCHAR(50),
    total_vaccinations NUMERIC,
    people_vaccinated NUMERIC,
    people_fully_vaccinated NUMERIC,
    new_vaccinations NUMERIC,
    new_vaccinations_smoothed NUMERIC,
    total_vaccinations_per_hundred NUMERIC,
    people_vaccinated_per_hundred NUMERIC,
    people_fully_vaccinated_per_hundred NUMERIC,
    new_vaccinations_smoothed_per_million NUMERIC,
    stringency_index NUMERIC,
    population NUMERIC,
    population_density NUMERIC,
    median_age NUMERIC,
    aged_65_older NUMERIC,
    aged_70_older NUMERIC,
    gdp_per_capita NUMERIC,
    extreme_poverty NUMERIC,
    cardiovasc_death_rate NUMERIC,
    diabetes_prevalence NUMERIC,
    female_smokers NUMERIC,
    male_smokers NUMERIC,
    handwashing_facilities NUMERIC,
    hospital_beds_per_thousand NUMERIC,
    life_expectancy NUMERIC,
    human_development_index NUMERIC
);


CREATE TABLE covidvaccinations (
    iso_code VARCHAR(10),
    continent VARCHAR(50),
    location VARCHAR(100),
    date DATE,
    new_tests NUMERIC,
    total_tests NUMERIC,
    total_tests_per_thousand NUMERIC,
    new_tests_per_thousand NUMERIC,
    new_tests_smoothed NUMERIC,
    new_tests_smoothed_per_thousand NUMERIC,
    positive_rate NUMERIC,
    tests_per_case NUMERIC,
    tests_units VARCHAR(50),
    total_vaccinations NUMERIC,
    people_vaccinated NUMERIC,
    people_fully_vaccinated NUMERIC,
    new_vaccinations NUMERIC,
    new_vaccinations_smoothed NUMERIC,
    total_vaccinations_per_hundred NUMERIC,
    people_vaccinated_per_hundred NUMERIC,
    people_fully_vaccinated_per_hundred NUMERIC,
    new_vaccinations_smoothed_per_million NUMERIC,
    stringency_index NUMERIC,
    population_density NUMERIC,
    median_age NUMERIC,
    aged_65_older NUMERIC,
    aged_70_older NUMERIC,
    gdp_per_capita NUMERIC,
    extreme_poverty NUMERIC,
    cardiovasc_death_rate NUMERIC,
    diabetes_prevalence NUMERIC,
    female_smokers NUMERIC,
    male_smokers NUMERIC,
    handwashing_facilities NUMERIC,
    hospital_beds_per_thousand NUMERIC,
    life_expectancy NUMERIC,
    human_development_index NUMERIC
);



select *
from covid_deaths
where continent is not null
order by 3,4

select *
from covid_accinations
where continent is not null
order by 3,4

-- Select Data that we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from covid_deaths
where continent is not null
order by 1,2

-- Looking at Total Cases vs Total Deaths
-- Show likelihood of dying if you contract covid in your country
select location, date, total_cases, total_deaths, (total_deaths::float / total_cases::float)*100 as DeathPercentage
from covid_deaths
where location ilike 'vietnam' and continent is not null -- ilike not differ upper or lower case
order by 1,2

-- Looking at Total Cases vd Population
-- Shows what percentage of population got Covid!
select location, date, population, total_cases,  (total_cases/population)*100 as DeathPercentage
from covid_deaths
where location ilike 'vietnam' -- ilike not differ upper or lower case
order by 1,2


-- Looking at countries with highest infection rate compared to population
 
select location, population, MAX(total_cases) as HighestInfectionCount,  MAX((total_cases/population))*100 as PercentPopulationInfected
from covid_deaths
-- where location ilike 'vietnam' -- ilike not differ upper or lower case
where continent is not null
group by location, population
order by PercentPopulationInfected NULLS LAST
 
 -- Showing countries with highest death count per population
 
select location, MAX(total_deaths) AS TotalDeathCount
from covid_deaths
-- where location ilike 'vietnam' -- ilike not differ upper or lower case
where continent is not null
group by location
order by TotalDeathCount DESC NULLS LAST
 
-- BREAK THINGS DOWN BY CONTINENT

select continent, MAX(total_deaths) AS TotalDeathCount
from covid_deaths
-- where location ilike 'vietnam' -- ilike not differ upper or lower case
where continent is not null
group by continent
order by TotalDeathCount DESC NULLS LAST
 
 
-- GLOBAL NUMBER --
select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths::float) / SUM(new_cases::float)*100 as DeathPercentage
from covid_deaths
where continent is not null
-- group by date
order by 1,2

-- Looking at total population vs vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100 
from covid_deaths dea
join covid_vaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (continent, location, date, population, new_vaccinations, RolingPeopleVaccinated, VaccinationRate)
AS 
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated,
        (SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.date) / dea.population) * 100 AS VaccinationRate
    FROM covid_deaths dea
    JOIN covid_vaccinations vac
        ON dea.location = vac.location 
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac
ORDER BY location, date;

-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMP TABLE PercentPopulationVaccinated
(
	continent VARCHAR(255),
	location VARCHAR(255),
	date DATE,
	population NUMERIC,
	new_vaccinations NUMERIC,
	RollingPeopleVaccinated NUMERIC
);

INSERT INTO PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100 
from covid_deaths dea
join covid_vaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date;
-- where dea.continent is not null
-- order by 2,3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM PercentPopulationVaccinated

-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100 
from covid_deaths dea
join covid_vaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null








































 