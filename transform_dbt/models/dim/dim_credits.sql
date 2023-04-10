with movies_full as (
    select distinct
        credits_row
    from 
        {{ ref('stg_movies') }}
)
select
    {{ dbt_utils.generate_surrogate_key(['credits_row']) }} as credits_id,
    credits_row as credits
from movies_full