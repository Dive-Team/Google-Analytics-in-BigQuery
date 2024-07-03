/**
 *  Flattens the items array so that each item in the event is represented in a single row.
 *  Also applies a window function to attribute transactions back to the item_lists and promotions that displayed the items earlier in the session.
 */


WITH extract_items AS (
SELECT 
    --Create unique keys
    user_pseudo_id,
    full_session_id,
    ga_session_id,
    event_name,
    event_timestamp,
    event_bundle_sequence_id,
    event_id,

    --Flatten item parameters
    i.item_id,
    i.item_name,
    i.item_brand,
    i.item_variant,
    i.item_category,
    i.item_category2,
    i.item_category3,
    i.item_category4,
    i.item_category5,
    i.price_in_usd,
    i.price,
    i.quantity,
    i.item_revenue_in_usd,
    i.item_revenue,
    i.item_refund_in_usd,
    i.item_refund,
    i.coupon,
    i.affiliation,
    i.location_id,
    i.item_list_id,
    i.item_list_name,
    i.item_list_index,
    i.promotion_id,
    i.promotion_name,
    i.creative_name,
    i.creative_slot

    --Extract custom item parameters here

  FROM `df-warehouse.df_warehouse_intermediate.int_ga4_events`,UNNEST(items) i 
  WHERE items IS NOT NULL
),

--The unique key for this view will be a concatenation of the event_id and item_id
add_unique_key AS (
  SELECT * ,
    CONCAT(item_id,event_id) AS item_event_id,
    CONCAT(item_id,full_session_id) AS item_session_id
  FROM extract_items
),

--Apply item_list and promotion attribution
--Set each dimension to the last non-null value detected for this item within this session
list_and_promo_attribution AS (
  SELECT * EXCEPT(item_list_id, item_list_name, item_list_index, promotion_id, promotion_name, creative_name, creative_slot),
    IF(item_list_id IS NOT NULL,item_list_id,
      LAST_VALUE(item_list_id IGNORE NULLS) OVER(
      PARTITION BY item_session_id ORDER BY event_timestamp ASC)) AS item_list_id,
    IF(item_list_name IS NOT NULL,item_list_name,
      LAST_VALUE(item_list_name IGNORE NULLS) OVER(
      PARTITION BY item_session_id ORDER BY event_timestamp ASC)) AS item_list_name,
    IF(item_list_index IS NOT NULL,item_list_index,
      LAST_VALUE(item_list_index IGNORE NULLS) OVER(
      PARTITION BY item_session_id ORDER BY event_timestamp ASC)) AS item_list_index,
    IF(promotion_id IS NOT NULL,promotion_id,
      LAST_VALUE(promotion_id IGNORE NULLS) OVER(
      PARTITION BY item_session_id ORDER BY event_timestamp ASC)) AS promotion_id,
    IF(promotion_name IS NOT NULL,promotion_name,
      LAST_VALUE(promotion_name IGNORE NULLS) OVER(
      PARTITION BY item_session_id ORDER BY event_timestamp ASC)) AS promotion_name,
    IF(creative_name IS NOT NULL,creative_name,
      LAST_VALUE(creative_name IGNORE NULLS) OVER(
      PARTITION BY item_session_id ORDER BY event_timestamp ASC)) AS creative_name,
    IF(creative_slot IS NOT NULL,creative_slot,
      LAST_VALUE(creative_slot IGNORE NULLS) OVER(
      PARTITION BY item_session_id ORDER BY event_timestamp ASC)) AS creative_slot
FROM add_unique_key
)

SELECT *
FROM list_and_promo_attribution