select
    order_id,
    customer_id,
    order_date,
    status,
    amount_paid,
    payment_count
from {{ ref('int_order_payments') }}
