with movies_all as (
    select
        *
    from 
        {{ ref('dim_movies') }}
)
select
    id,
    title,
    orig_language,
    overview,
    popularity,
    release_date,
    budget,
    revenue,
    percent_pure_income,
    runtime,
    status,
    tagline,
    vote_average,
    vote_count,
    keywords,
    recommendations    
    
from movies_all