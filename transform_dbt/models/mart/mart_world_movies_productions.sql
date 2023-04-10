with movies_fct as (
    select distinct
        release_date,
        movie_id,
        production_company_id
    from 
        {{ ref('fct_movies_data') }}
),
movies_dim as (
    select
        *
    from
        {{ ref('dim_movies') }}
),
production_dim as (
    select
        *
    from
        {{ ref('dim_production_companies') }}
)
select
    md.id,
    md.title,
    md.orig_language,
    md.overview,
    md.popularity,
    md.release_date,
    md.budget,
    md.revenue,
    md.runtime,
    md.status,
    md.tagline,
    md.vote_average,
    md.vote_count,
    md.keywords,
    md.recommendations,
    pd.production_company    
    
from movies_fct mf
inner join movies_dim md on mf.movie_id = md.movie_id
inner join production_dim pd on mf.production_company_id = pd.production_company_id