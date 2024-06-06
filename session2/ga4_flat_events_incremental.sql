/**
 * Converts the denormalized GA4 tables into a single flattened events partitioned by event_date
 * Incrementally refreshes the prior 4 days of data only
 */

DECLARE event_date_checkpoint DEFAULT (
  SELECT date("2020-01-01")
);

--Set fields to null to avoid errors on old tables where this field didn't exist
DECLARE is_active_user BOOL DEFAULT NULL;
DECLARE collected_traffic_source STRUCT<
    manual_campaign_id STRING,
    manual_campaign_name STRING,
    manual_source STRING,
    manual_medium STRING,
    manual_term STRING,
    manual_content STRING,
    gclid STRING,
    dclid STRING,
    srsltid STRING> DEFAULT NULL; 

--Set the checkpoint. All data after will be deleted and refreshed.
SET event_date_checkpoint = (
  SELECT
      LEAST(
        (SELECT date_sub(current_date(), INTERVAL 4 DAY)),
        (SELECT max(event_date) from `df-warehouse.df_warehouse_extras.test`)
      )
);

DELETE `df-warehouse.df_warehouse_extras.test` WHERE event_date > event_date_checkpoint;

CREATE OR REPLACE TABLE
  df_warehouse_extras.test

PARTITION BY
  event_date
