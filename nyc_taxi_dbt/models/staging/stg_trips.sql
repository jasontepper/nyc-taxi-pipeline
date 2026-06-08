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
        -- basic sanity filters
        tpep_pickup_datetime >= '2023-01-01'
        and tpep_pickup_datetime < '2025-01-01'
        and trip_distance > 0
        and fare_amount > 0
        and total_amount > 0
)

select * from renamed