Provide a list of artists along with the number of music genres they engage in, sorted in descending order of music genres and ascending order of artist names. 
Also, provide their ranking in descending order.

WITH artist_genre_num_rank AS (
    WITH artist_genre_num AS (
        SELECT
            g.genreid AS "genre",
            a.name AS "name",
            DENSE_RANK() OVER(PARTITION BY a.artistid ORDER BY g.genreid) AS "rank_num"
        FROM artist a
        INNER JOIN album l
        ON a.artistid = l.artistid
        INNER JOIN track t
        ON l.albumid = t.albumid
        INNER JOIN genre g
        ON t.genreid = g.genreid
    )
    SELECT DISTINCT
        name AS "artist_name",
        max("rank_num") over(PARTITION BY "name") AS "number_of_music_genres"
    FROM artist_genre_num
)
SELECT
    artist_name,
    number_of_music_genres,
    DENSE_RANK() OVER(ORDER BY number_of_music_genres DESC) AS "Ranking"
FROM artist_genre_num_rank
ORDER BY number_of_music_genres DESC, artist_name ASC;

-----------------------------------------------------------------------------------------------

What is the average sales in a given month relative to the average sales from the previous month? 
Create a report using an appropriate window function that reads the previous row.

WITH table_with_lag
AS 
(
SELECT DISTINCT 
                EXTRACT (YEAR FROM invoicedate) AS "year", 
                EXTRACT (MONTH FROM invoicedate) AS "month", 
                ROUND(AVG(total) over(PARTITION BY EXTRACT (YEAR FROM invoicedate), EXTRACT (MONTH FROM invoicedate)), 6) AS "average_sales" 
FROM invoice
)
SELECT DISTINCT 
                year, 
                month, 
                average_sales, 
                lag(average_sales) over(PARTITION BY year) AS "previous_month"
FROM table_with_lag 
ORDER BY year, month


-----------------------------------------------------------------------------------------------

Provide the top ten customers who spent the most in this store.

WITH ordered_table
AS 
(
    SELECT DISTINCT 
                    c.firstname AS "first_name", 
                    c.lastname AS "last_name",
                    sum(total) over(PARTITION BY c.customerid) AS "total_amount"
    FROM invoice i
        INNER JOIN customer c
            ON i.customerid=c.customerid
)
SELECT
        first_name,
        last_name, 
        total_amount 
FROM ordered_table 
ORDER BY total_amount DESC
LIMIT 10 


-----------------------------------------------------------------------------------------------

Provide the distribution of the sum of money spent by customers by country, in percentage with one-thousandth precision. 
Sort the result by the highest share.

SELECT* 
FROM 
(
    SELECT DISTINCT 
                    billingcountry AS "country", 
                    round(sum(total) over(PARTITION BY billingcountry)/sum(total) OVER() *100, 1) AS "%"
    FROM invoice
) AS t 
ORDER BY "%" DESC 


-----------------------------------------------------------------------------------------------

Provide the percentage (rounded to two decimal places) distribution of music file format types - from the entire dataset and additionally by music genres. 
What genre of music has not been purchased?

SELECT DISTINCT 
        g.name AS "genre_name",
        m.name AS "format_name",
        count(t.trackid) over(PARTITION BY t.mediatypeid) AS "number_of_tracks_format",
        ROUND(count(t.trackid) over(PARTITION BY t.mediatypeid)::decimal / count(t.trackid) OVER()::decimal * 100, 2) AS "%_format",
        count(t.trackid) over(PARTITION BY t.mediatypeid, g.genreid) AS "number_of_tracks_format_genre", 
        ROUND(count(t.trackid) over(PARTITION BY t.mediatypeid, g.genreid)::decimal / count(t.trackid) OVER()::decimal * 100, 2) AS "%_format_genre"
FROM invoiceline ii 
    LEFT OUTER JOIN track t 
        ON t.trackid=ii.trackid
    LEFT OUTER JOIN mediatype m 
        ON t.mediatypeid=m.mediatypeid 
    RIGHT OUTER JOIN genre g  
        ON g.genreid=t.genreid
ORDER BY "number_of_tracks_format" DESC, "%_format" DESC, "number_of_tracks_format_genre" DESC, "%_format_genre" DESC 

-----------------------------------------------------------------------------------------------

Provide the average bit rate in kbps for MPEG, MPEG4, and AAC file formats purchased songs at two levels of granularity, 
by file formats and by music genres. Present the result rounded to two decimal places and sorted by MediaTypeId and GenreId.

