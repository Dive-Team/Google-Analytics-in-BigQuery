/**
 * Example of UNNEST inside of a subquery and spanning multiple dates
 */

SELECT
  event_date,
  (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = "page_location") AS page_location,
  COUNT(1) AS events
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE event_name = "page_view"
  AND _TABLE_SUFFIX > "20201201"
GROUP BY 1,2
ORDER BY event_date, events desc