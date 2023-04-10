with movies_fct as (
    select distinct
        release_date,
        movie_id,
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
    gd.genre    
    
from movies_fct mf
    inner join movies_dim md on mf.movie_id = md.movie_id
    inner join genres_dim gd on mf.genre_id = gd.genre_id and gd.genre is not null