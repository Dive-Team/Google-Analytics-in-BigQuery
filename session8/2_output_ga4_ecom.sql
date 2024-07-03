/**
 * Creates a table to include every event that contains item data
 * The events will include all of the fields that are also available in the output_ga4_joined table 
 */


WITH events AS (
  SELECT * 
  FROM `df-warehouse.df_warehouse_output.output_ga4_joined`
),

items AS (
  SELECT * EXCEPT(
    --Remove duplicates
    user_pseudo_id,
    ga_session_id,
    full_session_id,
    event_name,
    event_timestamp,
    event_bundle_sequence_id,
    event_id
    ),
    event_id AS items_event_id
  FROM `df-warehouse.df_warehouse_intermediate.int_ga4_items`
),

joined_table AS (
  SELECT * EXCEPT(items_event_id)
  FROM events t1
  JOIN items t2 ON t1.event_id = t2.items_event_id
)

--Select all
SELECT * 
FROM joined_table