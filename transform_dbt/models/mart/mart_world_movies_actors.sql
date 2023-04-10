with movies_fct as (
    select distinct
        release_date,
        movie_id,
        credits_id,
        genre_id
    from 
        {{ ref('fct_movies_data') }}
),
movies_dim as (
    select
        *
    from
        {{ ref('dim_movies') }}
),
credits_dim as (
    select
        *
    from
        {{ ref('dim_credits') }}
),
genres_dim as (
    select
        *
    from
        {{ ref('dim_genres') }}
)
select
    md.id,
    md.title,
    md.orig_language,
    --md.overview,
    MAX(md.popularity) as popularity,
    MAX(md.release_date) as release_date,
    MAX(md.budget) as budget,
    MAX(md.revenue) as revenue,
    MAX(md.runtime) as runtime,
    --md.status,
    --md.tagline,
    MAX(md.vote_average) as vote_average,
    MAX(md.vote_count) as vote_count,
    --md.keywords,
    --md.recommendations,
    cd.credits as actor,
    MAX(gd.genre) as genre    
    
from movies_fct mf
inner join movies_dim md on mf.movie_id = md.movie_id
inner join credits_dim cd on mf.credits_id = cd.credits_id
inner join genres_dim gd on mf.genre_id = gd.genre_id
group by
    md.id,
    md.title,
    md.orig_language,
    actor
