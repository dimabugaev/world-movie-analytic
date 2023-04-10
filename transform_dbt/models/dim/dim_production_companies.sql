with movies_full as (
    select distinct
        production_companies_row
    from 
        {{ ref('stg_movies') }}
)
select
    {{ dbt_utils.generate_surrogate_key(['production_companies_row']) }} as production_company_id,
    production_companies_row as production_company
from movies_full