{{ config(
    enabled = target.name == 'preprod'
) }}


with coreruby_transactions_unique as (
select t.* from (
select
*,
row_number() over(partition by id order by metadata.kafka_metadata.offset desc) row_num
from
{{ source('coreruby', 'transactions') }}
where date(partitiontime) is not null
) t
where row_num=1
),
coreruby_appointment_unique as (
select t.* from (
select
*,
row_number() over(partition by id order by metadata.kafka_metadata.offset desc) row_num
from
{{ source('coreruby', 'appointments') }}
where date(partitiontime) is not null
) t
where row_num=1
),
coreruby_consumer_networks_unique as (
select t.* from (
select
*,
row_number() over(partition by id order by metadata.kafka_metadata.offset desc) row_num
from
{{ source('coreruby', 'consumer_networks') }}
where date(partitiontime) is not null
) t
where row_num=1
),
coreruby_credit_cards_unique as (
select t.* from (
select
*,
row_number() over(partition by id order by metadata.kafka_metadata.offset desc) row_num
from
{{ source('coreruby', 'credit_cards') }}
where date(partitiontime) is not null
) t
where row_num=1
),
original_transactions as (
select "M"                                AS R_ID
  , "0"                                   AS R_TYPE
  , cn.name                               AS PROVINCE
  , t.id                                  AS RECEIPT_NUMBER
  , t.price_cents                         AS PAYMNET_AMOUNT
  ,  '+'                                  AS SIGN
  , t.braintree_transaction_token         AS AUTHORISATION_NUMBER
  , cc.card_type                          AS PAYMENT_METHOD
  , FORMAT_DATE('%Y-%m-%d', t.created_at) AS DATE_OF_SALE
  , FORMAT_DATE('%H:%M:%S', t.created_at) AS TIME_OF_SALE
  , RIGHT(cc.masked_number, 4)            AS CREDIT_CARD_L4
  , LEFT(cc.masked_number, 6)             AS CREDIT_CARD_F6
FROM coreruby_transactions_unique AS t
LEFT JOIN coreruby_credit_cards_unique   AS cc ON (cc.id = t.credit_card_id) --- Credit card details has removed by the user once transaction has completed
JOIN coreruby_appointment_unique   AS a ON (a.id = t.purchase_id)
JOIN coreruby_consumer_networks_unique AS cn ON (cn.id = a.consumer_network_id)
),
refund_transactions as (
  select "M"                              AS R_ID
  , "0"                                   AS R_TYPE
  , cn.name                               AS PROVINCE
  , t.id                                  AS RECEIPT_NUMBER
  , t.price_cents                         AS PAYMNET_AMOUNT
  , '-'                                   AS SIGN
  , t.braintree_transaction_token         AS AUTHORISATION_NUMBER
  , cc.card_type                          AS PAYMENT_METHOD
  , FORMAT_DATE('%Y-%m-%d', t.refunded_at) AS DATE_OF_SALE
  , FORMAT_DATE('%H:%M:%S', t.refunded_at) AS TIME_OF_SALE
  , RIGHT(cc.masked_number, 4)            AS CREDIT_CARD_L4
  , LEFT(cc.masked_number, 6)             AS CREDIT_CARD_F6
FROM coreruby_transactions_unique AS t
LEFT JOIN coreruby_credit_cards_unique   AS cc ON (cc.id = t.credit_card_id) --- Credit card details has removed by the user once transaction has completed
JOIN coreruby_appointment_unique   AS a ON (a.id = t.purchase_id)
JOIN coreruby_consumer_networks_unique AS cn ON (cn.id = a.consumer_network_id)
WHERE t.refunded_at is not null
),
total_transactions as(
select * from original_transactions
union all
select * from refund_transactions
)
select * from total_transactions  ORDER BY RECEIPT_NUMBER  DESC
