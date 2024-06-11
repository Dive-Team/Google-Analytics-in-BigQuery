/**
 * Sample query provided by Google for test GA4 ecommerce data
 * https://console.cloud.google.com/bigquery?p=bigquery-public-data&d=ga4_obfuscated_sample_ecommerce&t=events_20210131&page=table&project=df-warehouse&ws=!1m5!1m4!4m3!1sbigquery-public-data!2sga4_obfuscated_sample_ecommerce!3sevents_20210131
 */

SELECT
  COUNT(*) AS event_count,
  COUNT(DISTINCT user_pseudo_id) AS user_count,
  COUNT(DISTINCT event_date) AS day_count
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`