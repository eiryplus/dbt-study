with dim_customers as (

    select * from {{ ref('dwh_dim_customers') }}

)

select
    customer_id,
    first_name || ' ' || last_name as customer_name,
    number_of_orders,
    lifetime_value,
    first_order_date,
    most_recent_order_date,
    case
        when number_of_orders = 0 then 'no_orders'
        when number_of_orders = 1 then 'new'
        else 'repeat'
    end as customer_segment
from dim_customers
