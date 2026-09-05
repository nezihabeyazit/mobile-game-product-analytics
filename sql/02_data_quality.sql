-- ============================================================
-- PHASE 3 — DATA QUALITY
-- Mobile Game Product & User Behavior Analytics
-- ============================================================


-- ============================================================
-- QUERY 1: NULL / MISSING PLAYER ID
-- Amaç:
-- Eventlerin kaçında oyuncuyu tanımlayan user_pseudo_id eksik?
--
-- Neden önemli?
-- DAU, retention, funnel gibi player-level KPI'larda
-- oyuncuyu tanımlayamazsak o eventi doğru oyuncuya bağlayamayız.
-- ============================================================

SELECT
  COUNT(*) AS total_events,
  COUNTIF(user_pseudo_id IS NULL) AS null_player_id_events,
  ROUND(
    100 * SAFE_DIVIDE(
      COUNTIF(user_pseudo_id IS NULL),
      COUNT(*)
    ),
    4
  ) AS null_player_pct
FROM `firebase-public-project.analytics_153293282.events_*`;


-- ============================================================
-- QUERY 2: EVENT_NAME NULL / EMPTY CHECK
-- Amaç:
-- Event kaydının ne olduğunu belirleyen event_name eksik mi?
-- ============================================================

SELECT
  COUNT(*) AS total_events,
  COUNTIF(event_name IS NULL) AS null_event_name,
  COUNTIF(TRIM(event_name) = '') AS empty_event_name
FROM `firebase-public-project.analytics_153293282.events_*`;


-- ============================================================
-- QUERY 3: EVENT TIMESTAMP QUALITY
-- Amaç:
-- Timestamp eksik mi ve datasetin zaman aralığı mantıklı mı?
-- ============================================================

SELECT
  COUNTIF(event_timestamp IS NULL) AS null_timestamps,

  MIN(TIMESTAMP_MICROS(event_timestamp))
    AS earliest_event,

  MAX(TIMESTAMP_MICROS(event_timestamp))
    AS latest_event

FROM `firebase-public-project.analytics_153293282.events_*`;


-- ============================================================
-- QUERY 4: EVENT_DATE vs UTC TIMESTAMP DATE
--
-- Daha önce şunu gördük:
-- event_date = 20180914
-- UTC timestamp = 2018-09-15 ...
--
-- Şimdi bunun kaç eventte gerçekleştiğini ölçüyoruz.
--
-- NOT:
-- Fark olması otomatik olarak "bozuk veri" anlamına gelmez.
-- Firebase event_date timezone mantığından kaynaklanabilir.
-- ============================================================

SELECT
  COUNT(*) AS total_events,

  COUNTIF(
    PARSE_DATE('%Y%m%d', event_date)
    != DATE(TIMESTAMP_MICROS(event_timestamp))
  ) AS different_date_events,

  ROUND(
    100 * SAFE_DIVIDE(
      COUNTIF(
        PARSE_DATE('%Y%m%d', event_date)
        != DATE(TIMESTAMP_MICROS(event_timestamp))
      ),
      COUNT(*)
    ),
    2
  ) AS different_date_pct

FROM `firebase-public-project.analytics_153293282.events_*`;


-- ============================================================
-- QUERY 5: EXACT DUPLICATE-LIKE EVENT CHECK
--
-- Aynı player + event_name + timestamp kombinasyonunun
-- birden fazla bulunup bulunmadığını kontrol ediyoruz.
--
-- Eğer occurrences > 1 ise incelememiz gerekir.
--
-- DİKKAT:
-- Bu "kesin duplicate" demek değildir.
-- Sadece duplicate adayıdır.
-- ============================================================

SELECT
  user_pseudo_id,
  event_name,
  event_timestamp,
  COUNT(*) AS occurrences

FROM `firebase-public-project.analytics_153293282.events_*`

GROUP BY
  user_pseudo_id,
  event_name,
  event_timestamp

HAVING COUNT(*) > 1

ORDER BY occurrences DESC

LIMIT 100;


-- ============================================================
-- QUERY 6: NORMAL GAMEPLAY PARAMETER COMPLETENESS
--
-- Normal level eventlerinde:
-- level ve level_name ne kadar dolu?
--
-- Phase 2'de level'ın double_value içinde olduğunu gördük.
-- ============================================================

SELECT
  event_name,

  COUNT(*) AS total_events,

  COUNTIF(
    (SELECT ep.value.double_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'level') IS NULL
  ) AS missing_level,

  COUNTIF(
    (SELECT ep.value.string_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'level_name') IS NULL
  ) AS missing_level_name

