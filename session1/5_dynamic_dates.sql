/**
 * Example of a dynamic date range based on the current date
 */

SELECT
  event_date,
  (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = "page_location") AS page_location,
  COUNT(1) AS events
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE event_name = "page_view"
  AND _TABLE_SUFFIX > FORMAT_DATE("%Y%m%d", DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
GROUP BY 1,2
ORDER BY event_date, events desc
