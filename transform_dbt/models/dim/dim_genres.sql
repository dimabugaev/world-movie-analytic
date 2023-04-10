with movies_full as (
    select distinct
        genres_row
    from 
        {{ ref('stg_movies') }}
)
select
    {{ dbt_utils.generate_surrogate_key(['genres_row']) }} as genre_id,
    genres_row as genre
from movies_full
