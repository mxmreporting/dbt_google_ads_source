{{ config(enabled=var('ad_reporting__google_ads_enabled', True),
     unique_key = ['source_relation','campaign_id','device','ad_network_type','date_day'],
     partition_by={
      "field": "date_day", 
      "data_type": "date",
      "granularity": "day"
    }
    ) }}

with base as (

    select * 
    from {{ ref('stg_google_ads__campaign_stats_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_google_ads__campaign_stats_tmp')),
                staging_columns=get_campaign_stats_columns()
            )
        }}
    
        {{ fivetran_utils.source_relation(
            union_schema_variable='google_ads_union_schemas', 
            union_database_variable='google_ads_union_databases') 
        }}

    from base
),

final as (

    select
        source_relation, 
        customer_id as account_id, 
        DATE(TIMESTAMP(date, "America/New_York")) AS date_day,     --EST timezone conversion 
        id as campaign_id, 
        ad_network_type,
        device,
        clicks, 
        cost_micros / 1000000.0 as spend, 
        impressions
        
        {{ fivetran_utils.fill_pass_through_columns('google_ads__campaign_stats_passthrough_metrics') }}

    from fields
)

select *
from final where DATE(date_day) >= DATE_ADD(CURRENT_DATE(), INTERVAL -2 YEAR)