FROM `firebase-public-project.analytics_153293282.events_*`

WHERE event_name IN (
  'level_start',
  'level_complete',
  'level_fail',
  'level_retry',
  'level_reset',
  'level_end'
)

GROUP BY event_name
ORDER BY total_events DESC;


-- ============================================================
-- QUERY 7: QUICKPLAY BOARD COMPLETENESS
--
-- Quickplay eventlerinde level yerine board kullanılıyor.
-- S / M vb.
--
-- Board eksikliği var mı?
-- ============================================================

SELECT
  event_name,

  COUNT(*) AS total_events,

  COUNTIF(
    (SELECT ep.value.string_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'board') IS NULL
  ) AS missing_board

FROM `firebase-public-project.analytics_153293282.events_*`

WHERE event_name IN (
  'level_start_quickplay',
  'level_complete_quickplay',
  'level_fail_quickplay',
  'level_retry_quickplay',
  'level_reset_quickplay',
  'level_end_quickplay'
)

GROUP BY event_name
ORDER BY total_events DESC;


-- ============================================================
-- QUERY 8: PURCHASE PRICE DATA TYPE
--
-- Çok önemli.
--
-- Phase 2'de price parametresi var ama:
-- value.double_value -> NULL
--
-- Şimdi price'ın hangi Firebase value alanında
-- saklandığını buluyoruz.
-- ============================================================

SELECT
  COUNT(*) AS purchase_events,

  COUNTIF(price.value.int_value IS NOT NULL)
    AS price_as_int,

  COUNTIF(price.value.float_value IS NOT NULL)
    AS price_as_float,

  COUNTIF(price.value.double_value IS NOT NULL)
    AS price_as_double,

  COUNTIF(price.value.string_value IS NOT NULL)
    AS price_as_string

FROM `firebase-public-project.analytics_153293282.events_*`,
UNNEST(event_params) AS price

WHERE event_name = 'in_app_purchase'
  AND price.key = 'price';


-- ============================================================
-- QUERY 9: PURCHASE PRICE VALUES
--
-- Price'ın gerçek değerlerini datatype'larıyla beraber görelim.
-- ============================================================

SELECT
  user_pseudo_id,

  TIMESTAMP_MICROS(event_timestamp) AS purchase_datetime,

  price.value.int_value AS price_int,
  price.value.float_value AS price_float,
  price.value.double_value AS price_double,
  price.value.string_value AS price_string

FROM `firebase-public-project.analytics_153293282.events_*`,
UNNEST(event_params) AS price

WHERE event_name = 'in_app_purchase'
  AND price.key = 'price'

ORDER BY purchase_datetime;


-- ============================================================
-- QUERY 10: PURCHASE CURRENCY + VALIDATION QUALITY
--
-- Purchase eventlerini currency ve validation açısından
-- kontrol ediyoruz.
--
-- Burada revenue hesaplamasının ne kadar güvenilir
-- olabileceğine karar vereceğiz.
-- ============================================================

SELECT
  (SELECT ep.value.string_value
   FROM UNNEST(event_params) ep
   WHERE ep.key = 'currency') AS currency,

  COUNT(*) AS purchases,

  COUNTIF(
    (SELECT ep.value.int_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'validated') = 1
  ) AS validated_purchases,

  COUNTIF(
    (SELECT ep.value.int_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'validated') IS NULL
  ) AS missing_validation

FROM `firebase-public-project.analytics_153293282.events_*`

WHERE event_name = 'in_app_purchase'

GROUP BY currency
ORDER BY purchases DESC;


-- ============================================================
-- QUERY 11: BASIC GAMEPLAY SANITY CHECK
--
-- Player-level normal gameplay event counts.
--
-- Amaç:
-- complete/fail/start dağılımında açıkça garip oyuncular
-- veya sıra dışı durumlar var mı?
--
-- Bu gerçek sequence validation değildir;
-- ilk sanity check'tir.
-- ============================================================

SELECT
  user_pseudo_id,

  COUNTIF(event_name = 'level_start') AS starts,
  COUNTIF(event_name = 'level_complete') AS completes,
  COUNTIF(event_name = 'level_fail') AS fails,

  COUNT(*) AS gameplay_events

FROM `firebase-public-project.analytics_153293282.events_*`

WHERE event_name IN (
  'level_start',
  'level_complete',
  'level_fail'
)

GROUP BY user_pseudo_id

ORDER BY gameplay_events DESC

LIMIT 100;