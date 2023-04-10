with movies_full as (
    select distinct
        id,
        title,
        original_language,
        overview,
        popularity,
        release_date,
        budget,
        revenue,
        runtime,
        status,
        tagline,
        vote_average,
        vote_count,
        keywords,
        recommendations
    from 
        {{ ref('stg_movies') }}
),
languages as (
    select
        *
    from 
        {{ ref('languages') }})
select
    {{ dbt_utils.generate_surrogate_key(['id', 'title']) }} as movie_id,
    mf.id,
    mf.title,
    l.English as orig_language,
    mf.overview,
    mf.popularity,
    mf.release_date,
    mf.budget,
    mf.revenue,
    case
        when mf.revenue <> 0 and mf.revenue is not null and mf.budget <> 0 and mf.budget is not null then
            (mf.revenue/mf.budget - 1) * 100 
        else 
            NULL 
    end as percent_pure_income,
    mf.runtime,
    mf.status,
    mf.tagline,
    mf.vote_average,
    mf.vote_count,
    mf.keywords,
    mf.recommendations
from movies_full mf
left join languages l on mf.original_language = l.alpha2