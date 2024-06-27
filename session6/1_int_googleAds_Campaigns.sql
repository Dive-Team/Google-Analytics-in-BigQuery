/**
 *  Extracts dimensions that describe each campaign from the ads_Campaign_<customer id> view in the Google Ads data transfer
 */

--Pull Google Ads campaign names by gclid 
WITH clickStats AS (
  SELECT 
    click_view_gclid,
    campaign_id
  FROM `df-warehouse.df_warehouse_extras.sample_ads_ClickStats`
)

--Extract dimensions for each campaign
SELECT
  clickStats.campaign_id,
  clickStats.click_view_gclid,
  SAFE_CAST(LOWER(ads_campaigns.campaign_name) AS STRING) AS campaign_name,
  ads_campaigns.campaign_advertising_channel_type,
  ads_campaigns.customer_id 
FROM clickStats
LEFT JOIN `df-warehouse.df_warehouse_extras.sample_ads_Campaign` ads_campaigns ON clickStats.campaign_id = ads_campaigns.campaign_id
WHERE ads_campaigns._DATA_DATE = ads_campaigns._LATEST_DATE
  AND ads_campaigns.campaign_status != "PAUSED"
GROUP BY ALL