/**
 *  Gets predictions from the user forecast model for the next 30 days
 */

SELECT * 
FROM ML.FORECAST(MODEL `df-warehouse.models.forecast_users`,
             STRUCT(30 AS horizon, 0.8 AS confidence_level)) 