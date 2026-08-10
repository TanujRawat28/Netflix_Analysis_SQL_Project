--- Netflix Project

CREATE TABLE netflix
(
	show_id	VARCHAR(10),
	type VARCHAR(20),
	title VARCHAR(170),
	director VARCHAR(230),
	casts VARCHAR(1100),
	country VARCHAR(170),
	date_added	VARCHAR(70),
	release_year INT,
	rating	VARCHAR(20),
	duration VARCHAR(30),
	listed_in	VARCHAR(120),
	description VARCHAR(300)
);


select * from netflix;

-- Clean date_added(Text -> real date column)

ALTER TABLE netflix ADD COLUMN date_added_clean DATE;

UPDATE netflix
SET date_added_clean =
    CASE
        -- Format 1: '25-Sep-21'
        WHEN TRIM(date_added) ~ '^[0-9]{1,2}-[A-Za-z]{3}-[0-9]{2}$'
            THEN TO_DATE(TRIM(date_added), 'DD-Mon-YY')
        -- Format 2: 'August 4, 2017'
        WHEN TRIM(date_added) ~ '^[A-Za-z]+ [0-9]{1,2}, [0-9]{4}$'
            THEN TO_DATE(TRIM(date_added), 'Month DD, YYYY')
        ELSE NULL
    END
WHERE date_added IS NOT NULL;

-- Quick check: how many rows failed to parse (should be close to 0, only true NULLs / blanks in the original column)

SELECT
	COUNT(*)
FROM netflix 
WHERE
	date_added IS NOT NULL AND 
	date_added_clean IS NULL;


-- Business Problems / SQL Question (22 Total)



-- Q1: Count the number of Movies vs TV Shows.
-- Goal: See if our catalog has more movies or more TV shows, so we know exactly how to split our future budget
-- when buying new content.
SELECT
	type,
	COUNT(*) AS Total_count
FROM netflix
GROUP BY type;

-- Q2: Find the most common rating for Movies and for TV Shows.
-- Goal: Find the most common age rating for both movies and TV shows, so we can see if our catalog is
-- mostly made for adults or for families.
SELECT type, rating, total
FROM (
    SELECT type, rating, COUNT(*) AS total,
           RANK() OVER (PARTITION BY type ORDER BY COUNT(*) DESC) AS rnk
    FROM netflix
    WHERE rating IS NOT NULL
    GROUP BY type, rating
) t
WHERE rnk = 1;

-- Q3: List all movies released in a specific year (e.g. 2021)
-- Goal: Pull data for specific years so we can build year-by-year review reports and track how our
-- content changes over time.
SELECT
	TITLE,
	RELEASE_YEAR
FROM
	NETFLIX
WHERE
	TYPE = 'Movie'
	AND RELEASE_YEAR = '2021';

-- Q4: Find the top 5 countries with the most contenton on netflix.
-- Goal: Find the countries making the most content for us, so we know exactly where to invest our money 
-- and buy future show licenses.
SELECT
	COUNTRY,
	COUNT(*) AS TOTAL_COUNT
FROM
	NETFLIX
WHERE
	COUNTRY IS NOT NULL
GROUP BY
	COUNTRY
ORDER BY
	TOTAL_COUNT DESC
LIMIT
	5;

-- Q5: Identify the longest movie (by duration in minutes).
-- Goal: Optimize catalog quality and viewing efficiency by identifying and managing cost-inefficient content, such as 
-- unusually long films.
SELECT 
	title,
	duration
FROM
	netflix
WHERE 
	type = 'Movie'
	AND duration IS NOT NULL
ORDER BY
	CAST(REPLACE(duration, 'min','') AS INT)
DESC
LIMIT
	1;

-- Q6: Number of content items added to Netflix each year.
-- Goal: Measure how fast our platform is growing so we can justify spending more money on tech infrastructure and new content.
SELECT
	EXTRACT(YEAR FROM date_added_clean) AS year_added,
	COUNT(*) AS Total_added
FROM 
	netflix
WHERE
	date_added_clean IS NOT NULL
GROUP BY
	year_added
ORDER BY
	year_added;

