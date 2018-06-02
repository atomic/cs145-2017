
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
SELECT late/(late+good) AS 'late_proportion' FROM (SELECT
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

-- 