
-- Query 1
SELECT * From flight_delays LIMIT 5;

SELECT DISTINCT year,month,day_of_month,day_of_week from flight_delays;

PRAGMA table_info (flight_delays);

SELECT AVG(arr_delay) from flight_delays;

-- Query 2
SELECT MAX(arr_delay) from flight_delays;


-- Query 3
-- In the cell below, write a SQL query that returns the carrier (i.e., carrier), flight number, origin city name, arrival city name,
-- and flight date for the flight with the maximum arrival delay for the entire month of July 2017. Do not hard-code the arrival delay you found above.
-- Hint: use a subquery.
SELECT carrier,fl_num,origin_city_name,dest_city_name,fl_date FROM flight_delays
WHERE arr_delay = (
  SELECT MAX(arr_delay) from flight_delays
);

-- Query 4: Which are the worst days to travel? (10 points)
-- Since CS145 just started, I don't have time to head to Kona anytime soon. However, I'm headed out of town for a trip next week! What day is worst for booking my flight?
-- In the cell below, write a SQL query that returns the average arrival delay time for each day of the week, in descending order. The schema of your relation should be of the form (weekday_name, average_delay).
-- Note: do not report the weekday ID. (Hint: look at the weekdays table and perform a join to obtain the weekday name.)

SELECT origin_city_name, dest_city_name from flight_delays;
SELECT * from weekdays;

SELECT weekday_name,AVG(arr_delay) AS avg_delay -- default
FROM flight_delays, weekdays
  WHERE day_of_week = weekday_id
GROUP BY day_of_week ORDER BY avg_delay DESC;

SELECT weekday_name,AVG(arr_delay) AS avg_delay -- using join
FROM flight_delays
  JOIN weekdays ON flight_delays.day_of_week = weekdays.weekday_id
GROUP BY day_of_week ORDER BY avg_delay DESC;

-- Query 5: Which airlines that fly out of SFO are delayed least?
-- Now that I know which days to avoid, I'm curious which airline I should fly out of SFO.
-- Since I haven't been told where I'm flying, please just compute the average for the airlines that fly from SFO.
-- In the cell below, write a SQL query that returns the average arrival delay time (across all flights) for each carrier
-- that flew out of SFO at least once in July 2017(i.e., in the current dataset), in descending order.
-- Note: do not report the airlines ID. (Hint: a subquery is helpful here; also, look at the airlines table and perform a join.)

select distinct origin_city_name from flight_delays WHERE origin_city_name LIKE '%San%';
select distinct origin_airport_id from flight_delays WHERE origin_city_name LIKE '%San Francisco%';
select airport_id,airport_name from airports WHERE airport_name LIKE '%San Francisco International%'; -- this one

select distinct airports.airport_name from flight_delays, airports
  WHERE flight_delays.origin_airport_id = airport_id;

select * from airlines;
SELECT COUNT(*),AVG(arr_delay) FROM  flight_delays WHERE origin_city_name = 'San Francisco, CA' GROUP BY airline_id;

SELECT airlines.airline_name, AVG(arr_delay) AS avg_arr_delay
FROM flight_delays
  JOIN airlines ON flight_delays.airline_id = airlines.airline_id
  WHERE origin_city_name = 'San Francisco, CA'
  GROUP BY flight_delays.airline_id
  ORDER BY avg_arr_delay DESC;  -- note: different values than the solution

-- Query 6: What proportion of airlines are regularly late?
-- Yeesh, there are a lot of late flights! How many airlines are regularly late?
-- In the cell below, write a SQL query that returns the proportion of airlines (appearing in flight_delays)
-- whose flights are on average at least 10 minutes late to arrive. Do not hard-code the total number of airlines,
-- and make sure to use at least one HAVING clause in your SQL query.
-- Note: sqlite COUNT(*) returns integer types. Therefore, your query should likely contain at least one SELECT CAST (COUNT(*) AS float) or a clause like COUNT(*)*1.0.

