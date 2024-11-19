/**
 * Create session forecast model
 */

CREATE OR REPLACE MODEL `df-warehouse.models.forecast_sessions`
  OPTIONS(MODEL_TYPE='ARIMA_PLUS',
    time_series_timestamp_col='date',
    time_series_data_col='sessions') AS

--Extract the fields necessary to identify a session
with extract_event_params as (
  select
    DATE(TIMESTAMP_MICROS(event_timestamp)) as date,
    stream_id,
    user_pseudo_id,
    (select value.int_value from unnest(event_params) where key = "ga_session_id") as ga_session_id
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_2020*`
)

--Sum sessions by date
select
  date,
  count(distinct TO_HEX(MD5(CONCAT(stream_id,user_pseudo_id,ga_session_id)))) AS sessions
from extract_event_params
group by 1

/**
 * Get forecast and compare to actuals
 */

--Pull the following 30 days after the training set
with extract_event_params as (
  select
    DATE(TIMESTAMP_MICROS(event_timestamp)) as date,
    stream_id,
    user_pseudo_id,
    (select value.int_value from unnest(event_params) where key = "ga_session_id") as ga_session_id
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_2021*`
),

actuals as (
  select
    date,
    count(distinct TO_HEX(MD5(CONCAT(stream_id,user_pseudo_id,ga_session_id)))) AS sessions
  from extract_event_params
  group by 1
),

--Predict the next 30 days
forecast as (
  select *
  from ML.FORECAST(model `df-warehouse.models.forecast_users`,
              struct(30 as horizon, 0.7 as confidence_level)) 
)

select *
from actuals
left join forecast on actuals.date = extract(date from forecast.forecast_timestamp)
order by date asc
