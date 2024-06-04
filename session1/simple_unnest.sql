/**
 * Simple example of UNNEST
 */

SELECT
  CASE WHEN ep.key = "page_location" THEN ep.value.string_value END AS page_location,
  COUNT(1) AS events
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201201`, UNNEST(event_params) ep
WHERE event_name = "page_view"
GROUP BY 1
ORDER BY events desc