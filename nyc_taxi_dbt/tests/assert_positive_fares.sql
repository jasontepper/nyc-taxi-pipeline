-- This test fails if any trips have negative or zero fare amounts
-- Returns failing rows; zero rows = test passes

select *
from {{ ref('fact_trips') }}
where fare_amount <= 0