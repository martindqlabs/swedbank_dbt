select * from {{ source('raw_source_systems', 'src_npl_status') }}
