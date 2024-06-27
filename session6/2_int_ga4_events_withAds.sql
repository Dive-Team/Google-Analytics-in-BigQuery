/**
 *  Update the Intermediate GA4 Events table created in session 3 on row 26
 */

WITH all_rows AS (
  SELECT 
    t1.* EXCEPT(engagement_time_msec, event_manual_campaign_name),
    t2.*,

    --Create unique keys
    TO_HEX(MD5(CONCAT(stream_id,user_pseudo_id,ga_session_id))) AS full_session_id,
    TO_HEX(MD5(CONCAT(user_pseudo_id,ga_session_id,event_name,event_timestamp,event_bundle_sequence_id))) as event_id,

    --Replace null engagement time with 0
    IFNULL(engagement_time_msec,0) AS engagement_time_msec,

    --Extract URL parameters
    REGEXP_EXTRACT(page_location, r'[?&]wbraid=([^&]+)') AS event_wbraid,
    REGEXP_EXTRACT(page_location, r'[?&]gbraid=([^&]+)') AS event_gbraid,
    REGEXP_EXTRACT(page_location, r'[?&]fbclid=([^&]+)') AS event_fbclid,

    --(optional) This is a great place to apply a custom content grouping

    --Get referring domain
    CASE WHEN event_manual_medium = "referral" THEN NET.REG_DOMAIN(event_manual_source) END AS referring_domain,

    --Import campaign dimensions from Google Ads
    COALESCE(SAFE_CAST(ads_campaigns.campaign_name AS STRING),t1.event_manual_campaign_name) AS event_manual_campaign_name,
    ads_campaigns.campaign_advertising_channel_type
    
  FROM `df-warehouse.df_warehouse_extras.sample_stg_ga4_events` t1
  JOIN `df-warehouse.df_warehouse_extras.sample_identity_graph` t2 ON t1.user_pseudo_id = t2.ig_user_pseudo_id
  LEFT JOIN `df-warehouse.df_warehouse_extras.sample_int_googleAds_campaigns` ads_campaigns ON t1.event_gclid = ads_campaigns.click_view_gclid
  WHERE t1.event_date = DATE "2024-06-09"
),

--Identify instances where the same event name was captured multiple times and then recorded in a single hit with the same timestamp
--Add a field to create unique event identifiers for each
add_row_num AS (
  SELECT * EXCEPT(ig_user_pseudo_id),
    ROW_NUMBER() OVER (PARTITION BY event_id ORDER BY event_timestamp ASC) AS event_number
  FROM all_rows
)

--Modify the event_id to include the event_num
--Number the events as they occurred sequentially
--Make the scroll event more useful by appending the percent scrolled
SELECT * EXCEPT(event_id,event_name),
  CONCAT(event_id,"_",event_number) AS event_id,
  ROW_NUMBER() OVER (PARTITION BY full_session_id ORDER BY event_timestamp ASC) AS session_event_number,
  ROW_NUMBER() OVER (PARTITION BY primary_user_id ORDER BY event_timestamp ASC) AS user_event_number,
  (CASE WHEN event_name = "scroll" THEN CONCAT("scroll_",percent_scrolled) ELSE event_name END) AS event_name
FROM add_row_num;