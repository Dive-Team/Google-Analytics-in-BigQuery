/**
 *  Create the primary_user_id field
 *  Identify the most recent user_id that has been set with each device
 */

--Identify the most recent user_id that was set on each device
WITH graph AS (
    SELECT
        user_pseudo_id,
        ARRAY_AGG(user_id IGNORE NULLS ORDER BY event_timestamp DESC LIMIT 1)[SAFE_OFFSET(0)] AS user_id,
        COUNT(DISTINCT user_id) AS shared_users
    FROM `df-warehouse.df_warehouse_extras.sample_stg_ga4_events`
    GROUP BY 1
)

--Set the most recent user_id used on each device to the primary_user_id
--If no user_id has been set on a device, have the primary_user_id fall back to the user_pseudo_id
SELECT
    user_pseudo_id AS ig_user_pseudo_id,
    COALESCE(user_id,user_pseudo_id) AS primary_user_id,
    shared_users
FROM graph
ORDER BY shared_users DESC