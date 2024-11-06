--Take a look at the raw data
SELECT *
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201117`
WHERE event_name = "page_view"
LIMIT 1

--Explore how UNNEST applies a cross join
--Every key creates a new row
SELECT
  event_params
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201117`, UNNEST(event_params) AS event_params
WHERE event_name = "page_view"


--Select * with event_params UNNESTED
--See how the results split a single event into multiple rows with repeated values in the columns
SELECT *,
  event_params
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201117`, UNNEST(event_params) AS event_params
WHERE event_name = "page_view"

--Create a top pages report
--Drop all rows except those with the event_param key set to "page_location"
SELECT
  event_params
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201117`, UNNEST(event_params) AS event_params
WHERE event_name = "page_view"
  AND event_params.key = "page_location"

--Create a top pages report with multiple parameters using a subselect
--The subselect creates a little table, and then digs into it to extract the items you want
SELECT
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = "page_location") AS page_location,
  COUNT(1) AS page_views
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201117`
GROUP BY 1
ORDER BY 2 desc