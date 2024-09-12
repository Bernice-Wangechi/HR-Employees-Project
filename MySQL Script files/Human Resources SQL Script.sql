USE projects;

CREATE TABLE hum_res LIKE human_resources;
INSERT INTO hum_res
SELECT* FROM human_resources;

SELECT birthdate from hum_res;
SELECT hire_date from hum_res;
SELECT termdate from hum_res;

SET sql_safe_updates = 0;

UPDATE hum_res
SET birthdate = CASE 
					WHEN birthdate LIKE '%/%' THEN DATE_FORMAT( STR_TO_DATE(birthdate, '%m/%d/%Y'), '%Y-%m-%d')
                    WHEN birthdate LIKE '%-%' THEN DATE_FORMAT( STR_TO_DATE(birthdate, '%m-%d-%Y'), '%Y-%m-%d')
                    ELSE NULL
END;

ALTER TABLE hum_res MODIFY COLUMN birthdate DATE;

UPDATE hum_res
SET hire_date = CASE 
					WHEN hire_date LIKE '%/%' THEN DATE_FORMAT( STR_TO_DATE(hire_date, '%m/%d/%Y'), '%Y-%m-%d')
                    WHEN hire_date LIKE '%-%' THEN DATE_FORMAT( STR_TO_DATE(hire_date, '%m-%d-%Y'), '%Y-%m-%d')
                    ELSE NULL
END;

ALTER TABLE hum_res MODIFY COLUMN hire_date DATE;

UPDATE hum_res 
SET termdate = date(str_to_date(termdate, '%Y-%m-%d %H:%i:%s UTC'))
WHERE termdate IS NOT NULL AND termdate != "";

UPDATE hum_res
SET termdate = NULL
WHERE termdate = '';

ALTER TABLE hum_res 
MODIFY COLUMN termdate DATE;

SELECT* FROM hum_res;
DESCRIBE hum_res;

SET @@sql_mode = '';  -- Disable strict mode temporarily
UPDATE hum_res
SET termdate = '0000-00-00'
WHERE termdate IS NULL;
SET @@sql_mode = 'STRICT_TRANS_TABLES,STRICT_ALL_TABLES';

ALTER TABLE hum_res
ADD COLUMN age INT;

UPDATE hum_res
SET age = TIMESTAMPDIFF(YEAR, birthdate, CURDATE());

SELECT birthdate, age
FROM hum_res;

SELECT max(age), min(age) 
FROM hum_res;

SELECT COUNT(*)
FROM hum_res
WHERE age < 18;

-- WHAT IS THE GENDER BREAKDOWN OF EMPLOYEES IN THE COMPANY?

SELECT gender, COUNT(*) AS count 
FROM hum_res
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY gender;

-- WHAT IS THE RACE/ETHNICITY BREAKDOWN OF EMPLOYEES IN THE COMPANY?
SELECT race, count(*) AS count
FROM hum_res
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY race
ORDER BY count DESC;

-- AGE DISTRIBUTION OF EMPLOYEES IN COMPANY 

SELECT min(age) AS youngest, max(age) AS oldest
FROM hum_res
WHERE age >= 18 AND termdate = '0000-00-00';

SELECT
	CASE
		WHEN age >= 18 AND age <=24 THEN '18-24'
        WHEN age >= 25 AND age <= 34 THEN '25-34'
        WHEN age >= 35 AND age <= 44 THEN '35-44'
        WHEN age >= 45 AND age <= 54 THEN '45-54'
        WHEN age >= 55 AND age <= 60 THEN '55-60'
        ELSE '60+'
	END AS age_group, gender, COUNT(*) AS Count 
FROM hum_res
WHERE age>=18 AND termdate = '0000-00-00'
GROUP BY age_group, gender
ORDER BY age_group, gender;

-- HOW MANY EMPLOYEES WORK AT HEADQUARTERS/REMOTE LOCATIONS? 

SELECT location, COUNT(*) AS Count 
FROM hum_res
WHERE age>=18 AND termdate = '0000-00-00'
GROUP BY location;

-- WHAT IS THE AVERAGE AGE OF EMPLOYMENT FOR EMPLOYEES WHO HAVE BEEN TERMINATED? 

SELECT round(AVG(TIMESTAMPDIFF(YEAR, hire_date, termdate)),0) AS avg_age_of_employment
FROM hum_res
WHERE age >= 18 AND termdate != '0000-00-00' and termdate <= curdate();

-- HOW DOES THE GENDER DISTRIBUTION VARY ACROSS DEPARTMENTS 

SELECT department,gender, COUNT(*) AS Count
FROM hum_res
WHERE age>= 18 AND termdate = '0000-00-00'
GROUP BY department, gender
ORDER BY department;

-- DISTRIBUTION OF JOB TITLES WITHIN COMPANY 

SET SESSION sql_mode = (SELECT REPLACE(@@sql_mode, 'NO_ZERO_DATE', ''));
SELECT jobtitle, COUNT(*) AS Count
FROM hum_res
WHERE age>= 18 AND termdate = '0000-00-00'
GROUP BY jobtitle
ORDER BY jobtitle DESC;

-- WHICH DEPARTMENT HAS THE HIGHEST TURNOVER RATE? Find total employees who left divided by avg number of employees 

SELECT* FROM hum_res;

SELECT department, total_count, terminated_count, terminated_count/total_count AS termination_rate
FROM (SELECT 
		department, 
        count(*) AS total_count,
        SUM(CASE WHEN termdate <> '0000-00-00' AND termdate <= curdate() THEN 1 ELSE 0 END) AS terminated_count
	FROM hum_res
    WHERE age>= 18
    GROUP BY department
    ) AS subquery
ORDER BY termination_rate DESC;

-- WHAT IS THE DISTRIBUTION OF EMPLOYEES ACROSS LOCATIONS BY STATE? 
SELECT location_state, count(*) as count
FROM hum_res
WHERE age>= 18 AND termdate = '0000-00-00'
GROUP BY location_state
ORDER BY count desc;

-- HOW HAS THE COMPANY'S EMPLOYEE COUNT CHANGED OVER TIME BASED ON HIRE AND TERM DATES?

SELECT 
	year,
	hires,
    terminations,
    hires - terminations AS net_change,
    round((hires - terminations)/hires * 100, 2) AS net_percent_change
FROM (
	SELECT 
		YEAR(hire_date) AS year,
        count(*) AS hires,
        SUM(CASE WHEN termdate IS NOT NULL AND termdate <> '0000-00-00' AND termdate <= CURDATE() THEN 1 ELSE 0 END) AS terminations 
        FROM hum_res
        WHERE age>=18 
        GROUP BY YEAR(hire_date)
        ) AS subquery
ORDER BY year DESC;

-- WHAT IS THE TENURE DISTRIBUTION FOR EACH DEPARTMENT? This is the amount of time spent in a company before quitting 

SELECT department, round(avg(TIMESTAMPDIFF(YEAR, hire_date,termdate)),0) AS avg_tenure
FROM hum_res
WHERE age>= 18 AND termdate <= CURDATE() AND termdate <> '0000-00-00'
GROUP BY department;

    
    
