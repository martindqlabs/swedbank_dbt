select * from {{ source('raw_source_systems', 'src_customers') }}