-- Q7: Number of content items in each genre.
-- Goal: See which genres we have too much of and which ones we are missing, so we know exactly what kind of content to 
-- buy or make next.
SELECT
	TRIM(genre) AS genre,
	COUNT(*) AS Total_content
FROM
	netflix, 
	UNNEST(STRING_TO_ARRAY(listed_in,',')) AS genre
GROUP BY 
	TRIM(genre)
ORDER BY 
	total_content 
DESC;

-- Q8: Top 10 directors with the most content.
-- Goal: Secure better long-term contracts and improve creator partnerships by identifying the directors and actors who produce the 
-- highest volume of successful content.
SELECT 
	director,
	COUNT(*) AS Total_content
FROM
	netflix
WHERE
	director IS NOT NULL
GROUP BY
	director
ORDER BY
	total_content
DESC
LIMIT
	10;

-- Data Quality Check

-- Q9: Content where country information is missing 
-- Goal: Fix missing country details in our dataset so we can generate accurate regional performance reports and
-- stop making business decisions based on incomplete data.
SELECT
	COUNT(*) AS missing_country
FROM
	netflix
WHERE
	country IS NULL;

-- Q10: content where director information is missing
-- Fix missing director names in our dataset so we can accurately track which creators are driving the most viewership and
-- making the company money.
SELECT
	COUNT(*) AS missing_director
FROM
	netflix
WHERE
	director IS NULL;

-- Q11: Top 10 actors who've appeared in the most movies produced in India 
-- Goal: Identify top Indian actors to optimize casting and marketing for regional growth.
SELECT 
	TRIM(actor) AS actor,
	COUNT(*) AS Total_movies
FROM
	netflix,
	UNNEST(STRING_TO_ARRAY(casts, ',')) AS actor
WHERE
	country = 'India' AND type = 'Movie'
GROUP BY
	TRIM(actor)
ORDER BY
	total_movies
DESC
LIMIT
	10;

-- Q12: Actor-Director collaborations
-- Goal: Increase the success rate of future shows and movies by finding winning director-and-actor combinations that 
-- we should fund again.
SELECT
	director,
	TRIM(actor) AS actor,
	COUNT(*) AS Title_together
FROM
	netflix,
	UNNEST(STRING_TO_ARRAY(casts,',')) AS actor
WHERE 
	director IS NOT NULL
	AND 
	casts IS NOT NULL
GROUP BY
	director,
	TRIM(actor)
HAVING COUNT(*) > 1
ORDER BY 
	Title_together DESC
LIMIT
	10;


-- Q13: Content 'drought' years per country
-- Goal: Find the countries where we barely have any content, so we can launch new shows there and win over new subscribers.
SELECT
	country,
	release_year,
	gap_years
FROM (
	SELECT
		country,
		release_year,
		release_year - LAG(release_year) OVER (PARTITION BY country ORDER BY release_year) AS gap_years
	FROM
		(SELECT DISTINCT
			country,
			release_year
		FROM 
			netflix
		WHERE
			country IS NOT NULL
		) as t
) AS t
WHERE 
	gap_years IS NOT NULL
ORDER BY
	gap_years DESC
LIMIT
	10;


-- Q14: Solo vs Ensemble content (avg casts size by type)
-- Goal: Look at how movie formats differ from TV show formats so we can plan and manage our production budgets more accurately.
SELECT
	type,
	ROUND(AVG(ARRAY_LENGTH(STRING_TO_ARRAY(casts,','),1)),2) AS avg_casts_size
FROM
	netflix
WHERE
	casts IS NOT NULL
GROUP BY
	type;


-- Q15: Release-To-Netflix lag
-- Goal: See if we are adding mostly brand-new releases or older classic shows, so we can spend our licensing budget on
-- the content that keeps subscribers hooked.
SELECT
	title,
	release_year,
	EXTRACT(YEAR FROM date_added_clean) AS year_added,
	EXTRACT(YEAR FROM date_added_clean) - release_year AS lag_years
FROM
	netflix
WHERE
	date_added_clean IS NOT NULL
ORDER BY
	lag_years DESC
