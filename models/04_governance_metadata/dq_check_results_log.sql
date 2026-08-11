select * from {{ source('raw_governance_metadata', 'dq_check_results_log') }}