-- proportion : #late flights with >= 10 minutes / #total flights

SELECT Count() from flight_delays
GROUP BY airline_id
HAVING AVG(arr_delay) >= 10 AND arr_delay IS NOT NULL;

SELECT (SELECT Count(*) from flight_delays
  GROUP BY airline_id
  HAVING AVG(arr_delay) >= 10 AND arr_delay IS NOT NULL);


-- another try
SELECT subquery_badairline.ids
FROM
  (SELECT distinct x.airline_id as ids from flight_delays x
    GROUP BY       x.airline_id
    HAVING AVG(x.arr_delay) >= 10 AND x.arr_delay IS NOT NULL) as subquery_badairline;

-- good airlines
SELECT DISTINCT airline_id FROM flight_delays
    WHERE airline_id NOT IN
    ( SELECT x.airline_id from flight_delays x
      GROUP BY x.airline_id
      HAVING AVG(arr_delay) >= 10 AND arr_delay IS NOT NULL);

-- bad airlines
SELECT DISTINCT airline_id FROM flight_delays
WHERE airline_id IN
      ( SELECT airline_id from flight_delays
      GROUP BY airline_id
      HAVING AVG(arr_delay) >= 10 AND arr_delay IS NOT NULL);


SELECT COUNT(DISTINCT airline_id)*1.0 as bad_airline
  from flight_delays
  WHERE airline_id IN
        (
          SELECT airline_id
          from flight_delays
          GROUP BY airline_id
          HAVING AVG(arr_delay) >= 10 AND arr_delay IS NOT NULL
        );

-- The only one that works
SELECT late/(late+good) AS 'late_proportion'FROM
  (
    SELECT
      (
        SELECT COUNT(DISTINCT airline_id) * 1.0
        from flight_delays
        WHERE airline_id IN
              (
                SELECT airline_id
                from flight_delays
                GROUP BY airline_id
                HAVING AVG(arr_delay) >= 10 AND arr_delay IS NOT NULL
              )
      ) late,
      (
        SELECT COUNT(DISTINCT airline_id) * 1.0
        from flight_delays
        WHERE airline_id IN
              (
                SELECT airline_id
                from flight_delays
                GROUP BY airline_id
                HAVING AVG(arr_delay) < 10 AND arr_delay IS NOT NULL
              )
      ) good
  );

-- Query 7
-- It sure looks like my plane is likely to be delayed.
-- I'd like to know: if my plane is delayed in taking off, how will it affect my arrival time?
-- The sample covariance provides a measure of the joint variability of two variables.
-- The higher the covariance, the more the two variables behave similarly, and negative covariance indicates the variables indicate the variables tend to be inversely related.
-- We can compute the sample covariance as:
-- In the cell below, write a single SQL query that computes the covariance between the departure delay time and the arrival delay time.

-- FROM (
--      SELECT (...) a, (...) b
-- )

SELECT mean_x, mean_y, f.arr_delay, f.dep_delay FROM
  (
    SELECT
    ( SELECT AVG(x.arr_delay) FROM flight_delays x ) mean_x,
    ( SELECT AVG(y.dep_delay) FROM flight_delays y ) mean_y
  ),
  flight_delays f;

SELECT ((f.arr_delay - mean_x)*(f.dep_delay - mean_y)) as products FROM
  (
    SELECT
      ( SELECT AVG(x.arr_delay) FROM flight_delays x ) mean_x,
      ( SELECT AVG(y.dep_delay) FROM flight_delays y ) mean_y
    ),
flight_delays f;

SELECT sum(products), count(products)
FROM (
  SELECT ((f_inner.arr_delay - mean_x)*(f_inner.dep_delay - mean_y)) as products
  FROM
    (
      SELECT
        ( SELECT AVG(x.arr_delay) FROM flight_delays x ) mean_x,
        ( SELECT AVG(y.dep_delay) FROM flight_delays y ) mean_y
      ),
    flight_delays f_inner
);

