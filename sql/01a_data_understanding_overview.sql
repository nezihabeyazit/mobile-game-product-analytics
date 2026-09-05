-- ============================================================
-- MOBILE GAME PRODUCT & USER BEHAVIOR ANALYTICS
-- PHASE 2: DATA UNDERSTANDING
-- Dataset: Flood It! Firebase / GA
-- ============================================================


-- ============================================================
-- QUERY 1: DATASET OVERVIEW
-- Amaç:
-- Dataset hangi tarihleri kapsıyor?
-- Kaç event var?
-- Kaç unique player var?
-- ============================================================

SELECT
  MIN(event_date) AS first_date,
  MAX(event_date) AS last_date,
  COUNT(*) AS total_events,
  COUNT(DISTINCT user_pseudo_id) AS unique_players
FROM `firebase-public-project.analytics_153293282.events_*`;



-- ============================================================
-- QUERY 2: EVENT TAXONOMY
-- Amaç:
-- Oyunda hangi event türleri var?
-- Her event kaç kez gerçekleşmiş?
-- Kaç farklı player bu eventi gerçekleştirmiş?
--
-- Result grain:
-- 1 row = 1 event_name
-- ============================================================

SELECT
  event_name,
  COUNT(*) AS event_count,
  COUNT(DISTINCT user_pseudo_id) AS players
FROM `firebase-public-project.analytics_153293282.events_*`
GROUP BY event_name
ORDER BY event_count DESC;



-- ============================================================
-- QUERY 3: PLATFORM DISTRIBUTION
-- Amaç:
-- Player ve event hacmi platformlara nasıl dağılıyor?
--
-- Dikkat:
-- Event sayısının fazla olması tek başına daha yüksek
-- engagement anlamına gelmez.
--
-- Result grain:
-- 1 row = 1 platform
-- ============================================================

SELECT
  platform,
  COUNT(DISTINCT user_pseudo_id) AS players,
  COUNT(*) AS events
FROM `firebase-public-project.analytics_153293282.events_*`
GROUP BY platform
ORDER BY players DESC;



-- ============================================================
-- QUERY 4: COUNTRY DISTRIBUTION
-- Amaç:
-- En fazla player hangi ülkelerden geliyor?
--
-- geo bir STRUCT'tır.
-- geo.country = geo içindeki country alanı.
--
-- Result grain:
-- 1 row = 1 country
-- ============================================================

SELECT
  geo.country AS country,
  COUNT(DISTINCT user_pseudo_id) AS players
FROM `firebase-public-project.analytics_153293282.events_*`
GROUP BY geo.country
ORDER BY players DESC
LIMIT 20;



-- ============================================================
-- QUERY 5: RAW EVENT_PARAMS INSPECTION
-- Amaç:
-- event_params nested yapısının gerçekte nasıl
-- göründüğünü incelemek.
--
-- ARRAY_LENGTH(event_params) > 0:
-- En az bir parameter taşıyan eventleri getirir.
-- ============================================================

SELECT
  event_name,
  event_params
FROM `firebase-public-project.analytics_153293282.events_*`
WHERE ARRAY_LENGTH(event_params) > 0
LIMIT 10;



-- ============================================================
-- QUERY 6: AVAILABLE EVENT PARAMETERS
-- Amaç:
-- Dataset içerisinde hangi event parameter isimleri var?
--
-- UNNEST:
-- event_params ARRAY'ini satırlara açar.
--
-- Result grain:
-- 1 row = 1 parameter_name
-- ============================================================

SELECT
  ep.key AS parameter_name,
  COUNT(*) AS occurrences
FROM `firebase-public-project.analytics_153293282.events_*`,
UNNEST(event_params) AS ep
GROUP BY ep.key
ORDER BY occurrences DESC;



-- ============================================================
-- QUERY 7: EVENT × PARAMETER TAXONOMY
-- Amaç:
-- Hangi event hangi parameter'ları taşıyor?
--
-- Bu bilgi ileride gameplay, funnel, session ve
-- monetization analizlerini doğru kurmak için kullanılacak.
--
-- Result grain:
-- 1 row = 1 event_name × parameter_name combination
-- ============================================================

SELECT
  event_name,
  ep.key AS parameter_name,
  COUNT(*) AS occurrences
FROM `firebase-public-project.analytics_153293282.events_*`,
UNNEST(event_params) AS ep
GROUP BY event_name, ep.key
ORDER BY event_name, occurrences DESC;