SELECT DISTINCT 
                m.name AS "file_format", 
                ROUND(avg(t.bytes/t.milliseconds) OVER(PARTITION BY t.mediatypeid), 2) AS "average_bitrate_format",
                g.name AS "music_genre",
                ROUND(avg(t.bytes/t.milliseconds) OVER(PARTITION BY t.genreid), 2) AS "average_bitrate_genre",
                ROUND(avg(t.bytes/t.milliseconds) OVER(PARTITION BY t.mediatypeid, t.genreid), 2) AS "average_bitrate_format_genre"
FROM invoiceline il 
    INNER JOIN track t 
        ON t.trackid=il.trackid
    INNER JOIN mediatype m 
        ON t.mediatypeid=m.mediatypeid 
    INNER JOIN genre g  
        ON g.genreid=t.genreid
ORDER BY m.name 


-----------------------------------------------------------------------------------------------

Which artist is most frequently purchased by those who also bought Miles Davis albums (excluding Miles Davis and Various Artists)?

SELECT a.name, COUNT(i.quantity) AS num_of_purchases
FROM artist a
    INNER JOIN album l 
        ON a.artistid = l.artistid
    INNER JOIN track t 
        ON l.albumid = t.albumid
    INNER JOIN invoiceline i 
        ON t.trackid = i.trackid
    INNER JOIN invoice n 
        ON i.invoiceid = n.invoiceid
WHERE n.customerid IN (SELECT n.customerid
                        FROM artist a
                        INNER JOIN album l ON a.artistid = l.artistid
                        INNER JOIN track t ON l.albumid = t.albumid
                        INNER JOIN invoiceline i ON t.trackid = i.trackid
                        INNER JOIN invoice n ON i.invoiceid = n.invoiceid
                        WHERE a.name = 'Miles Davis'
                        GROUP BY n.customerid
                        HAVING COUNT(i.quantity) >= 2) 
                        AND a.name NOT IN ('Miles Davis', 'Various Artists')                                             
GROUP BY a.name
ORDER BY num_of_purchases DESC
LIMIT 1


-----------------------------------------------------------------------------------------------

Create a ranking of customer support representatives (supportrepid), where the evaluation criterion is the highest non-zero turnover for a given month.
The query should return a table with the first name and last name of the employee of the month for each month of sales.

WITH ranking_employee_per_year_month AS (
    SELECT
        EXTRACT(YEAR FROM i.invoicedate) AS year,
        EXTRACT(MONTH FROM i.invoicedate) AS month,
        e.employeeid AS employee_of_the_month_id,
        e.firstname AS employee_of_the_month_first_name,
        e.lastname AS employee_of_the_month_last_name,
        SUM(i.total) AS sales_sum,
        DENSE_RANK() OVER (PARTITION BY EXTRACT(YEAR FROM i.invoicedate), EXTRACT(MONTH FROM i.invoicedate) ORDER BY SUM(i.total) DESC) AS ranking
    FROM employee e
        INNER JOIN customer c 
            ON e.employeeid = c.supportrepid
        INNER JOIN invoice i 
            ON c.customerid = i.customerid
    GROUP BY year, 
             month, 
             employee_of_the_month_id, 
             employee_of_the_month_first_name, 
             employee_of_the_month_last_name
)
SELECT
    year,
    month,
    employee_of_the_month_id,
    employee_of_the_month_first_name,
    employee_of_the_month_last_name,
    sales_sum
FROM ranking_employee_per_year_month
WHERE ranking = 1
ORDER BY year, month;


-----------------------------------------------------------------------------------------------

For each of the three sales representatives (supportrepid), indicate the months for which they recorded zero sales.
Utilize the appropriate window functions and an approach involving searching for gaps in the data.

WITH solution AS (
    SELECT DISTINCT
        c.supportrepid AS sales_representative,
        EXTRACT(YEAR FROM i.invoicedate) AS year,
        EXTRACT(MONTH FROM i.invoicedate) AS month,
        DENSE_RANK() OVER (PARTITION BY c.supportrepid, EXTRACT(YEAR FROM i.invoicedate) ORDER BY EXTRACT(MONTH FROM i.invoicedate)) AS row_num_per_id_date
    FROM customer c
    INNER JOIN invoice i 
        ON i.customerid = c.customerid
),
error_tracker AS (
    SELECT sales_representative, 
           year, 
           month, 
           row_num_per_id_date, 
           month - row_num_per_id_date AS error,
           DENSE_RANK() OVER (PARTITION BY sales_representative, year, month - row_num_per_id_date ORDER BY row_num_per_id_date) AS row_num_per_error
    FROM solution
    WHERE month - row_num_per_id_date != 0
)
SELECT sales_representative, 
       year, 
       month - 1 AS missing_month 
FROM error_tracker
WHERE row_num_per_error = 1
ORDER BY sales_representative, year, month;
