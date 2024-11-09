# README

# DBT Project - Enhancements

## Step 1: Update dbt_project.yml

Instead of passing environment-specific settings through a loop, define them directly in dbt_project.yml using vars. Here’s how to set it up:

1. In dbt_project.yml add the vars section.
2. Structure the vars section to define environment-specific configurations for each model based on the target.
3. Inside the models, we can access these settings based on the target, using **`{{ var('model_config')[target.name]['some_setting'] }}`** 


## Step 2: Configure table_config.yml and preprod_table_config.yml Variables in dbt_project.yml

Since there are many settings in table_config.yml and preprod_table_config.yml, we can add them as variables under the respective environments in the vars section.

1. Copy the configurations from table_config.yml and preprod_table_config.yml and place them under vars in dbt_project.yml with specific keys.
2. In our models, access the environment configurations like this: **`{{ var('dev_config')['setting1'] if target.name == 'dev' else var('prod_config')['setting1'] }}`** 

### dbt_project.yml
````
name: 'dap'
version: '1.0.0'
config-version: 2

# This setting configures which "profile" dbt uses for this project.
profile: 'domain_dbt'

# These configurations specify where dbt should look for different types of files.
# The `source-paths` config, for example, states that models in this project can be
# found in the "models/" directory. You probably won't need to change these!
source-paths: ["models"]
analysis-paths: ["analysis"]
#test-paths: ["tests"]
data-paths: ["data"]
macro-paths: ["../../dags/domain_utils/macros"]
snapshot-paths: ["snapshots"]

target-path: "target"  # directory which will store compiled SQL files
clean-targets:         # directories to be removed by `dbt clean`
    - "target"
    - "dbt_modules"

models:
    dap:
        enabled: true
        materialized: table
    my_transfer_project_refactor:
        reports:
            +enabled: "{{ target.name == 'preprod' }}"

# Define environment-specific variables
vars:
    # preprod configuration
    preprod_config:
        m_reports:
            DBT_SRC_GCP_PROJECT: "project id"
            DBT_SRC_GCP_DATASET: "coreruby"
            DBT_GCP_DATASET: "transfer_project_preprod"

        default:
            DBT_SRC_GCP_PROJECT: "project id"
            DBT_SRC_GCP_DATASET: "coreruby"
            DBT_GCP_DATASET: "transfer_project_preprod"
            DBT_SRC_TABLE_NAME: "coreruby_transactions_native"
            DBT_TGT_TABLE_NAME: "coreruby_transactions_native_raw"

    # Production configuration
    prod_config:
        m_reports:
            DBT_SRC_GCP_PROJECT: "project id"
            DBT_SRC_GCP_DATASET: "coreruby"
            DBT_GCP_DATASET: "transfer_project_preprod"

        default:
            DBT_SRC_GCP_PROJECT: "project id"
            DBT_SRC_GCP_DATASET: "coreruby"
            DBT_GCP_DATASET: "transfer_project_preprod"
            DBT_SRC_TABLE_NAME: "coreruby_transactions_native"
            DBT_TGT_TABLE_NAME: "coreruby_transactions_native_raw_prod"
   
````

## Step 3: Add Conditional Enabling of Models
### Use DBT’s enabled configuration to conditionally enable models based on the target environment:

Open each model file that needs conditional execution.

Add a configuration block at the top of each file to enable or disable or pass env var based on the env target

**models/reports/default.sql:** In this model, the vars are picked up based on the condition defined in Jinja template. Appropriate env vars are fetched when run via **`dbt run --target prod`** or **`dbt run --target preprod`**
````
{{ config(
    alias = var("preprod_config")["default"]["DBT_TGT_TABLE_NAME"] if target.name == "preprod" else var("prod_config")["default"]["DBT_TGT_TABLE_NAME"]
) }}

SELECT * ........
            .... 
````

**models/reports/m0_report.sql:** This model will only run if **`dbt run --target preprod`**
````
{{ config(
    enabled = target.name == 'preprod'
) }}

