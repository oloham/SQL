What was the average arrival delay?

SELECT avg(arr_delay_new) as "avg_delay"
FROM "Flight_delays";

---------------------------------------------------------

What was the maximum arrival delay?

SELECT max(arr_delay_new) as "max_delay"
FROM "Flight_delays";


---------------------------------------------------------

Which flight had the largest arrival delay?

SELECT carrier, origin_city_name, dest_city_name, fl_date, arr_delay_new
FROM "Flight_delays" 
WHERE arr_delay_new = (SELECT max(arr_delay_new)
                       FROM "Flight_delays")


---------------------------------------------------------


Which days of the week are the worst for traveling in terms of delays?
SELECT  CASE day_of_week 
            WHEN '1' THEN 'Monday'
            WHEN '2' THEN 'Tuesday'
            WHEN '3' THEN 'Wednesday'
            WHEN '4' THEN 'Thursday'
            WHEN '5' THEN 'Friday' 
            WHEN '6' THEN 'Saturday' 
            ELSE 'Sunday' 
        END AS "weekday_name",
        AVG(arr_delay_new) AS "avg_delay"
FROM "Flight_delays" 
GROUP BY day_of_week
ORDER BY "avg_delay" DESC


---------------------------------------------------------

Which airlines flying from San Francisco (SFO) have the smallest arrival delays?

WITH CTE_SFO(airline_name, airline_id, avg_delay)
AS 
(
    SELECT a.airline_name, fd.airline_id, avg(arr_delay_new) 
    FROM "Flight_delays" fd
        INNER JOIN "Airlines" a 
            ON fd.airline_id = a.airline_id
    GROUP BY a.airline_name, fd.airline_id 
)
SELECT DISTINCT c.airline_name, c.avg_delay 
FROM CTE_SFO c
    INNER JOIN "Flight_delays" AS f 
        ON c.airline_id = f.airline_id 
WHERE f.origin = 'SFO'
ORDER BY avg_delay DESC


---------------------------------------------------------

What proportion of airlines have regular delays, i.e., their flights have an average delay of at least 10 minutes?
WITH part_airlines(part)
AS 
(
    SELECT count("id")
    FROM 
    (
    SELECT airline_id AS "id"
    FROM "Flight_delays"
    GROUP BY airline_id 
    HAVING avg(arr_delay_new) >= 10
    ) AS t
), 
all_airlines(al)
AS 
(
    SELECT count(DISTINCT airline_id)
    FROM "Flight_delays" 
)
SELECT CAST(part AS float) / CAST(al AS float) AS "late_proportion"
FROM part_airlines, all_airlines


---------------------------------------------------------

How do departure delays affect arrival delays?
SELECT (
       (SUM(dep_delay_new * arr_delay_new) - 
       (SUM(dep_delay_new) * SUM(arr_delay_new)) / COUNT(*))/
       (SQRT(SUM(dep_delay_new * dep_delay_new) -
       (SUM(dep_delay_new) * SUM(dep_delay_new)) / COUNT(*)) *
        SQRT(SUM(arr_delay_new * arr_delay_new) - 
        (SUM(arr_delay_new) * SUM(arr_delay_new)) / COUNT(*))
       )
      ) AS "Pearson's r"
FROM "Flight_delays"


---------------------------------------------------------

Which airline had the greatest increase (difference) in average arrival delays in the last week of the month, i.e., between July 24th and July 31st?

WITH CTE_first(avg_first, aid1)
AS 
(SELECT avg(arr_delay_new), airline_id
FROM "Flight_delays" 
WHERE "month" = 7 AND day_of_month BETWEEN 1 AND 23 
GROUP BY airline_id),

CTE_second(avg_second, aid2)
AS 
(SELECT avg(arr_delay_new), airline_id
FROM "Flight_delays" 
WHERE "month" = 7 AND day_of_month BETWEEN 24 AND 31
GROUP BY airline_id)

SELECT *
FROM 
(
SELECT  a.airline_name AS "airline_name", 
        max(c2.avg_second - c1.avg_first) AS "delay_increase"
FROM CTE_first c1 
    INNER JOIN CTE_second c2 
        ON c1.aid1 = c2.aid2 
    INNER JOIN "Airlines" a 
        ON a.airline_id = c2.aid2
GROUP BY a.airline_name) AS t 
ORDER BY "delay_increase" DESC 
LIMIT 1


---------------------------------------------------------

Which airlines fly both the SFO → PDX (Portland) and SFO → EUG (Eugene) routes?

SELECT DISTINCT a.airline_name
FROM "Airlines" a
    INNER JOIN "Flight_delays" f1
        ON a.airline_id = f1.airline_id 
    INNER JOIN "Flight_delays" f2
        ON f1.airline_id = f2.airline_id AND f1.origin = f2.origin
WHERE f1.origin = 'SFO' AND f2.dest IN ('PDF','EUG')
GROUP BY a.airline_name


---------------------------------------------------------

What is the quickest way to get from Chicago to Stanford, assuming departure after 2:00 PM local time?
SELECT 
            origin AS "origin", 
              dest AS "dest",
avg(arr_delay_new) AS "avg_delay"
FROM "Flight_delays" 
WHERE origin IN ('MDW','ORD') AND dest IN ('SFO','SJC','OAK') AND crs_dep_time > 1400
GROUP BY origin,dest
ORDER BY "avg_delay" DESC 