AS (

    WITH unnested_events AS (
    SELECT
        user_pseudo_id,
        stream_id,
        event_name,
        event_bundle_sequence_id,
        TIMESTAMP_MICROS(event_timestamp) AS event_timestamp,
        DATE(TIMESTAMP_MICROS(event_timestamp), "America/New_York") AS event_date, --Convert from UTC to the timestamp you prefer
        event_server_timestamp_offset,
        user_id,
        privacy_info.analytics_storage,
        privacy_info.ads_storage,
        privacy_info.uses_transient_token,
        TIMESTAMP_MICROS(user_first_touch_timestamp) AS user_first_touch_timestamp,
        user_ltv.revenue AS ltv_revenue,
        user_ltv.currency AS ltv_currency,
        device.category AS device_category,
        device.mobile_brand_name,
        device.mobile_model_name,
        device.mobile_marketing_name,
        device.mobile_os_hardware_model,
        device.operating_system,
        device.operating_system_version,
        device.vendor_id,
        device.advertising_id,
        device.language AS device_language,
        device.is_limited_ad_tracking,
        device.web_info.browser,
        device.web_info.browser_version,
        geo.city,
        geo.metro,
        geo.region,
        geo.country,
        geo.sub_continent,
        geo.continent,
        app_info.id AS app_id,
        app_info.version AS app_version,
        app_info.install_store,
        app_info.firebase_app_id,
        app_info.install_source,
        LOWER(traffic_source.name) AS first_user_campaign,
        LOWER(traffic_source.medium) AS first_user_medium,
        LOWER(traffic_source.source) AS first_user_source,
        platform,
        ecommerce.total_item_quantity,
        ecommerce.purchase_revenue_in_usd,
        ecommerce.purchase_revenue,
        ecommerce.refund_value_in_usd,
        ecommerce.refund_value,
        ecommerce.shipping_value_in_usd,
        ecommerce.shipping_value,
        ecommerce.tax_value_in_usd,
        ecommerce.tax_value,
        ecommerce.unique_items,
        ecommerce.transaction_id AS ecommerce_transaction_id,
        (SELECT AS STRUCT 
        collected_traffic_source.manual_campaign_id AS manual_campaign_id,
        lower(collected_traffic_source.manual_campaign_name) AS manual_campaign_name,
        lower(collected_traffic_source.manual_source) AS manual_source,
        lower(collected_traffic_source.manual_medium) AS manual_medium,
        lower(collected_traffic_source.manual_content) AS manual_content,
        lower(collected_traffic_source.manual_term) AS manual_term,
        collected_traffic_source.gclid AS gclid,
        collected_traffic_source.dclid AS dclid,
        collected_traffic_source.srsltid AS srsltid
        ) AS collected_traffic_source,
        is_active_user,
        user_properties,
        items,
        PARSE_DATE('%Y%m%d', REGEXP_EXTRACT(_TABLE_SUFFIX, '[0-9]+')) AS partition_date,
    
        --Generate columns for each event parameter
        (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id, 
        (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_number') AS ga_session_number, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS page_location, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_title') AS page_title, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_referrer') AS page_referrer, 
        (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec') AS engagement_time_msec, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'session_engaged') AS session_engaged, 
        (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'percent_scrolled') AS percent_scrolled, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'link_classes') AS link_classes, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'link_domain') AS link_domain, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'link_id') AS link_id, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'link_url') AS link_url, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'outbound') AS outbound, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'file_extension') AS file_extension, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'file_name') AS file_name, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'link_text') AS link_text, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_id') AS form_id, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_name') AS form_name, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_destination') AS form_destination, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_submit_text') AS form_submit_text, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'video_title') AS video_title, 
        (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'video_current_time') AS video_current_time, 
        (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'video_duration') AS video_duration, 
        (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'video_percent') AS video_percent, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'video_provider') AS video_provider, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'video_url') AS video_url, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'visible') AS visible, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'level_name') AS level_name, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'success') AS success, 
        (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'level') AS level, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'character') AS character, 
        (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'score') AS score, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'achievement_id') AS achievement_id, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'group_id') AS group_id, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'method') AS method, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'search_term') AS search_term, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'content_type') AS content_type, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'content_id') AS content_id, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'currency') AS transaction_currency, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'transaction_id') AS transaction_id, 
        (SELECT value.double_value FROM UNNEST(event_params) WHERE key = 'value') AS transaction_value, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'coupon') AS transaction_coupon, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'payment_type') AS transaction_payment_type, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'shipping_tier') AS transaction_shipping_tier, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'virtual_currenty_name') AS transaction_virtual_currenty_name, 
        (SELECT value.double_value FROM UNNEST(event_params) WHERE key = 'shipping') AS transaction_shipping, 
        (SELECT value.double_value FROM UNNEST(event_params) WHERE key = 'tax') AS transaction_tax, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'item_list_id') AS transaction_item_list_id, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'item_list_name') AS transaction_item_list_name, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'creative_name') AS transaction_creative_name, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'creative_slot') AS transaction_creative_slot, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'promotion_id') AS transaction_promotion_id, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'promotion_name') AS transaction_promotion_name, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'demandbase_audience') AS demandbase_audience, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'demandbase_city') AS demandbase_city, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'demandbase_company_sid') AS demandbase_company_sid, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'demandbase_company_name') AS demandbase_company_name, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'demandbase_employee_range') AS demandbase_employee_range, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'demandbase_industry') AS demandbase_industry, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'demandbase_marketing_alias') AS demandbase_marketing_alias, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'demandbase_revenue_range') AS demandbase_revenue_range, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'demandbase_state') AS demandbase_state, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'demandbase_sub_industry') AS demandbase_sub_industry, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'demandbase_web_site') AS demandbase_web_site, 
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'demandbase_country_name') AS demandbase_country_name

        FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
        WHERE _TABLE_SUFFIX > FORMAT_DATE('%Y%m%d', "2020-01-01")
    )

    --Ensure ga_session_id is not null
    --Extract event-scoped traffic dimensions from the collected_traffic_source struct
    SELECT * EXCEPT(ga_session_id, collected_traffic_source),
    IFNULL(ga_session_id,0) AS ga_session_id,
    collected_traffic_source.manual_campaign_id AS event_manual_campaign_id,
    collected_traffic_source.manual_campaign_name AS event_manual_campaign_name,
    collected_traffic_source.manual_source AS event_manual_source,
    collected_traffic_source.manual_medium AS event_manual_medium,
    collected_traffic_source.manual_content AS event_manual_content,
    collected_traffic_source.manual_term AS event_manual_term,
    collected_traffic_source.gclid AS event_gclid,
    collected_traffic_source.dclid AS event_dclid,
    collected_traffic_source.srsltid AS event_srsltid,
    NET.HOST(page_location) AS hostname
    FROM unnested_events
)