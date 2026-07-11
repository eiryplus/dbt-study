with lake as (

    select * from {{ ref('lake_customers') }}

)

select
    customer_id,
    {{ dbt_privacy.mask("trim(first_name)") }} as first_name,
    {{ dbt_privacy.mask("trim(last_name)") }} as last_name
from lake
