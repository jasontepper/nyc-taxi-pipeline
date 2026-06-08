with trips as (
    select * from {{ ref('stg_trips') }}
),

dim_time as (
    select * from {{ ref('dim_time') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['pickup_datetime', 'pickup_location_id', 'dropoff_location_id', 'total_amount']) }} as trip_id,

        -- foreign keys
        t.pickup_location_id,
        t.dropoff_location_id,
        dt.time_id,

        -- trip attributes
        t.vendor_id,
        t.rate_code_id,
        t.payment_type,
        t.store_and_fwd_flag,
        t.passenger_count,
        t.trip_distance,
        t.trip_duration_minutes,

        -- financials
        t.fare_amount,
        t.extra,
        t.mta_tax,
        t.tip_amount,
        t.tolls_amount,
        t.improvement_surcharge,
        t.congestion_surcharge,
        t.airport_fee,
        t.total_amount,

        -- timestamps
        try_to_timestamp(t.pickup_datetime)     as pickup_datetime,
        try_to_timestamp(t.dropoff_datetime)    as dropoff_datetime

    from trips t
    left join dim_time dt
        on date_trunc('hour', try_to_timestamp(t.pickup_datetime)) = dt.time_hour
)

select * from final