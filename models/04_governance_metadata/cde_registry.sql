select * from {{ source('raw_governance_metadata', 'cde_registry') }}
