select * from {{ source('raw_governance_metadata', 'dq_rule_catalog') }}
