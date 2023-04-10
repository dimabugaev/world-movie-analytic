{{ config(materialized='table') }}

with my_grouped_table as 
(
  select
    id,
    max(title) title,
    max(genres) genres,
    max(original_language) original_language,
    max(overview) overview,
    max(popularity) popularity,
    max(production_companies) production_companies,
    max(PARSE_DATE('%Y-%m-%d', release_date)) release_date,
    max(budget) budget,
    max(revenue) revenue,
    max(runtime) runtime,
    max(status) status,
    max(tagline) tagline,
    max(vote_average) vote_average,
    max(vote_count) vote_count,
    max(credits) credits,
    max(keywords) keywords,
    max(recommendations) recommendations 
  from {{ source('staging', 'movies') }}
  where
    release_date is not null  
  group by
    id
),
genres_array_table as (
  select
    id,
    SPLIT(genres, '-') genres_array
  from my_grouped_table    
),
production_companies_array_table as (
  select
    id,
    SPLIT(production_companies, '-') production_companies_array
  from my_grouped_table    
),
credits_array_table as (
  select
    id,
    SPLIT(credits, '-') credits_array
  from my_grouped_table    
),
credits_table as (
  select distinct
    id,
    credits_row
  from credits_array_table
  cross join UNNEST(credits_array_table.credits_array) credits_row  
),
production_companies_table as (
  select distinct
    id,
    production_companies_row
  from production_companies_array_table
  cross join UNNEST(production_companies_array_table.production_companies_array) production_companies_row
),
genres_table as (
  select distinct
    id,
    genres_row
  from genres_array_table
  cross join UNNEST(genres_array_table.genres_array) genres_row
)
select
  gt.*,
  ct.credits_row,
  pt.production_companies_row,
  gn.genres_row
from my_grouped_table gt
left join credits_table ct on gt.id = ct.id
left join production_companies_table pt on gt.id = pt.id
left join genres_table gn on gt.id = gn.id