-- result
SELECT (1.0/(count(products)-1)*1.0)*sum(products) as 'covariance'
FROM (
  SELECT ((f_inner.arr_delay - mean_x)*(f_inner.dep_delay - mean_y)) as products
  FROM
    (
      SELECT
        ( SELECT AVG(x.arr_delay) FROM flight_delays x ) mean_x,
        ( SELECT AVG(y.dep_delay) FROM flight_delays y ) mean_y
      ),
    flight_delays f_inner
);

-- Query 8
-- Which airlines had the largest absolute increase in average arrival delay in the last week of July (i.e., flights on or after July 24th) compared to the previous days (i.e. flights before July 24th)?
-- In the cell below, write a single SQL query that returns the airline name (not ID) with the maximum absolute increase in average arrival delay between the first 23 days of the month and days 24-31.
-- Report both the airline name and the absolute increase.
-- Note: due to sqlite's handling of dates, it may be easier to query using day_of_month.
-- Note 2: This is probably the hardest query of the assignment; break it down into subqueries that you can run one-by-one and build up your answer subquery by subquery.
-- Hint: You can compute two subqueries, one to compute the average arrival delay for flights on or after July 24th,
-- and one to compute the average arrival delay for flights before July 24th, and then join the two to calculate the increase in delay.
SELECT DISTINCT flight_delays.day_of_week FROM flight_delays;

-- Query 9: Of Hipsters and Anarchists
-- I'm keen to visit both Portland (PDX) and Eugene (EUG), but I can't fit both into the same trip.
-- To maximize my frequent flier mileage, I'd like to use the same flight for each. Which airlines fly both SFO -> PDX and SFO -> EUG?
-- In the cell below,
-- write a single SQL query that returns the distinct airline names (not ID, and with no duplicates) that flew both SFO -> PDX and SFO -> EUG in July 2017.
SELECT airport_name from airports WHERE airport_name LIKE '%San Francisco International';
SELECT airport_name from airports WHERE airport_name LIKE '%Portland International';
SELECT airport_name from airports WHERE airport_name LIKE '%Eugene%';

SELECT origin_airport_id, dest_airport_id, a1.airport_name, a2.airport_name, al.airline_name
FROM flight_delays
JOIN airports a1 ON a1.airport_id = origin_airport_id
JOIN airports a2 ON a2.airport_id = dest_airport_id
JOIN airlines al ON al.airline_id = flight_delays.airline_id
WHERE a1.airport_name LIKE '%San Francisco International%' AND
      (
        (a2.airport_name LIKE '%Portland International')
        OR
        (a2.airport_name LIKE '%Eugene%')
      );

-- Answer
SELECT DISTINCT al.airline_name
FROM flight_delays
  JOIN airports a1 ON a1.airport_id = origin_airport_id
  JOIN airports a2 ON a2.airport_id = dest_airport_id
  JOIN airlines al ON al.airline_id = flight_delays.airline_id
WHERE a1.airport_name LIKE '%San Francisco International' AND
      (
        (a2.airport_name LIKE '%Portland International')
        OR
        (a2.airport_name LIKE '%Eugene%')
      )
;

-- Query 10: Decision Fatigue and Equidistance
-- I'm flying back to Stanford from Chicago later this month, and I can fly out of either Midway (MDW) or O'Hare (ORD)
-- and can fly into either San Francisco (SFO), San Jose (SJC), or Oakland (OAK).
-- If this month is like July, which leg will have the shortest arrival delay for flights leaving Chicago after 2PM local time?
-- In the cell below, write a single SQL query that returns the average arrival delay of flights departing either MDW or ORD after 2PM local time (crs_dep_time) and arriving at one of SFO, SJC, or OAK.
-- Group by departure and arrival airport and return results descending by arrival delay.
-- Note: the crs_dep_time field is an integer formatted as hhmm (e.g. 4:15pm is 1615)
