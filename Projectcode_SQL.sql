
--Es wird mithilfe von SQL ein Überblick über die aktuelle Lage der Covid-19 Pandemie erarbeitet
--Dabei wird der Datensatz analysiert und zu spannenden Fragen werden mithilfe von SQL Daten bereitgestellt
--Quelle des Datensatzes:https://ourworldindata.org/covid-deaths

--Im Ersten Schritt wurde der Datensatz mit Excel bereinigt und die Formatierung wurde angepasst
--Der Datensatz wurde aufgeteilt in die zwei Unterdatensätze "CovidDeaths" und "CovidVaccination"
--Schließlich wurden die zwei Unterdatensätze in einer SQL Datenbank importiert

--Datensatz anzeigen lassen
SELECT *
FROM PortfolioProject..CovidDeaths AS cd;

SELECT *
FROM PortfolioProject..CovidVaccinations AS cv;

--Datensatz mit SQL bereinigen
UPDATE PortfolioProject..CovidDeaths
SET total_cases=0 
WHERE total_cases IS NULL;

UPDATE PortfolioProject..CovidDeaths
SET total_deaths=0 
WHERE total_deaths IS NULL;


--Gegenüberstellung von Covid Tote und Covid Fälle in Deutschland
--Mit welcher Wahrscheinlichkeit sterben Menschen aktuell in Deutschland durch Covid?
SELECT cd.location AS 'Land', cd.date AS 'Datum', cd.total_cases AS 'CovidFaelle', cd.total_deaths AS 'CovidTote', (CONVERT(DECIMAL(15, 3), cd.total_deaths) / CONVERT(DECIMAL(15, 3), total_cases))*100 AS 'ProzentualesVerhaeltnis'
FROM PortfolioProject..CovidDeaths AS cd
WHERE location='Germany' 
ORDER BY cd.location, cd.date DESC;


--Gegenüberstellung von Covid Fälle und Einwohnerzahl
--Wie viele Covid Fälle wurden in Deutschland registriert?
SELECT cd.location AS 'Land', cd.date AS 'Datum', cd.population AS 'Einwohnerzahl', cd.total_cases AS 'CovidFaelle', (CONVERT(DECIMAL(15, 3), cd.total_cases) / CONVERT(DECIMAL(15, 3), cd.population))*100 AS 'ProzentualesVerhaeltnis'
FROM PortfolioProject..CovidDeaths AS cd
WHERE cd.location='Germany' 
ORDER BY cd.date DESC;


--Welche Länder haben aktuell den höchsten Anteil der Bevölkerung die in der Pandemie schon mal Covid hatten ?
SELECT cd.location AS 'Land', cd.population AS 'Einwohnerzahl', MAX(CAST(cd.total_cases AS DECIMAL(15,3))) AS 'Covid_Erkrankungen', MAX((CONVERT(DECIMAL(15, 3), cd.total_cases) / CONVERT(DECIMAL(15, 3), cd.population)))*100 AS 'Anteil_Der_Bevölkerung_mit_Coviderkrankung'
FROM PortfolioProject..CovidDeaths AS cd
GROUP BY cd.population, cd.location
ORDER BY Anteil_Der_Bevölkerung_mit_Coviderkrankung DESC;


--Welche Länder haben aktuell den höchsten Anteil der Bevölkerung die in der Pandemie durch Covid gestorben sind?
SELECT cd.location AS 'Land', cd.population AS 'Einwohner', MAX(CAST(cd.total_deaths as DECIMAL(15,3))) AS 'Covid_Tote', MAX((CONVERT(DECIMAL(15, 3), cd.total_deaths) / CONVERT(DECIMAL(15, 3), cd.population)))*100 AS 'Anteil_Der_Bevölkerung_mit_Tod_durch_Covid'
FROM PortfolioProject..CovidDeaths AS cd
GROUP BY cd.location, cd.population
ORDER BY Anteil_Der_Bevölkerung_mit_Tod_durch_Covid DESC;


--Wie viele Menschen sind pro Land gestorben durch Covid?
SELECT cd.location AS 'Land', MAX(CAST(cd.total_deaths as DECIMAL(15,3))) AS 'Covid_Tote'
FROM PortfolioProject..CovidDeaths AS cd
WHERE continent IS NOT NULL
GROUP BY cd.location
ORDER BY Covid_Tote DESC;


