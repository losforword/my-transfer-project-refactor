{{ config(
    alias = var("preprod_config")["default"]["DBT_TGT_TABLE_NAME"] if target.name == "preprod" else var("prod_config")["default"]["DBT_TGT_TABLE_NAME"]
) }}

SELECT *
FROM {{ source('dataset_name', 'table_name') }}
