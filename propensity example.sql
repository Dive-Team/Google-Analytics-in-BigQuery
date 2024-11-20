--Select behavior of users who visited during 2020 (observation period)
--Generate relevant attributes for each user from their behavior during this time period
--Label those who converted
with sample_users as (
  select
    user_pseudo_id,
    COUNT(1) as events,
    sum(case when event_name = 'view_item' then 1 else 0 end) as item_views,
    sum(case when event_name = 'add_to_cart' then 1 else 0 end) as adds_to_cart,
    sum(case when event_name = 'begin_checkout' then 1 else 0 end) as checkout_starts,
    logical_or(event_name = 'purchase') as observed_converts --Identifies users who convert during the observation period
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_2020*`
  group by 1
),

--pull a list of users who converted in 2021 (during the conversion window)
labels as (
  select
      user_pseudo_id,
      logical_or(event_name = "purchase") as label
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_2021*`
  group by 1
)

--Pull training set and add labels
--Exclude those users who converted during the observation period
select sample_users.* except(observed_converts),
  ifnull(label,false) as label
from sample_users
left join labels using(user_pseudo_id)
where observed_converts = false



/*
 * STEP 2 - Create model
 */

 
 CREATE OR REPLACE MODEL `df-warehouse.models.propensity_sample`
 OPTIONS(MODEL_TYPE = 'BOOSTED_TREE_CLASSIFIER',
          BOOSTER_TYPE = 'GBTREE',
          NUM_PARALLEL_TREE = 3, # Default is 1. Try reducing this if training takes a long time.
          MIN_TREE_CHILD_WEIGHT = 1,
          COLSAMPLE_BYTREE = 0.8,
          MAX_TREE_DEPTH = 10, 
          AUTO_CLASS_WEIGHTS = TRUE,
          L1_REG = 1.0,
          L2_REG = 1.0,
          EARLY_STOP = FALSE,
          LEARN_RATE = 0.3,
          INPUT_LABEL_COLS = ["label"],
          MAX_ITERATIONS = 35,
          DATA_SPLIT_METHOD = 'AUTO_SPLIT',
          ENABLE_GLOBAL_EXPLAIN = TRUE,
          XGBOOST_VERSION = '0.9' # '1.1' is also available
 )
 AS SELECT * except(user_pseudo_id)
 FROM `df-warehouse.df_warehouse_extras.propensity_training`