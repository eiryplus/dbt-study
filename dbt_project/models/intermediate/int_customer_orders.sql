with order_payments as (

    select * from {{ ref('int_order_payments') }}

)

select
    customer_id,
    min(order_date) as first_order_date,
    max(order_date) as most_recent_order_date,
    count(order_id) as number_of_orders,
    sum(amount_paid) as lifetime_value
from order_payments
group by 1
