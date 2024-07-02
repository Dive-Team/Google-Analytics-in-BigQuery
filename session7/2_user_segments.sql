/**
 *  Create user-scoped segments from output tables
 */

-- Create user-scoped segments from event attributes
WITH segments_from_events AS (
  SELECT
    primary_user_id,
    IF(SUM(CASE WHEN event_name IN ("page_view","screen_view") THEN 1 ELSE 0 END) > 2,TRUE,FALSE) AS userSegment_three_plus_pageviews
  FROM `df-warehouse.df_warehouse_output.output_ga4_events`
  GROUP BY 1
),

-- Create segments from session attributes
segments_from_sessions AS (
  SELECT
    primary_user_id,
    LOGICAL_OR(session_medium="cpc") AS userSegment_visitedFromCPC
  FROM 
    `df-warehouse.df_warehouse_output.output_ga4_sessions`
  GROUP BY 1
),

-- Create segments from user attributes
segments_from_users AS (
  SELECT
    primary_user_id,
    LOGICAL_OR(CASE WHEN total_adds_to_cart > 0 THEN TRUE ELSE FALSE END) AS userSegment_addedItemsToCart
  FROM `df-warehouse.df_warehouse_output.output_ga4_users`
  GROUP BY 1
),

-- Create segments that use combinations of the segments above
combined_segments AS (
  SELECT 
    primary_user_id,
    LOGICAL_OR(CASE WHEN(userSegment_three_plus_pageviews OR userSegment_addedItemsToCart) THEN TRUE ELSE FALSE END) AS userSegment_threePageviews_orAddsToCart
  FROM segments_from_events
    JOIN segments_from_users USING (primary_user_id)
  GROUP BY 1)

SELECT *
FROM segments_from_events
  JOIN segments_from_sessions USING (primary_user_id)
  JOIN segments_from_users USING (primary_user_id)
  JOIN combined_segments USING (primary_user_id)