with coreruby_transactions_unique as (
select t.* from (
select
        ............... 
                    .........

````

**models/reports/m1_report.sql:** This model will only run if **`dbt run --target prod`**
````
{{ config(
    enabled = target.name == 'prod'
) }}

with coreruby_transaction_details as (
select t.* from
(
select *except(name),
upper(name) as name,
        ............... 
                    .........

````


## Deprecated components

1. **`dbt_command_loop.sh`** 
2. **`preprod_table_config.yml`**
3. **`table_config.yml`**

## Run Demonstration

### 1. **` dbt run --target preprod`**: 
Note: Here only 2 models (default & mo_report) will run based on the definition.
```bash
❯ dbt run --target preprod
09:26:15  Running with dbt=1.8.8
09:26:16  [WARNING]: Deprecated functionality
The `source-paths` config has been renamed to `model-paths`. Please update your
`dbt_project.yml` configuration to reflect this change.
09:26:16  [WARNING]: Deprecated functionality
The `data-paths` config has been renamed to `seed-paths`. Please update your
`dbt_project.yml` configuration to reflect this change.
09:26:16  Registered adapter: bigquery=1.8.3
09:26:16  Unable to do partial parsing because saved manifest not found. Starting full parse.
09:26:17  [WARNING]: Configuration paths exist in your dbt_project.yml file which do not apply to any resources.
There are 1 unused configuration paths:
- models.my_transfer_project_refactor.reports
09:26:17  Found 2 models, 11 sources, 479 macros
09:26:17  
09:26:18  Concurrency: 1 threads (target='preprod')
09:26:18  
09:26:18  1 of 2 START sql table model transfer_project_preprod.coreruby_transactions_native_raw  [RUN]
09:26:20  1 of 2 OK created sql table model transfer_project_preprod.coreruby_transactions_native_raw  [CREATE TABLE (0.0 rows, 0 processed) in 2.57s]
09:26:20  2 of 2 START sql table model transfer_project_preprod.mo_report ................ [RUN]
09:26:23  2 of 2 OK created sql table model transfer_project_preprod.mo_report ........... [CREATE TABLE (0.0 rows, 0 processed) in 2.41s]
09:26:23  
09:26:23  Finished running 2 table models in 0 hours 0 minutes and 5.97 seconds (5.97s).
09:26:23  
09:26:23  Completed successfully
09:26:23  
09:26:23  Done. PASS=2 WARN=0 ERROR=0 SKIP=0 TOTAL=2

```

### 2. **` dbt run --target prod`**:
Note: Here only 2 models (default & m1_report) will run based on the definition.
```bash
❯ dbt run --target prod
09:32:26  Running with dbt=1.8.8
09:32:27  [WARNING]: Deprecated functionality
The `source-paths` config has been renamed to `model-paths`. Please update your
`dbt_project.yml` configuration to reflect this change.
09:32:27  [WARNING]: Deprecated functionality
The `data-paths` config has been renamed to `seed-paths`. Please update your
`dbt_project.yml` configuration to reflect this change.
09:32:27  Registered adapter: bigquery=1.8.3
09:32:27  Unable to do partial parsing because config vars, config profile, or config target have changed
09:32:27  Unable to do partial parsing because profile has changed
09:32:27  [WARNING]: Configuration paths exist in your dbt_project.yml file which do not apply to any resources.
There are 1 unused configuration paths:
- models.my_transfer_project_refactor.reports
09:32:27  Found 2 models, 11 sources, 479 macros
09:32:27  
09:32:28  Concurrency: 1 threads (target='prod')
09:32:28  
09:32:28  1 of 2 START sql table model transfer_project_prod.coreruby_transactions_native_raw_prod  [RUN]
09:32:31  1 of 2 OK created sql table model transfer_project_prod.coreruby_transactions_native_raw_prod  [CREATE TABLE (0.0 rows, 0 processed) in 2.48s]
09:32:31  2 of 2 START sql table model transfer_project_prod.m1_report ................... [RUN]
09:32:34  2 of 2 OK created sql table model transfer_project_prod.m1_report .............. [CREATE TABLE (0.0 rows, 0 processed) in 2.94s]
09:32:34  
09:32:34  Finished running 2 table models in 0 hours 0 minutes and 6.40 seconds (6.40s).
09:32:34  
09:32:34  Completed successfully
09:32:34  
09:32:34  Done. PASS=2 WARN=0 ERROR=0 SKIP=0 TOTAL=2
```
## Datasets
Source Table: [bigquery_ddls.sql](bigquery_ddls.sql)
```bash
❯ bq ls coreruby
                   tableId                    Type    Labels   Time Partitioning   Clustered Fields  
 ------------------------------------------- ------- -------- ------------------- ------------------ 
  coreruby_appointment_service_types_native   TABLE                                                  
  coreruby_appointments_native                TABLE                                                  
  coreruby_consultants_native                 TABLE                                                  
  coreruby_consultants_regions_native         TABLE                                                  
  coreruby_consumer_networks_native           TABLE                                                  
  coreruby_credit_cards_native                TABLE                                                  
  coreruby_specialism_categories_native       TABLE                                                  
  coreruby_specialisms_native                 TABLE                                                  
  coreruby_transaction_details_native         TABLE                                                  
  coreruby_transactions_native                TABLE                                                  

```

DBT model Tables in BQ

preprod:
```bash
❯ bq ls transfer_project_preprod
              tableId                Type    Labels   Time Partitioning   Clustered Fields  
 ---------------------------------- ------- -------- ------------------- ------------------ 
  coreruby_transactions_native_raw   TABLE                                                  
  mo_report                          TABLE    
```

prod:
```bash
❯ bq ls transfer_project_prod
                 tableId                  Type    Labels   Time Partitioning   Clustered Fields  
 --------------------------------------- ------- -------- ------------------- ------------------ 
  coreruby_transactions_native_raw_prod   TABLE                                                  
  m1_report                               TABLE    
```