/**
 * Example of UNNEST inside of a subquery
 */

SELECT
  (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = "page_location") AS page_location,
  COUNT(1) AS events
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201201`
WHERE event_name = "page_view"
GROUP BY 1
ORDER BY events desc