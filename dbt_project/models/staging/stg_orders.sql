with lake as (

    select * from {{ ref('lake_orders') }}

)

select
    order_id,
    customer_id,
    order_date,
    lower(trim(status)) as status
from lake
