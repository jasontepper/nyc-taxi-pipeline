with trips as (
    select * from {{ ref('stg_trips') }}
),

dim_time as (
    select * from {{ ref('dim_time') }}
),

deduplicated as (
    select *,
        row_number() over (
            partition by pickup_datetime, dropoff_datetime, pickup_location_id,
                         dropoff_location_id, total_amount, vendor_id, tip_amount
            order by pickup_datetime
        ) as row_num
    from trips
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['pickup_datetime', 'dropoff_datetime', 'pickup_location_id', 'dropoff_location_id', 'total_amount', 'vendor_id', 'tip_amount', 'row_num']) }} as trip_id,

        -- foreign keys
        d.pickup_location_id,
        d.dropoff_location_id,
        dt.time_id,

        -- trip attributes
        d.vendor_id,
        d.rate_code_id,
        d.payment_type,
        d.store_and_fwd_flag,
        d.passenger_count,
        d.trip_distance,
        d.trip_duration_minutes,

        -- financials
        d.fare_amount,
        d.extra,
        d.mta_tax,
        d.tip_amount,
        d.tolls_amount,
        d.improvement_surcharge,
        d.congestion_surcharge,
        d.airport_fee,
        d.total_amount,

        -- timestamps
        try_to_timestamp(d.pickup_datetime)     as pickup_datetime,
        try_to_timestamp(d.dropoff_datetime)    as dropoff_datetime

    from deduplicated d
    left join dim_time dt
        on date_trunc('hour', try_to_timestamp(d.pickup_datetime)) = dt.time_hour

    where d.row_num = 1
)

select * from final