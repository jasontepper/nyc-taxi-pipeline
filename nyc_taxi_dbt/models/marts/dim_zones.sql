with zones as (
    select * from {{ ref('taxi_zones') }}
)

select
    locationid          as zone_id,
    borough,
    zone                as zone_name,
    service_zone
from zones