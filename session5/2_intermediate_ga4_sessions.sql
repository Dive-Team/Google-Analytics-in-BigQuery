/**
 *  Consolidates all session-scoped attributes
 *  Calculates session-scoped attributes from the intermediate events table
 */


WITH base_sessions_table AS (
  SELECT
    intermediate_events.full_session_id,
    intermediate_events.primary_user_id,
    MAX(session_attribution.referring_domain) AS referring_domain,
    MAX(session_attribution.session_start) AS session_start,
    MAX(is_active_user) AS is_active_user,
    ARRAY_AGG(event_date IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS session_date,
    ARRAY_AGG(user_id IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS user_id,
    ARRAY_AGG(ga_session_number IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS ga_session_number,
    ARRAY_AGG(page_location IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS landing_page,
    ARRAY_AGG(page_title IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS landing_page_title,
    MAX(event_timestamp) AS session_end,
    TIMESTAMP_DIFF(MAX(event_timestamp), MIN(event_timestamp), SECOND) AS session_duration,
    IF(
      SUM(CASE WHEN event_name = "page_view" OR event_name = "screen_view" THEN 1 END) > 1
      OR (SUM(engagement_time_msec) >= 10000)
      OR LOGICAL_OR(is_conversion_event = TRUE), "1", "0") AS session_engaged,
    COUNTIF(is_conversion_event = TRUE) as total_conversions,    

    --Traffic Source Attribution
    MAX(session_attribution.first_user_campaign) AS first_user_campaign,
    MAX(session_attribution.first_user_medium) AS first_user_medium,
    MAX(session_attribution.first_user_source) AS first_user_source,
    MAX(session_attribution.last_non_direct_attribution.session_manual_source) AS session_source,
    MAX(session_attribution.last_non_direct_attribution.session_manual_medium) AS session_medium,
    MAX(session_attribution.session_manual_term) AS session_term,
    MAX(session_attribution.session_manual_content) AS session_content,
    MAX(session_attribution.session_manual_campaign_id) AS session_campaign_id,
    MAX(session_attribution.last_non_direct_attribution.session_manual_campaign_name) AS session_campaign_name,
    MAX(session_attribution.session_gclid) AS session_gclid,
    MAX(session_attribution.session_dclid) AS session_dclid,
    MAX(session_attribution.session_srsltid) AS session_srsltid, 
    MAX(session_attribution.session_wbraid) AS session_wbraid, 
    MAX(session_attribution.session_gbraid) AS session_gbraid, 
    MAX(session_attribution.session_fbclid) AS session_fbclid, 

    --Geographic Attributes
    ARRAY_AGG(country IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS country,
    ARRAY_AGG(city IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS city,
    ARRAY_AGG(metro IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS metro,
    ARRAY_AGG(region IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS region,
    ARRAY_AGG(sub_continent IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS sub_continent,
    ARRAY_AGG(continent IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS continent,
    
    --Device Attributes
    ARRAY_AGG(device_category IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS device_category,
    ARRAY_AGG(device_language IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS device_language, 
    ARRAY_AGG(mobile_brand_name IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS mobile_brand_name,
    ARRAY_AGG(mobile_model_name IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS mobile_model_name,
    ARRAY_AGG(mobile_marketing_name IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS mobile_marketing_name,
    ARRAY_AGG(mobile_os_hardware_model IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS mobile_os_hardware_model,
    ARRAY_AGG(operating_system IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS operating_system,
    ARRAY_AGG(operating_system_version IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS operating_system_version,
    ARRAY_AGG(vendor_id IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS vendor_id,
    ARRAY_AGG(advertising_id IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS advertising_id,
    ARRAY_AGG(is_limited_ad_tracking IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS is_limited_ad_tracking,
    ARRAY_AGG(browser IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS browser,
    ARRAY_AGG(browser_version IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS browser_version,
    ARRAY_AGG(platform IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS platform,
    
    --Insert Custom Session-Scoped Dimensions Here
    --LOGICAL_OR(CASE WHEN REGEXP_CONTAINS(page_location, '/demo') THEN TRUE ELSE FALSE END) AS viewed_demo_page

  FROM `df-warehouse.df_warehouse_intermediate.int_ga4_events` intermediate_events
    JOIN `df-warehouse.df_warehouse_intermediate.int_ga4_session_attribution` session_attribution ON intermediate_events.full_session_id = session_attribution.full_session_id
  WHERE intermediate_events.event_date BETWEEN PARSE_DATE("%Y%m%d","20201101") AND PARSE_DATE("%Y%m%d","20201107")
  GROUP BY 1,2
),
       
--Select final result from the last processing step
final_processing AS (
  SELECT *,
    IF(ga_session_number > 1,"Returning","New") AS session_type,
    --Insert custom channel grouping here
    CASE 
            WHEN (session_source = 'direct' OR session_source = '(direct)' OR session_source is null) 
                AND (REGEXP_CONTAINS(session_medium, r'^((not set)|(none))$') OR session_medium is null) 
                THEN 'Direct'
            WHEN REGEXP_CONTAINS(session_campaign_name, 'cross-network') THEN 'Cross-network'
            WHEN (REGEXP_CONTAINS(session_source,'alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart')
                OR REGEXP_CONTAINS(session_campaign_name, '^(.*(([^a-df-z]|^)shop|shopping).*)$'))
                AND REGEXP_CONTAINS(session_medium, '^(.*cp.*|ppc|paid.*)$') THEN 'Paid Shopping'
            WHEN REGEXP_CONTAINS(session_source,'baidu|bing|duckduckgo|ecosia|google|yahoo|yandex')
                AND REGEXP_CONTAINS(session_medium,'^(.*cp.*|ppc|paid.*)$') THEN 'Paid Search'
            WHEN REGEXP_CONTAINS(session_source,'badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp')
                AND REGEXP_CONTAINS(session_medium,'^(.*cp.*|ppc|paid.*)$') THEN 'Paid Social'
            WHEN REGEXP_CONTAINS(session_source,'dailymotion|disneyplus|netflix|youtube|vimeo|twitch|vimeo|youtube')
                AND REGEXP_CONTAINS(session_medium,'^(.*cp.*|ppc|paid.*)$') THEN 'Paid Video'
            WHEN session_medium in ('display', 'banner', 'expandable', 'interstitial', 'cpm') THEN 'Display'
            WHEN REGEXP_CONTAINS(session_source,'alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart')
                OR REGEXP_CONTAINS(session_campaign_name, '^(.*(([^a-df-z]|^)shop|shopping).*)$') THEN 'Organic Shopping'
            WHEN REGEXP_CONTAINS(session_source,'badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp')
                OR session_medium in ('social','social-network','social-media','sm','social network','social media') THEN 'Organic Social'
            WHEN REGEXP_CONTAINS(session_source,'dailymotion|disneyplus|netflix|youtube|vimeo|twitch|vimeo|youtube')
                OR REGEXP_CONTAINS(session_medium,'^(.*video.*)$') THEN 'Organic Video'
            WHEN REGEXP_CONTAINS(session_source,'baidu|bing|duckduckgo|ecosia|google|yahoo|yandex')
                OR session_medium = 'organic' THEN 'Organic Search'
            WHEN REGEXP_CONTAINS(session_source,'email|e-mail|e_mail|e mail')
                OR REGEXP_CONTAINS(session_medium,'email|e-mail|e_mail|e mail') THEN 'Email'
            WHEN session_medium = 'affiliate' THEN 'Affiliates'
            WHEN session_medium = 'referral' THEN 'Referral'
            WHEN session_medium = 'audio' THEN 'Audio'
            WHEN session_medium = 'sms' THEN 'SMS'
            WHEN session_medium like '%push'
                OR REGEXP_CONTAINS(session_medium,'mobile|notification') THEN 'Mobile Push Notifications'
            ELSE 'Unassigned'
        END AS session_default_channel_grouping
  FROM base_sessions_table
)

SELECT *
FROM final_processing