LIMIT
	10;


-- Q16: Rating trend over time (% mature content per release year)
-- Goal: Check if our content is getting more mature over the years, so we can market our brand correctly and
-- build better parental controls for families.
SELECT
	release_year,
	ROUND(
		100.0 * SUM(CASE WHEN rating IN ('TV-MA', 'R') THEN 1 ELSE 0 END) / COUNT(*),2) AS pct_mature_content
FROM
	netflix
WHERE
	rating IS NOT NULL
GROUP BY
	release_year
ORDER BY
	release_year;


-- Q17: Director specialization (specialization vs generalist)
-- Goal: Figure out which directors stick to one specific genre and which ones can jump across many, so we
-- know exactly who to hire for different types of upcoming projects.
SELECT
	director,
	COUNT(*) AS total_titles,
	COUNT(DISTINCT listed_in) AS distinct_genre_combinations,
	CASE
		WHEN
			COUNT(DISTINCT listed_in) = 1 THEN 'Specialist'
		ELSE 'Generalist'
	END AS director_type
FROM
	netflix
WHERE
	director IS NOT NULL
GROUP BY
	director
HAVING COUNT(*) >= 3
ORDER BY
	total_titles DESC;


-- Q18: Monthly seasonality of content drops
-- Goal: Check if we release most of our big shows and movies during specific months (like the holidays), 
-- so we can time our launches perfectly to beat the competition.
SELECT
	TO_CHAR(date_added_clean, 'Month') AS month_added,
	COUNT(*) AS total_added
FROM
	netflix
WHERE
	date_added_clean IS NOT NULL
GROUP BY
	TO_CHAR(date_added_clean, 'Month'), EXTRACT(MONTH FROM date_added_clean)
ORDER BY
	EXTRACT(MONTH FROM date_added_clean);


-- Q19: Country content diversity index
-- Goal: Find out which countries make a massive variety of genres and which ones focus on just one 
-- specific niche, so we know where to branch out versus where to keep buying what they do best.
SELECT
	country,
	COUNT(DISTINCT listed_in) AS distinct_genre_combinations
FROM
	netflix
WHERE
	country IS NOT NULL
GROUP BY
	country
ORDER BY
	distinct_genre_combinations DESC
LIMIT
	10;


-- Q20: "One-Hit" vs recurring directors
-- Goal: See how much of our content comes from directors we only hire once versus the partners we work 
-- with long-term, so we can build better strategies to keep top talent from leaving.
SELECT
	CASE
		WHEN total_titles = 1 THEN 'One-time Director' 
		ELSE
			'Recurring Director' 
	END AS director_type,
	COUNT(*)AS num_directors,
	ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_directors
FROM (
	SELECT
		director,
		COUNT(*) AS total_titles
	FROM
		netflix
	WHERE
		director IS NOT NULL
	GROUP BY
		director
) AS d
GROUP BY
	director_type;


-- Q21: Casts overlap between countries (crossover talent)
-- Goal: Find the actors who are popular in multiple countries so we can cast them in global projects and use them in
-- big international marketing campaigns.
SELECT
	TRIM(actor) AS actor,
	COUNT(DISTINCT country) AS num_countries
FROM
	netflix,
	UNNEST(STRING_TO_ARRAY(casts,',')) AS actor
WHERE
	casts IS NOT NULL
	AND country IS NOT NULL
GROUP BY
	TRIM(actor)
HAVING
	COUNT(DISTINCT country) > 1
ORDER BY
	num_countries DESC
LIMIT
	10;


-- Q22: Each Country's most recent and oldest content addition
-- Goal: See the age range of content for each country in a single look, so we can quickly update our global dashboards with
-- the newest and oldest titles.
SELECT DISTINCT
	country,
	FIRST_VALUE(title) OVER (PARTITION BY country ORDER BY date_added_clean ASC) AS oldest_title,
	FIRST_VALUE(title) OVER (PARTITION BY country ORDER BY date_added_clean DESC) AS newest_title
FROM
	netflix
WHERE
	country IS NOT NULL
	AND date_added_clean IS NOT NULL;