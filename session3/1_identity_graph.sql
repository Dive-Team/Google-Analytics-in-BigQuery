/**
 *  Create a simple identity graph
 *  Identify the most recent user_id that has been set with each device
 */

SELECT
    user_pseudo_id,
    ARRAY_AGG(user_id IGNORE NULLS ORDER BY event_timestamp DESC LIMIT 1)[SAFE_OFFSET(0)] AS user_id,
    COUNT(DISTINCT user_id) AS shared_users
FROM `df-warehouse.df_warehouse_extras.sample_stg_ga4_events` --A flat events table that has been obfuscated and shared publically
GROUP BY 1
--HAVING shared_users > 1 -- Remove comment to view devices shared by multiple users