with source as (

    select * from {{ source('raw', 'payments') }}

)

select
    id as payment_id,
    order_id,
    payment_method,
    amount::numeric as amount
from source
