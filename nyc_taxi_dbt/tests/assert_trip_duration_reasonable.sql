-- Trips should be between 1 and 1440 minutes (24 hours)
-- Anything outside that range is likely bad data

select *
from {{ ref('fact_trips') }}
where trip_duration_minutes <= 0
   or trip_duration_minutes > 1440