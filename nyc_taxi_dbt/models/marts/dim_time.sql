with trips as (
    select distinct
        date_trunc('hour', try_to_timestamp(pickup_datetime)) as time_hour
    from {{ ref('stg_trips') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['time_hour']) }}  as time_id,
        time_hour,
        date(time_hour)                             as date_day,
        extract(hour from time_hour)                as hour_of_day,
        dayofweek(time_hour)                        as day_of_week,
        dayname(time_hour)                          as day_name,
        case when dayofweek(time_hour) in (1, 7)
            then true else false end                as is_weekend,
        extract(month from time_hour)               as month_number,
        monthname(time_hour)                        as month_name,
        extract(quarter from time_hour)             as quarter_number,
        extract(year from time_hour)                as year_number
    from trips
)

select * from final