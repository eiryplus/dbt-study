with lake as (

    select * from {{ ref('lake_payments') }}

)

select
    payment_id,
    order_id,
    lower(trim(payment_method)) as payment_method,
    amount
from lake
where amount > 0
