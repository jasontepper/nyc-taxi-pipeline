with source as (
    select * from {{ source('raw', 'trips') }}
),

renamed as (
    select
        -- identifiers
        vendorid                                    as vendor_id,
        pulocationid                                as pickup_location_id,
        dolocationid                                as dropoff_location_id,
        ratecodeid                                  as rate_code_id,
        payment_type,

        -- timestamps
        tpep_pickup_datetime                        as pickup_datetime,
        tpep_dropoff_datetime                       as dropoff_datetime,

        -- trip info
        passenger_count,
        trip_distance,
        store_and_fwd_flag,

        -- financials
        fare_amount,
        extra,
        mta_tax,
        tip_amount,
        tolls_amount,
        improvement_surcharge,
        congestion_surcharge,
        airport_fee,
        total_amount,

        -- derived
        datediff('minute', tpep_pickup_datetime, tpep_dropoff_datetime) as trip_duration_minutes

    from source

    where
    try_to_timestamp(tpep_pickup_datetime) >= '2023-01-01'
    and try_to_timestamp(tpep_pickup_datetime) < '2025-01-01'
    and trip_distance > 0
    and fare_amount > 0
    and total_amount > 0
    and datediff('minute', try_to_timestamp(tpep_pickup_datetime), try_to_timestamp(tpep_dropoff_datetime)) > 0
    and datediff('minute', try_to_timestamp(tpep_pickup_datetime), try_to_timestamp(tpep_dropoff_datetime)) <= 1440
)

select * from renamed