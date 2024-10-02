--Create users forecast model
CREATE OR REPLACE MODEL `df-warehouse.models.forecast_users`
  OPTIONS(MODEL_TYPE='ARIMA_PLUS',
    time_series_timestamp_col='session_date',
    time_series_data_col='users') AS

SELECT
  session_date,
  COUNT(DISTINCT primary_user_id) AS users
FROM `df-warehouse.df_warehouse_output.output_ga4_sessions`
GROUP BY 1
ORDER BY session_date ASC


--Predict the next 30 days

/*
SELECT *
FROM ML.FORECAST(MODEL `df-warehouse.models.forecast_users`,
             STRUCT(30 AS horizon, 0.7 AS confidence_level))
*/