--Wie viele Menschen sind pro Kontinent gestorben durch Covid?
SELECT cd.continent AS 'Kontinent', MAX(CAST(cd.total_deaths as DECIMAL(15,3))) AS 'Covid_Tote'
FROM PortfolioProject..CovidDeaths AS cd
WHERE continent IS NOT NULL
GROUP BY cd.continent
ORDER BY Covid_Tote DESC;


--Wie sieht die tägliche Infektionsrate und Todesrate in den letzten zwei Wochen aus?  
SELECT TOP 14 cd.date AS 'Datum', SUM(CAST(cd.new_deaths AS DECIMAL(15,3))) AS 'Neue Tote', SUM(CAST(cd.new_cases AS DECIMAL(15,3))) AS 'Neue Fälle',  SUM(CAST(cd.new_deaths AS DECIMAL(15,3))) / SUM(CAST(cd.new_cases AS DECIMAL(15,3)))*100 AS 'Anteil'
FROM PortfolioProject..CovidDeaths AS cd
WHERE cd.continent IS NOT NULL
GROUP BY cd.date
ORDER BY cd.date DESC;


--Was waren die letzten 10 Tage an denen weltweit über 15000 Menschen an Covid gestorben sind?
SELECT TOP 10 cd.date AS 'Datum', SUM(CAST(cd.new_deaths AS DECIMAL(15,3))) AS 'Neue Tote', SUM(CAST(cd.new_cases AS DECIMAL(15,3))) AS 'Neue Fälle',  SUM(CAST(cd.new_deaths AS DECIMAL(15,3))) / SUM(CAST(cd.new_cases AS DECIMAL(15,3)))*100 AS 'Anteil'
FROM PortfolioProject..CovidDeaths AS cd
WHERE cd.continent IS NOT NULL
GROUP BY cd.date
HAVING SUM(CAST(cd.new_deaths AS DECIMAL(15,3)))>15000
ORDER BY cd.date DESC;


--Was ist aggregierte Anzahl der Geimpften Personen im Verlauf der Pandemie in Deutschland?
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(CAST(cv.new_vaccinations AS DECIMAL(15,3))) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS AggregierteGeimpfte
FROM PortfolioProject..CovidDeaths AS cd
JOIN PortfolioProject..CovidVaccinations AS cv
	ON cd.location = cv.location AND cd.date=cv.date
WHERE cd.location='Germany'
ORDER BY cd.date ASC


--Was hat sich der Anteil der geimpften Bevölkerung in Deutschland verändert?(Ist nur sinnvoll, solange Menschen sich nur einmal impfen lassen)
WITH tabelle (continent, location, date, population, new_vaccinations, AggregierteGeimpfte)
AS
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(CAST(cv.new_vaccinations_smoothed AS DECIMAL(15,3))) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS AggregierteGeimpfte
FROM PortfolioProject..CovidDeaths AS cd
JOIN PortfolioProject..CovidVaccinations AS cv
	ON cd.location = cv.location AND cd.date=cv.date
WHERE cd.location='Germany'
)
SELECT *, (AggregierteGeimpfte/population)*100 AS Anteil_Pro_Einwohner
FROM tabelle


--Tabelle erstellen, um die Ausgabe zu speichern
DROP TABLE IF exists ProzentualeAggregierteImpfzahl
CREATE TABLE ProzentualeAggregierteImpfzahl
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
New_vaccinations numeric,
AggregierteImpfungen numeric
) 

INSERT INTO ProzentualeAggregierteImpfzahl
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(CAST(cv.new_vaccinations_smoothed AS DECIMAL(15,3))) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS AggregierteImpfungen
FROM PortfolioProject..CovidDeaths AS cd
JOIN PortfolioProject..CovidVaccinations AS cv
	ON cd.location = cv.location AND cd.date=cv.date
WHERE cd.location='Germany'

SELECT *, (AggregierteImpfungen/population)*100 AS Anteil_Pro_Einwohner
FROM ProzentualeAggregierteImpfzahl


--Eine View erstellen, um später die Daten visualisieren zu können, z.B. mit PowerBI oder Tableau
CREATE VIEW View_ProzentualeAggregierteImpfzahl AS 
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(CAST(cv.new_vaccinations_smoothed AS DECIMAL(15,3))) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS AggregierteImpfungen
FROM PortfolioProject..CovidDeaths AS cd
JOIN PortfolioProject..CovidVaccinations AS cv
	ON cd.location = cv.location AND cd.date=cv.date
WHERE cd.location='Germany';

SELECT *
FROM View_ProzentualeAggregierteImpfzahl