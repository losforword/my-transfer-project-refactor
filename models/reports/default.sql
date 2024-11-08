{{
    config(
        alias= env_var('DBT_TGT_TABLE_NAME')
)}}

Select *
from  {{ source('dataset_name', 'table_name') }}
