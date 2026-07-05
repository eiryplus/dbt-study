with lake as (

    select * from {{ ref('lake_customers') }}

)

select
    customer_id,
    trim(first_name) as first_name,
    trim(last_name) as last_name
from lake
