{{ config(
    enabled = target.name == 'prod'
) }}

with coreruby_transaction_details as (
select t.* from
(
select *except(name),
upper(name) as name,
row_number() over(partition by id order by metadata.kafka_metadata.offset desc) row_num
from {{ source('coreruby', 'transaction_details') }}
WHERE  date(partitiontime) is not null
and kind ='tax'
and (UPPER(name) like '%GST%' or UPPER(name) like '%HST%' or UPPER(name) like '%PST%')
) t
where row_num=1
),
coreruby_transactions_unique as (
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
coreruby_consultants_unique as (
select t.* from (
select
*,
row_number() over(partition by id order by metadata.kafka_metadata.offset desc) row_num
from
{{ source('coreruby', 'consultants') }}
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
coreruby_consultants_regions_unique as (
select t.* from (
select
*,
row_number() over(partition by consultant_id,region_id  order by metadata.kafka_metadata.offset desc) row_num
from
{{ source('coreruby', 'consultants_regions') }}
where date(partitiontime) is not null
) t
where row_num=1
),
coreruby_specialisms_unique as (
select t.* from (
select
*,
row_number() over(partition by id order by metadata.kafka_metadata.offset desc) row_num
from
{{ source('coreruby', 'specialisms') }}
where date(partitiontime) is not null
) t
where row_num=1
),
coreruby_specialism_categories_unique as (
select t.* from (
select
*,
row_number() over(partition by id order by metadata.kafka_metadata.offset desc) row_num
from
{{ source('coreruby', 'specialism_categories') }}
where date(partitiontime) is not null
) t
where row_num=1
),
coreruby_appointment_service_types_unique as (
select t.* from (
select
*,
row_number() over(partition by uuid order by metadata.kafka_metadata.offset desc) row_num
from
{{ source('coreruby', 'appointment_service_types') }}
where date(partitiontime) is not null
) t
where row_num=1
),
appointment_details as
(
select t.id as transaction_id,t.price_cents,t.refunded_at,a.id as appointment_id,a.consultant_id,a.consumer_network_id,a.appointment_service_type_uuid
,cr.specialism_id
from
coreruby_transactions_unique t
JOIN coreruby_appointment_unique AS a
ON (a.id = t.purchase_id)
JOIN coreruby_consultants_unique AS c   ON (c.id = a.consultant_id)
JOIN coreruby_consumer_networks_unique   AS cn  ON (cn.id = a.consumer_network_id)
JOIN coreruby_consultants_regions_unique        AS cr  ON (cr.consultant_id = c.id AND cr.region_id = cn.region_id)
),
specialism_details as
(
select s.id as specialism_id,s.specialism_category_id as specialism_category_id,s.new_name as specialism_name,sc.new_name as specialism_category
FROM
coreruby_specialisms_unique          AS s
JOIN coreruby_specialism_categories_unique    AS sc  ON (sc.id = s.specialism_category_id)
),
appointment_specialism as (
select
    a.appointment_id,
    a.transaction_id,
    a.appointment_service_type_uuid,
    a.price_cents,
    a.refunded_at,
    a.specialism_id,
    s.specialism_category_id,
    s.specialism_name,
    s.specialism_category
From
appointment_details as a
left join
specialism_details as s
on a.specialism_id=s.specialism_id
),
original_transactions as (
SELECT 'M'                                    AS R_ID
  , '1'                                       AS R_TYPE
  , '000'                                     AS WORKSTATION
  , t.transaction_id                          AS RECEIPT_NUMBER
  , 1                                         AS ITEM_NUMBER
  , COALESCE(ast.uuid, cast(specialism_id as string),"PRODUCT_DELETED")  AS PRODUCT_CODE
  , COALESCE(ast.name, specialism_name,"PRODUCT_DELETED")            AS PRODUCT_DESC
  , ''                                        AS GL_ACCOUNT
  , 1                                         AS QUANTITY
  , COALESCE(t.price_cents, 0)                AS AMOUNT
  , '+'                                       AS SIGN_
  , if(gst.amount_cents>0, 'false', 'true')   AS GST_EXEMPT_FLAG
  , gst.amount_cents                          AS GST_AMOUNT
  , '+'                                       AS GST_SIGN
  , if(pst.amount_cents>0, 'false', 'true')   AS PST_EXEMPT_FLAG
  , pst.amount_cents                          AS PST_AMOUNT
  , '+'                                       AS PST_SIGN
  , if(hst.amount_cents>0, 'false', 'true')   AS HST_EXEMPT_FLAG
  , hst.amount_cents                          AS HST_AMOUNT
  , '+'                                       AS HST_SIGN
  , COALESCE(ast.grouping, specialism_category,"PRODUCT_DELETED")   AS PRODUCT_GROUP
FROM appointment_specialism t
LEFT JOIN (select transaction_id, COALESCE(amount_cents, 0) AS amount_cents FROM  coreruby_transaction_details where name like '%GST%') AS gst ON (gst.transaction_id = t.transaction_id)
LEFT JOIN (select transaction_id, COALESCE(amount_cents, 0) AS amount_cents FROM  coreruby_transaction_details where name like '%HST%') AS hst ON (hst.transaction_id = t.transaction_id)
LEFT JOIN (select transaction_id, COALESCE(amount_cents, 0) AS amount_cents FROM  coreruby_transaction_details where name like '%PST%') AS pst ON (pst.transaction_id = t.transaction_id)
LEFT JOIN  coreruby_appointment_service_types_unique AS ast ON (ast.uuid = t.appointment_service_type_uuid)
),
refund_transactions as (
SELECT 'M'                                    AS R_ID
  , '1'                                       AS R_TYPE
  , '000'                                     AS WORKSTATION
  , t.transaction_id                          AS RECEIPT_NUMBER
  , 1                                         AS ITEM_NUMBER
  , COALESCE(ast.uuid, cast(specialism_id as string),"PRODUCT_DELETED")  AS PRODUCT_CODE
  , COALESCE(ast.name, specialism_name,"PRODUCT_DELETED")            AS PRODUCT_DESC
  , ''                                        AS GL_ACCOUNT
  , 1                                         AS QUANTITY
  , COALESCE(t.price_cents, 0)                AS AMOUNT
  , '-'                                       AS SIGN_
  , if(gst.amount_cents>0, 'false', 'true')   AS GST_EXEMPT_FLAG
  , gst.amount_cents                          AS GST_AMOUNT
  , '-'                                       AS GST_SIGN
  , if(pst.amount_cents>0, 'false', 'true')   AS PST_EXEMPT_FLAG
  , pst.amount_cents                          AS PST_AMOUNT
  , '-'                                       AS PST_SIGN
  , if(hst.amount_cents>0, 'false', 'true')   AS HST_EXEMPT_FLAG
  , hst.amount_cents                          AS HST_AMOUNT
  , '-'                                       AS HST_SIGN
  , COALESCE(ast.grouping, specialism_category,"PRODUCT_DELETED")   AS PRODUCT_GROUP
FROM appointment_specialism t
LEFT JOIN (select transaction_id, COALESCE(amount_cents, 0) AS amount_cents FROM  coreruby_transaction_details where name like '%GST%') AS gst ON (gst.transaction_id = t.transaction_id)
LEFT JOIN (select transaction_id, COALESCE(amount_cents, 0) AS amount_cents FROM  coreruby_transaction_details where name like '%HST%') AS hst ON (hst.transaction_id = t.transaction_id)
LEFT JOIN (select transaction_id, COALESCE(amount_cents, 0) AS amount_cents FROM  coreruby_transaction_details where name like '%PST%') AS pst ON (pst.transaction_id = t.transaction_id)
LEFT JOIN  coreruby_appointment_service_types_unique AS ast ON (ast.uuid = t.appointment_service_type_uuid)
WHERE t.refunded_at is not null
),
total_transactions as(
select * from original_transactions
union all
select * from refund_transactions
)
select * from total_transactions ORDER BY RECEIPT_NUMBER DESC
