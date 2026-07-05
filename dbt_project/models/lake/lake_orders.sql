with source as (

    select * from {{ source('raw', 'orders') }}

)

select
    id as order_id,
    user_id as customer_id,
    order_date::date as order_date,
    status
from source
