/**
 *  Calculate the key metrics over the prior 30 days for each Google Ads campaign
 *  Since the sample GA4 data provided by Google does not have a corresponding Google Ads export, this query will return no results
 *  See this table for an example of the output: df-warehouse.df_warehouse_extras.sample_ads_30_day_performance
 */

WITH clickStats AS (
  SELECT 
    click_view_gclid,
    campaign_id
  FROM `df-warehouse.df_warehouse_extras.sample_ads_ClickStats`
),

google_analytics AS (
  SELECT 
    session_campaign_name,
    clickStats.campaign_id,
    COUNT(DISTINCT primary_user_id) AS users,
    COUNT(DISTINCT full_session_id) AS sessions
  FROM `df-warehouse.df_warehouse_extras.sample_output_ga4_sessions` 
  LEFT JOIN clickStats ON session_gclid = clickStats.click_view_gclid
  WHERE session_date BETWEEN DATE_ADD(CURRENT_DATE(), INTERVAL -31 DAY) AND DATE_ADD(CURRENT_DATE(), INTERVAL -1 DAY)
  GROUP BY ALL
),

analytics_enriched AS (
  SELECT
    LOWER(COALESCE(SAFE_CAST(ads_campaigns.campaign_name AS STRING),session_campaign_name)) AS campaign_name,
    google_analytics.campaign_id,
    ads_campaigns.campaign_advertising_channel_type,
    ads_campaigns.customer_id,
    SUM(google_analytics.users) AS users,
    SUM(google_analytics.sessions) AS sessions
  FROM google_analytics
  LEFT JOIN `df-warehouse.df_warehouse_extras.sample_ads_Campaign` ads_campaigns ON google_analytics.campaign_id = ads_campaigns.campaign_id
  WHERE ads_campaigns._DATA_DATE = ads_campaigns._LATEST_DATE
    AND ads_campaigns.campaign_status != "PAUSED"
  GROUP BY ALL
)

SELECT
  ga.customer_id,
  ga.campaign_advertising_channel_type,
  ga.campaign_name,
  ga.sessions AS last_touch_sessions,
  ga.users AS last_touch_users,
  SUM(cs.metrics_impressions) AS impressions,
  SUM(cs.metrics_interactions) AS interactions,
  SUM(cs.metrics_clicks) AS clicks,
  ROUND((SUM(cs.metrics_cost_micros) / 1000000),2) AS cost
FROM analytics_enriched ga
LEFT JOIN `df-warehouse.df_warehouse_extras.sample_ads_CampaignBasicStats` cs
  ON (ga.campaign_id = cs.campaign_id AND cs._DATA_DATE BETWEEN DATE_ADD(CURRENT_DATE(), INTERVAL -31 DAY) AND DATE_ADD(CURRENT_DATE(), INTERVAL -1 DAY) )
GROUP BY ALL