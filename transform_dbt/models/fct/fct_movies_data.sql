with movies_full as (
    select distinct
        id,
        credits_row,
        production_companies_row,
        genres_row,
        release_date
    from 
        {{ ref('stg_movies') }}
),
dim_movies as (
    select
        movie_id,
        id
    from
        {{ ref('dim_movies') }}
),
dim_credits as (
    select
        credits_id,
        credits
    from
        {{ ref('dim_credits') }}
),
dim_genres as (
    select
        genre_id,
        genre
    from
        {{ ref('dim_genres') }}
),
dim_production as (
    select
        production_company_id,
        production_company
    from
        {{ ref('dim_production_companies') }}
)
select
    mf.release_date,
    dm.movie_id,
    dc.credits_id,
    dg.genre_id,
    dp.production_company_id
from movies_full mf
left join dim_movies dm on mf.id = dm.id
left join dim_credits dc on mf.credits_row = dc.credits
left join dim_genres dg on mf.genres_row = dg.genre
left join dim_production dp on mf.production_companies_row = dp.production_company