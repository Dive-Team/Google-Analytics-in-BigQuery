/**
 *  Calculates the first and last traffic source attributed to each session
 *  Applies last non-direct attribution to replicate the session/user scoped dimensions available in the GA4 user interface
 */

--Pull each session generated in the intermediate events table
--Pull manual traffic source attribution applied to each [simple last touch attribution]
WITH base_sessions_table AS (
  SELECT
    full_session_id,
    primary_user_id,
    ARRAY_AGG(referring_domain IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS referring_domain,
    MIN(event_timestamp) AS session_start,

    --User Attribution
    ARRAY_AGG(first_user_campaign IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS first_user_campaign,
    ARRAY_AGG(first_user_medium IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS first_user_medium,
    ARRAY_AGG(first_user_source IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS first_user_source,

    --Session First Source Attribution
    --Identify the first value for each traffic source dimension that was set during the session
    ARRAY_AGG(event_manual_source IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS session_manual_source,
    ARRAY_AGG(event_manual_medium IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS session_manual_medium,
    ARRAY_AGG(event_manual_term IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS session_manual_term,
    ARRAY_AGG(event_manual_content IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS session_manual_content,
    ARRAY_AGG(event_manual_campaign_id IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS session_manual_campaign_id,
    ARRAY_AGG(event_manual_campaign_name IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS session_manual_campaign_name,
    ARRAY_AGG(event_gclid IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS session_gclid,
    ARRAY_AGG(event_dclid IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS session_dclid,
    ARRAY_AGG(event_srsltid IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS session_srsltid,
    ARRAY_AGG(event_wbraid IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS session_wbraid,
    ARRAY_AGG(event_gbraid IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS session_gbraid,
    ARRAY_AGG(event_fbclid IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS session_fbclid,

    --Session Last Source Attribution
    --Identify the last value for each traffic source dimension that was set during the session
    ARRAY_AGG(event_manual_source IGNORE NULLS ORDER BY event_timestamp desc LIMIT 1)[SAFE_OFFSET(0)] AS last_session_manual_source,
    ARRAY_AGG(event_manual_medium IGNORE NULLS ORDER BY event_timestamp desc LIMIT 1)[SAFE_OFFSET(0)] AS last_session_manual_medium,
    ARRAY_AGG(event_manual_term IGNORE NULLS ORDER BY event_timestamp desc LIMIT 1)[SAFE_OFFSET(0)] AS last_session_manual_term,
    ARRAY_AGG(event_manual_content IGNORE NULLS ORDER BY event_timestamp desc LIMIT 1)[SAFE_OFFSET(0)] AS last_session_manual_content,
    ARRAY_AGG(event_manual_campaign_id IGNORE NULLS ORDER BY event_timestamp desc LIMIT 1)[SAFE_OFFSET(0)] AS last_session_manual_campaign_id,
    ARRAY_AGG(event_manual_campaign_name IGNORE NULLS ORDER BY event_timestamp desc LIMIT 1)[SAFE_OFFSET(0)] AS last_session_manual_campaign_name,
    ARRAY_AGG(event_gclid IGNORE NULLS ORDER BY event_timestamp desc LIMIT 1)[SAFE_OFFSET(0)] AS last_session_gclid,
    ARRAY_AGG(event_dclid IGNORE NULLS ORDER BY event_timestamp desc LIMIT 1)[SAFE_OFFSET(0)] AS last_session_dclid,
    ARRAY_AGG(event_srsltid IGNORE NULLS ORDER BY event_timestamp desc LIMIT 1)[SAFE_OFFSET(0)] AS last_session_srsltid,
    ARRAY_AGG(event_wbraid IGNORE NULLS ORDER BY event_timestamp desc LIMIT 1)[SAFE_OFFSET(0)] AS last_session_wbraid,
    ARRAY_AGG(event_gbraid IGNORE NULLS ORDER BY event_timestamp desc LIMIT 1)[SAFE_OFFSET(0)] AS last_session_gbraid,
    ARRAY_AGG(event_fbclid IGNORE NULLS ORDER BY event_timestamp desc LIMIT 1)[SAFE_OFFSET(0)] AS last_session_fbclid
  FROM `df-warehouse.df_warehouse_intermediate.int_ga4_events`
  GROUP BY 1,2
),

--Create last click attribution struct
--Apply logic to adjust values as needed
add_last_click_attribution AS (
  SELECT *,
    --Create a STRUCT to identify the first traffic source that was identified during the session
    CASE 
      
      --Correct error in BigQuery that attributes cpc to organic search for session attribution dimensions
      WHEN (session_gclid IS NOT NULL OR session_wbraid IS NOT NULL OR session_gbraid IS NOT NULL) 
        THEN STRUCT('google' AS session_manual_source, 'cpc' AS session_manual_medium, session_manual_campaign_name AS session_manual_campaign_name)  
      
      --Set unwanted referrals to direct
      WHEN referring_domain IN ("00000000.com,test.com") 
        THEN STRUCT('(direct)' AS session_manual_source, '(none)' AS session_manual_medium, '(not set)' AS session_manual_campaign_name)
      
      --If the event-scoped traffic source parameters are not null, apply them
      WHEN COALESCE(session_manual_source, session_manual_medium, session_manual_campaign_name) IS NOT NULL 
        THEN STRUCT(session_manual_source AS session_manual_source, session_manual_medium AS session_manual_medium, session_manual_campaign_name AS session_manual_campaign_name)
      
      --Default everything else to direct (including "unassigned")
      ELSE STRUCT('(direct)' AS session_manual_source, '(none)' AS session_manual_medium, '(not set)' AS session_manual_campaign_name)
    END AS last_click_attribution,

    --Create a STRUCT to identify the last traffic source that was identified during the session (if more than one were set)
    CASE 
      WHEN (last_session_gclid IS NOT NULL OR last_session_wbraid IS NOT NULL OR last_session_gbraid IS NOT NULL) 
        THEN STRUCT('google' AS session_manual_source, 'cpc' AS session_manual_medium, last_session_manual_campaign_name AS session_manual_campaign_name) 
    
      --If the event-scoped traffic source parameters are not null, apply them
      WHEN COALESCE(last_session_manual_source, last_session_manual_medium, last_session_manual_campaign_name) IS NOT NULL 
        THEN STRUCT(last_session_manual_source AS session_manual_source, last_session_manual_medium AS session_manual_medium, last_session_manual_campaign_name AS session_manual_campaign_name)
      
      --Default everything else to NULL
      ELSE NULL
    
    END AS last_nondirect_attribution,
  FROM base_sessions_table 
),

--Create last non-direct click attribution dimension to match the GA4 user interface
--Where a session is set to direct, search the prior 90 days for a non-direct traffic source to replace the current information
add_last_non_direct AS (
  SELECT *,
    IF(last_click_attribution.session_manual_medium = '(not set)',
      LAST_VALUE(last_nondirect_attribution IGNORE NULLS) OVER(
        PARTITION BY primary_user_id ORDER BY UNIX_SECONDS(session_start)
        RANGE BETWEEN 7776000 PRECEDING AND 1 PRECEDING),last_click_attribution -- Check prior 90 days for the last non-direct session attribution
    ) AS last_non_direct_attribution,
  FROM add_last_click_attribution
)

SELECT *
FROM add_last_non_direct