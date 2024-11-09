-- DDL for <project id>.<dataset>.coreruby_appointment_service_types_native
CREATE TABLE `<project id>.<dataset>.coreruby_appointment_service_types_native` (
  `uuid` STRING,
  `name` STRING,
  `description` STRING,
  `created_at` TIMESTAMP,
  `updated_at` TIMESTAMP,
  `partitiontime` TIMESTAMP,
  `metadata` STRUCT<kafka_metadata STRUCT<offset INT64>>,
  `grouping` STRING
);

-- DDL for <project id>.<dataset>.coreruby_appointments_native
CREATE TABLE `<project id>.<dataset>.coreruby_appointments_native` (
  `id` INT64,
  `created_at` TIMESTAMP,
  `consultant_id` INT64,
  `consumer_network_id` INT64,
  `appointment_service_type_uuid` STRING,
  `partitiontime` TIMESTAMP,
  `metadata` STRUCT<kafka_metadata STRUCT<offset INT64>>
);

-- DDL for <project id>.<dataset>.coreruby_consultants_native
CREATE TABLE `<project id>.<dataset>.coreruby_consultants_native` (
  `id` INT64,
  `name` STRING,
  `partitiontime` TIMESTAMP,
  `metadata` STRUCT<kafka_metadata STRUCT<offset INT64>>
);

-- DDL for <project id>.<dataset>.coreruby_consultants_regions_native
CREATE TABLE `<project id>.<dataset>.coreruby_consultants_regions_native` (
  `consultant_id` INT64,
  `region_id` INT64,
  `specialism_id` INT64,
  `partitiontime` TIMESTAMP,
  `metadata` STRUCT<kafka_metadata STRUCT<offset INT64>>
);

-- DDL for <project id>.<dataset>.coreruby_consumer_networks_native
CREATE TABLE `<project id>.<dataset>.coreruby_consumer_networks_native` (
  `id` INT64,
  `name` STRING,
  `region_id` INT64,
  `partitiontime` TIMESTAMP,
  `metadata` STRUCT<kafka_metadata STRUCT<offset INT64>>
);

-- DDL for <project id>.<dataset>.coreruby_credit_cards_native
CREATE TABLE `<project id>.<dataset>.coreruby_credit_cards_native` (
  `id` INT64,
  `card_type` STRING,
  `masked_number` STRING,
  `expiration_date` DATE,
  `cardholder_name` STRING,
  `billing_address` STRING,
  `created_at` TIMESTAMP,
  `updated_at` TIMESTAMP,
  `metadata` STRUCT<kafka_metadata STRUCT<offset INT64>>,
  `partitiontime` TIMESTAMP
);

-- DDL for <project id>.<dataset>.coreruby_specialism_categories_native
CREATE TABLE `<project id>.<dataset>.coreruby_specialism_categories_native` (
  `id` INT64,
  `new_name` STRING,
  `partitiontime` TIMESTAMP,
  `metadata` STRUCT<kafka_metadata STRUCT<offset INT64>>
);

-- DDL for <project id>.<dataset>.coreruby_specialisms_native
CREATE TABLE `<project id>.<dataset>.coreruby_specialisms_native` (
  `id` INT64,
  `specialism_category_id` INT64,
  `new_name` STRING,
  `partitiontime` TIMESTAMP,
  `metadata` STRUCT<kafka_metadata STRUCT<offset INT64>>
);

-- DDL for <project id>.<dataset>.coreruby_transaction_details_native
CREATE TABLE `<project id>.<dataset>.coreruby_transaction_details_native` (
  `id` INT64,
  `transaction_id` INT64,
  `name` STRING,
  `kind` STRING,
  `amount_cents` INT64,
  `created_at` TIMESTAMP,
  `metadata` STRUCT<kafka_metadata STRUCT<offset INT64>>,
  `partitiontime` TIMESTAMP
);

-- DDL for <project id>.<dataset>.coreruby_transactions_native
CREATE TABLE `<project id>.<dataset>.coreruby_transactions_native` (
  `id` INT64,
  `created_at` TIMESTAMP,
  `price_cents` INT64,
  `braintree_transaction_token` STRING,
  `credit_card_id` INT64,
  `purchase_id` INT64,
  `partitiontime` TIMESTAMP,
  `metadata` STRUCT<kafka_metadata STRUCT<offset INT64>>,
  `refunded_at` DATETIME
);

