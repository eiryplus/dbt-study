with orders as (

    select * from {{ ref('stg_orders') }}

),

payments as (

    select
        order_id,
        sum(amount) as amount_paid,
        count(payment_id) as payment_count
    from {{ ref('stg_payments') }}
    group by 1

)

select
    orders.order_id,
    orders.customer_id,
    orders.order_date,
    orders.status,
    coalesce(payments.amount_paid, 0) as amount_paid,
    coalesce(payments.payment_count, 0) as payment_count
from orders
left join payments on orders.order_id = payments.order_id
