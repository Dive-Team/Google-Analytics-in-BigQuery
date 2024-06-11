/**
 *  Create a simple identity graph
 *  Identify the most recent user_id that has been set with each device
 */

SELECT
    user_pseudo_id,
    ARRAY_AGG(user_id IGNORE NULLS ORDER BY event_timestamp DESC LIMIT 1)[SAFE_OFFSET(0)] AS user_id,
    COUNT(DISTINCT user_id) AS shared_users
FROM `df-warehouse.df_warehouse_extras.sample_stg_ga4_events`
GROUP BY 1
--HAVING shared_users > 1 -- Remove comment to view devices shared by multiple users


-- -- Alternate version with no ARRAY_AGG
-- WITH user_ids AS (
--     SELECT
--         user_pseudo_id,
--         user_id,
--         max(event_timestamp) as max_event_timestamp
--     FROM `df-warehouse.df_warehouse_extras.sample_stg_ga4_events`
--     GROUP BY 1, 2
-- )

-- SELECT
--     user_pseudo_id AS ig_user_pseudo_id,
--     user_id AS primary_user_id,
-- FROM user_ids
-- QUALIFY RANK() OVER (PARTITION BY user_pseudo_id ORDER BY max_event_timestamp DESC) = 1
