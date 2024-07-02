/**
 *  Create session-scoped segments from output tables
 */

-- Create session-scoped segments from event attributes
WITH segments_from_events AS (
  SELECT
    full_session_id,
    LOGICAL_OR(CASE WHEN REGEXP_CONTAINS(page_location, 'ordercompleted') THEN TRUE ELSE FALSE END) AS sessionSegment_viewed_thankyou_page
  FROM `df-warehouse.df_warehouse_output.output_ga4_events`
  GROUP BY 1
),

-- Create segments from session attributes
segments_from_sessions AS (
  SELECT
    full_session_id,
    LOGICAL_OR(country != "United States") AS sessionSegment_outsideUnitedStates
  FROM `df-warehouse.df_warehouse_output.output_ga4_sessions`
  GROUP BY 1
),

-- Create segments that use combinations of the segments above
combined_segments AS (
  SELECT 
    full_session_id,
    LOGICAL_OR(CASE WHEN(sessionSegment_viewed_thankyou_page AND sessionSegment_outsideUnitedStates) THEN TRUE ELSE FALSE END) AS sessionSegment_outsideUS_viewedThankyou,
  FROM segments_from_events
    JOIN segments_from_sessions USING (full_session_id)
  GROUP BY 1)

SELECT *
FROM segments_from_events
  JOIN segments_from_sessions USING (full_session_id)
  JOIN combined_segments USING (full_session_id)