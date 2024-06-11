  /**
 *  Create a field to replicate GA4's user id behavior
 *  Create a primary_user_id that is:  
    user_id,
    the first non-null user_id after the current event,
    user_pseudo_id 
 */


SELECT
  user_pseudo_id,
  COALESCE(
      user_id, 
      FIRST_VALUE(user_id IGNORE NULLS) OVER (PARTITION BY CONCAT(stream_id,user_pseudo_id,ga_session_id) ORDER BY event_timestamp ASC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING),
      user_pseudo_id
    ) AS primary_user_id
FROM
  `df-warehouse.df_warehouse_extras.sample_stg_ga4_events`