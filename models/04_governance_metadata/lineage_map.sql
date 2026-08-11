select * from {{ source('raw_governance_metadata', 'lineage_map') }}
