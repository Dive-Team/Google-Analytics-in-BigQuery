/**
 *  Creates the Output Table for Pathing Analysis
 *  This table builds on the output from session3/3_intermediate_ga4_events.sql
 */

WITH event_properties AS (
  SELECT
    event_id,
    full_session_id,
    primary_user_id,
    event_timestamp,
    page_location,
    page_title,
    ROW_NUMBER() OVER (PARTITION BY full_session_id ORDER BY event_timestamp ASC) AS session_view_number --Order events within each session by timestamp
  FROM `df-warehouse.df_warehouse_intermediate.int_ga4_events`
  WHERE event_name IN ('page_view','screen_view')
  AND event_date = PARSE_DATE("%Y%m%d","20201101")
)

SELECT *,
  IFNULL(LAG(page_location) 
    OVER( PARTITION BY full_session_id ORDER BY session_view_number ASC),"ENTRANCE") AS prior_page_location,
  IFNULL(LAG(page_title) 
    OVER( PARTITION BY full_session_id ORDER BY session_view_number ASC), "ENTRANCE") AS prior_page_title,
  IFNULL(LEAD(page_location) 
    OVER( PARTITION BY full_session_id ORDER BY session_view_number ASC), "EXIT") AS next_page_location,
  IFNULL(LEAD(page_title) 
    OVER( PARTITION BY full_session_id ORDER BY session_view_number ASC), "EXIT") AS next_page_title,
FROM event_properties
ORDER BY full_session_id