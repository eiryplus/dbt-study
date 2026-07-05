with fct_orders as (

    select * from {{ ref('dwh_fct_orders') }}

)

select
    date_trunc('month', order_date)::date as order_month,
    count(distinct order_id) as number_of_orders,
    sum(amount_paid) as total_revenue
from fct_orders
where status != 'returned'
group by 1
order by 1
