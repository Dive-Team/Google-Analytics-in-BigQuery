/**
 *  GA4 Intermediate Users table
 *  Creates a series of user attributes from the intermediate events table, aggregated by primary_user_id
 */


SELECT
  primary_user_id,

  --Standard User Attributes
  ARRAY_AGG(user_id IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS user_id,
  MIN(DATE(user_first_touch_timestamp, "America/New_York")) AS first_session_date,
  MAX(DATE(event_timestamp, "America/New_York")) AS most_recent_session_date,

  --Privacy Settings
  ARRAY_AGG(analytics_storage IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS analytics_storage,
  ARRAY_AGG(ads_storage IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS ads_storage,
  ARRAY_AGG(uses_transient_token IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS uses_transient_token,

  --Acquisition Source
  ARRAY_AGG(first_user_campaign IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS first_user_campaign,
  ARRAY_AGG(first_user_medium IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS first_user_medium,
  ARRAY_AGG(first_user_source IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS first_user_source,
  ARRAY_AGG(user_first_touch_timestamp IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS user_first_touch_timestamp,

  --Most Recent Device
  ARRAY_AGG(device_category IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_device_category,
  ARRAY_AGG(mobile_brand_name IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_device_mobile_brand_name,
  ARRAY_AGG(mobile_model_name IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_device_mobile_model_name,
  ARRAY_AGG(mobile_marketing_name IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_device_mobile_marketing_name,
  ARRAY_AGG(mobile_os_hardware_model IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_device_mobile_os_hardware_model,
  ARRAY_AGG(operating_system IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_device_operating_system,
  ARRAY_AGG(operating_system_version IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_device_operating_system_version,
  ARRAY_AGG(vendor_id IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_device_vendor_id,
  ARRAY_AGG(advertising_id IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_device_advertising_id,
  ARRAY_AGG(device_language IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_device_language,
  ARRAY_AGG(is_limited_ad_tracking IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_device_is_limited_ad_tracking,
  ARRAY_AGG(browser IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_device_browser,
  ARRAY_AGG(browser_version IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_device_browser_version,
  ARRAY_AGG(hostname IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_device_hostname,

  --Most Recent Geo Info
  ARRAY_AGG(city IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_geo_city,
  ARRAY_AGG(metro IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_geo_metro,
  ARRAY_AGG(region IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_geo_region,
  ARRAY_AGG(country IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_geo_country,
  ARRAY_AGG(sub_continent IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_geo_sub_continent,
  ARRAY_AGG(continent IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_geo_continent,

  --Most Recent Mobile App Info
  ARRAY_AGG(app_id IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_appInfo_id,
  ARRAY_AGG(app_version IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_appInfo_version,
  ARRAY_AGG(install_store IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_appInfo_install_store,
  ARRAY_AGG(firebase_app_id IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_appInfo_firebase_app_id,
  ARRAY_AGG(install_source IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS most_recent_appInfo_install_source,

  --Enhanced Measurement Engagement Metrics
  SUM(CASE WHEN event_name IN ("page_view","screen_view") THEN 1 ELSE 0 END) AS total_views,
  ARRAY_AGG(ltv_revenue IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS lifetime_revenue,
  COUNT(1) AS total_events,
  SUM(IFNULL(engagement_time_msec,0)) AS total_engagement_time,
  SUM(CASE WHEN event_name = 'session_start' THEN 1 ELSE 0 END) AS total_sessions,
  MAX(ga_session_number) AS lifetime_sessions,
  SUM(CASE WHEN event_name = 'click' THEN 1 ELSE 0 END) AS total_clicks,
  SUM(CASE WHEN event_name = 'scroll' THEN 1 ELSE 0 END) AS total_scrolls,
  SUM(CASE WHEN event_name = 'view_search_results' THEN 1 ELSE 0 END) AS total_internal_searches,
  SUM(CASE WHEN event_name = 'video_start' THEN 1 ELSE 0 END) AS total_videos_started,
  SUM(CASE WHEN event_name = 'video_complete' THEN 1 ELSE 0 END) AS total_videos_completed,
  SUM(CASE WHEN event_name = 'file_download' THEN 1 ELSE 0 END) AS total_files_downloaded,
  SUM(CASE WHEN event_name = 'form_start' THEN 1 ELSE 0 END) AS total_forms_started,
  SUM(CASE WHEN event_name = 'form_submit' THEN 1 ELSE 0 END) AS total_forms_submited,

  --Ecommerce Engagement Metrics
  SUM(CASE WHEN event_name = 'view_item_list' THEN 1 ELSE 0 END) AS total_item_lists_viewed,
  SUM(CASE WHEN event_name = 'select_item' THEN 1 ELSE 0 END) AS total_items_selected,
  SUM(CASE WHEN event_name = 'view_item' THEN 1 ELSE 0 END) AS total_items_viewed,
  SUM(CASE WHEN event_name = 'add_to_cart' THEN 1 ELSE 0 END) AS total_adds_to_cart,
  SUM(CASE WHEN event_name = 'add_to_wishlist' THEN 1 ELSE 0 END) AS total_adds_to_wishlist,
  SUM(CASE WHEN event_name = 'view_cart' THEN 1 ELSE 0 END) AS total_carts_viewed,
  SUM(CASE WHEN event_name = 'remove_from_cart' THEN 1 ELSE 0 END) AS total_removes_from_cart,
  SUM(CASE WHEN event_name = 'begin_checkout' THEN 1 ELSE 0 END) AS total_checkouts_started,
  SUM(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS total_purchases,
  SUM(CASE WHEN event_name = 'refund' THEN 1 ELSE 0 END) AS total_refunds,
  SUM(CASE WHEN event_name = 'view_promotion' THEN 1 ELSE 0 END) AS total_promos_viewed,
  SUM(CASE WHEN event_name = 'select_promotion' THEN 1 ELSE 0 END) AS total_promos_selected,

  --Suggested Events
  SUM(CASE WHEN event_name = 'generate_lead' THEN 1 ELSE 0 END) AS total_leads_generated,
  SUM(CASE WHEN event_name = 'login' THEN 1 ELSE 0 END) AS total_logins,
  SUM(CASE WHEN event_name = 'search' THEN 1 ELSE 0 END) AS total_searches,
  SUM(CASE WHEN event_name = 'share' THEN 1 ELSE 0 END) AS total_shares,
  SUM(CASE WHEN event_name = 'sign_up' THEN 1 ELSE 0 END) AS total_signups,
  SUM(CASE WHEN event_name = 'tutorial_begin' THEN 1 ELSE 0 END) AS total_tutorials_started,
  SUM(CASE WHEN event_name = 'tutorial_complete' THEN 1 ELSE 0 END) AS total_tutorials_completed,
  SUM(CASE WHEN event_name = 'spend_virtual_currency' THEN 1 ELSE 0 END) AS total_virtual_currency_spends,
  SUM(CASE WHEN event_name = 'earn_virtual_currency' THEN 1 ELSE 0 END) AS total_virtual_currency_earns,

  --OPTIONAL: Add custom engagement metrics
  SUM(CASE WHEN event_name = "page_view" AND REGEXP_CONTAINS(page_location,"/example") THEN 1 ELSE 0 END) AS total_example_pages_viewed,

  --OPTIONAL: Add Custom User Properties

  --OPTIONAL: Add Demandbase attributes if the integration exists
  ARRAY_AGG(demandbase_audience IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS demandbase_audience,
  ARRAY_AGG(demandbase_city IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS demandbase_city,
  ARRAY_AGG(demandbase_company_sid IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS demandbase_company_sid,
  ARRAY_AGG(demandbase_company_name IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS demandbase_company_name,
  ARRAY_AGG(demandbase_employee_range IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS demandbase_employee_range,
  ARRAY_AGG(demandbase_industry IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS demandbase_industry,
  ARRAY_AGG(demandbase_marketing_alias IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS demandbase_marketing_alias,
  ARRAY_AGG(demandbase_revenue_range IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS demandbase_revenue_range,
  ARRAY_AGG(demandbase_state IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS demandbase_state,
  ARRAY_AGG(demandbase_sub_industry IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS demandbase_sub_industry,
  ARRAY_AGG(demandbase_web_site IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS demandbase_web_site,
  ARRAY_AGG(demandbase_country_name IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS demandbase_country_name,

FROM --Insert the ID of your intermediate GA4 events table
GROUP BY 1