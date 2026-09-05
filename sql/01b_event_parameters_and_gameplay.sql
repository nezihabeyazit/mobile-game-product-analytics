-- ============================================================
-- PHASE 2 - FINAL DATA UNDERSTANDING / VALIDATION
-- ============================================================


-- ============================================================
-- QUERY 8: TIMESTAMP CHECK
-- Amaç:
-- event_timestamp'in gerçek timestamp'e nasıl çevrildiğini görmek.
--
-- Firebase event_timestamp'i microseconds olarak saklar.
-- TIMESTAMP_MICROS() bunu okunabilir timestamp'e çevirir.
-- ============================================================

SELECT
  event_date,
  event_timestamp,
  TIMESTAMP_MICROS(event_timestamp) AS event_datetime,
  event_name,
  user_pseudo_id
FROM `firebase-public-project.analytics_153293282.events_*`
LIMIT 20;



-- ============================================================
-- QUERY 9: DEVICE DISTRIBUTION
-- Amaç:
-- Oyuncuların cihaz / işletim sistemi dağılımını anlamak.
--
-- device bir STRUCT'tır.
-- Bu yüzden device.category gibi alt alanlara erişiyoruz.
--
-- Grain:
-- 1 row = device category × operating system
-- ============================================================

SELECT
  device.category AS device_category,
  device.operating_system AS operating_system,
  COUNT(DISTINCT user_pseudo_id) AS players,
  COUNT(*) AS events
FROM `firebase-public-project.analytics_153293282.events_*`
GROUP BY
  device.category,
  device.operating_system
ORDER BY players DESC;



-- ============================================================
-- QUERY 10: TRAFFIC SOURCE
-- Amaç:
-- Oyuncuların hangi acquisition/source bilgilerine sahip
-- olduğunu görmek.
--
-- traffic_source da bir STRUCT'tır.
--
-- Grain:
-- 1 row = source × medium
-- ============================================================

SELECT
  traffic_source.source,
  traffic_source.medium,
  COUNT(DISTINCT user_pseudo_id) AS players
FROM `firebase-public-project.analytics_153293282.events_*`
GROUP BY
  traffic_source.source,
  traffic_source.medium
ORDER BY players DESC
LIMIT 30;



-- ============================================================
-- QUERY 11: GAMEPLAY PARAMETER VALUES
-- Amaç:
-- level / board gibi önemli parametrelerin gerçek değerlerini
-- görmek.
--
-- Burada correlated subquery ile event_params ARRAY'inden
-- istediğimiz key'in value'sunu çekiyoruz.
-- ============================================================

SELECT
  event_name,

  (
    SELECT ep.value.string_value
    FROM UNNEST(event_params) ep
    WHERE ep.key = 'level_name'
  ) AS level_name,

  (
    SELECT ep.value.int_value
    FROM UNNEST(event_params) ep
    WHERE ep.key = 'level'
  ) AS level_int,

  (
    SELECT ep.value.double_value
    FROM UNNEST(event_params) ep
    WHERE ep.key = 'level'
  ) AS level_double,

  (
    SELECT ep.value.string_value
    FROM UNNEST(event_params) ep
    WHERE ep.key = 'board'
  ) AS board

FROM `firebase-public-project.analytics_153293282.events_*`

WHERE event_name IN (
  'level_start',
  'level_complete',
  'level_fail',
  'level_start_quickplay',
  'level_complete_quickplay',
  'level_fail_quickplay'
)

LIMIT 100;



-- ============================================================
-- QUERY 12: PURCHASE INSPECTION
-- Amaç:
-- 27 purchase eventinin içindeki gerçek monetization
-- parametrelerini incelemek.
--
-- Özellikle price, currency, product_id ve quantity.
-- ============================================================

SELECT
  user_pseudo_id,
  TIMESTAMP_MICROS(event_timestamp) AS purchase_datetime,

  (
    SELECT ep.value.string_value
    FROM UNNEST(event_params) ep
    WHERE ep.key = 'product_id'
  ) AS product_id,

  (
    SELECT ep.value.double_value
    FROM UNNEST(event_params) ep
    WHERE ep.key = 'price'
  ) AS price,

  (
    SELECT ep.value.string_value
    FROM UNNEST(event_params) ep
    WHERE ep.key = 'currency'
  ) AS currency,

  (
    SELECT ep.value.int_value
    FROM UNNEST(event_params) ep
    WHERE ep.key = 'quantity'
  ) AS quantity,

  (
    SELECT ep.value.int_value
    FROM UNNEST(event_params) ep
    WHERE ep.key = 'validated'
  ) AS validated

FROM `firebase-public-project.analytics_153293282.events_*`

WHERE event_name = 'in_app_purchase'

ORDER BY purchase_datetime;