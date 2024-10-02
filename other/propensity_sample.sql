--The following 4 queries can be used to create a propensity scoring model on top of the df_warehouse schema for GA4



--STEP 1: Collect the user data for training and evaluation
--Include every user who's first visit was greater than 30 days ago
--Grab all of the features about each user 10 days after their first visit date from the aggregated user profiles tables

SELECT *
FROM `<INSERT extra_user_profiles TABLE ID>`
WHERE DATE_DIFF(CURRENT_DATE(),first_session_date,DAY) > 30
  AND DATE_DIFF(profile_aggregation_date,first_session_date,DAY) = 10


--STEP 2: Create a BOOLEAN label field, to identify if each user converted within the 30 days following the data aggregation date.

--Start by creating logic to identify a conversion in the output_ga4_sessions table
WITH converts AS (
  SELECT
    session_date,
    primary_user_id
  FROM `<INSERT output_ga4_sessions TABLE ID>`
  WHERE session_transactions > 0
  GROUP BY 1,2
),

--Then append the label to the propensity features table
--Randomly split 20% of rows into an evaluation dataset for training & cross validation
SELECT
  t1.*,
  IF(RAND() > .2,"TRAIN","EVAL") AS table_type,
  CASE WHEN DATE_DIFF(t1.first_session_date,t2.session_date,DAY) <= 30 THEN TRUE ELSE FALSE END AS label
FROM `<INSERT STEP 1 TABLE ID>` t1
LEFT JOIN converts t2 USING(primary_user_id)



--STEP 3: Train a model to predict each user's propability to convert in the next 30 days
--Use a boosted tree classifier to handle imbalanced data with colinear features
CREATE OR REPLACE MODEL `<INSERT PROJECT ID>.models.propensity_to_purchase`
OPTIONS(MODEL_TYPE = 'BOOSTED_TREE_CLASSIFIER',
         BOOSTER_TYPE = 'GBTREE',
         NUM_PARALLEL_TREE = 3, -- Default is 1. Try reducing this if training takes a long time.
         MIN_TREE_CHILD_WEIGHT = 1,
         COLSAMPLE_BYTREE = 0.8,
         MAX_TREE_DEPTH = 6,
         AUTO_CLASS_WEIGHTS = TRUE,
         L1_REG = 1.0,
         L2_REG = 1.0,
         EARLY_STOP = FALSE,
         LEARN_RATE = 0.3,
         INPUT_LABEL_COLS = ["label"],
         MAX_ITERATIONS = 35,
         DATA_SPLIT_METHOD = 'AUTO_SPLIT',
         ENABLE_GLOBAL_EXPLAIN = TRUE,
         XGBOOST_VERSION = '0.9' -- '1.1' is also available
)
AS SELECT
  most_recent_device_browser,
  most_recent_geo_continent,
  total_views,
  total_events,
  total_engagement_time,
  total_sessions,
  lifetime_sessions,
  total_clicks,
  total_scrolls,
  total_internal_searches,
  total_videos_started,
  total_videos_completed,
  total_files_downloaded,
  total_forms_started,
  total_forms_submited,
  total_item_lists_viewed,
  total_items_selected,
  total_items_viewed,
  total_adds_to_cart,
  total_adds_to_wishlist,
  total_carts_viewed,
  total_removes_from_cart,
  total_checkouts_started,
  total_purchases,
  total_refunds,
  total_promos_viewed,
  total_promos_selected,
  total_leads_generated,
  total_logins,
  total_searches,
  days_retained,
  userSegment_three_plus_pageviews,
  userSegment_viewedPDP,
  userSegment_addedItemToCart,
  userSegment_startedCheckout,
  label
FROM `<INSERT STEP 2 TABLE ID>`
WHERE table_type = "TRAIN"



--STEP 4: Test the model with the validation holdout group

SELECT
  primary_user_id,
  ROUND(probs.prob * 100) AS probability_bucket
FROM
ML.PREDICT(
  MODEL `<INSERT PROJECT ID>.models.propensity_to_purchase`,
  (SELECT
    primary_user_id,
    most_recent_device_browser,
    most_recent_geo_continent,
    total_views,
    total_events,
    total_engagement_time,
    total_sessions,
    lifetime_sessions,
    total_clicks,
    total_scrolls,
    total_internal_searches,
    total_videos_started,
    total_videos_completed,
    total_files_downloaded,
    total_forms_started,
    total_forms_submited,
    total_item_lists_viewed,
    total_items_selected,
    total_items_viewed,
    total_adds_to_cart,
    total_adds_to_wishlist,
    total_carts_viewed,
    total_removes_from_cart,
    total_checkouts_started,
    total_purchases,
    total_refunds,
    total_promos_viewed,
    total_promos_selected,
    total_leads_generated,
    total_logins,
    total_searches,
    days_retained,
    userSegment_three_plus_pageviews,
    userSegment_viewedPDP,
    userSegment_addedItemToCart,
    userSegment_startedCheckout
    FROM `<INSERT STEP 2 TABLE ID>`
    WHERE table_type = "EVAL")
  ),UNNEST(predicted_label_probs) as probs
WHERE probs.label = true
