# NETFLIX CONTENT STRATEGY ANALYSIS - END TO END SQL PROJECT

## About this project

I picked up the Netflix Movies and TV Shows dataset from Kaggle to practice SQL beyond just basic SELECT/WHERE queries. The dataset has close to 8,800 titles with details like type, cast, director, country, release year, rating, and genre — but a lot of it is messy (missing directors, inconsistent date formats, multiple values crammed into single columns), which made it a decent dataset to actually practice real data cleaning on, not just querying clean data.

The project goes from setting up the database and table, cleaning the data, and then answering a set of business-style questions using SQL — things like which countries produce the most content, how the catalog has grown over the years, which directors/actors show up most often, and a few more advanced ones using window functions.

## What I was trying to figure out
1. How does the content split between Movies and TV Shows?
2. Which countries and genres dominate the catalog?
3. How has Netflix's content library grown year over year?
4. Are there patterns in ratings, cast size, or genres that say something about content strategy?
5. Where are the gaps/issues in the data itself (missing director, missing country, etc.)?

## Dataset
show_id, type, title, director, cast, country, date_added, release_year, rating, duration, listed_in, description

Source: https://www.kaggle.com/datasets/shivamb/netflix-shows

## Tools

PostgreSQL. Some queries use window functions (LAG, FIRST_VALUE), array/string splitting for the multi-value columns (cast, country, genre), and CASE-based classification.

## A few things that tripped me up while doing this

1. date_added isn't in one consistent format — most rows are like 25-Sep-21 but some are like August 4, 2017, so a single TO_DATE format kept throwing errors until I handled both formats.
2. cast is a reserved keyword in Postgres, so it needs to be quoted as "cast" everywhere or the queries fail.
3. duration mixes minutes (movies) and seasons (TV shows) in the same column, so it needs to be split logically depending on type before doing anything numeric with it.
4. Columns like country, cast, and listed_in hold multiple comma-separated values in a single field, so anything involving "count per country" or "count per genre" needed splitting those out first instead of just grouping by the raw column.

## Findings
1. Around 70% of the catalog is Movies, the rest TV Shows.
2. US, India, and UK show up as the top content-producing countries.
3. TV-MA and TV-14 are the most common ratings, so the catalog leans toward a more mature audience overall.
4. Content additions ramp up noticeably after 2016-17, which lines up with Netflix's big international expansion phase.
5. About 30% of rows don't have a director listed — worth keeping in mind if you're doing any director-level analysis on this dataset, since it'll skew results.

## Files
1. 
