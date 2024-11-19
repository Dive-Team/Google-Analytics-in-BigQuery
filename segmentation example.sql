--Extract the fields necessary to identify a session, and define the segment
with extract_event_params as (
  select
    stream_id,
    user_pseudo_id,
    (select value.int_value from unnest(event_params) where key = "ga_session_id") as ga_session_id,
    event_name
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201117`
)

--Create a true/false flag to determine if each session belongs within the segment
select
  TO_HEX(MD5(CONCAT(stream_id,user_pseudo_id,ga_session_id))) AS full_session_id,
  logical_or(event_name = "add_to_cart") as sessionSegment_add_to_cart
from extract_event_params
group by 1