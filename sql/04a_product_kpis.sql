-- ============================================================
-- PHASE 5 — PRODUCT KPIs
-- DAU / WAU / MAU / STICKINESS
-- ============================================================


-- ============================================================
-- 1. DAILY ACTIVE USERS (DAU)
--
-- Definition:
-- Unique active players per calendar day.
--
-- Since player_daily_activity_v has
-- 1 row = 1 player × 1 day,
-- COUNT(*) is sufficient here.
-- ============================================================

SELECT
  activity_date,
  COUNT(*) AS dau
FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`
GROUP BY activity_date
ORDER BY activity_date;



-- ============================================================
-- 2. WEEKLY ACTIVE USERS (WAU)
--
-- Definition:
-- Unique players active in each calendar week.
-- ============================================================

SELECT
  DATE_TRUNC(activity_date, WEEK(MONDAY)) AS week_start,
  COUNT(DISTINCT user_pseudo_id) AS wau
FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`
GROUP BY week_start
ORDER BY week_start;



-- ============================================================
-- 3. MONTHLY ACTIVE USERS (MAU)
--
-- Definition:
-- Unique players active in each calendar month.
-- ============================================================

SELECT
  DATE_TRUNC(activity_date, MONTH) AS month_start,
  COUNT(DISTINCT user_pseudo_id) AS mau
FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`
GROUP BY month_start
ORDER BY month_start;



-- ============================================================
-- 4. DAILY DAU + ROLLING 7-DAY ACTIVE USERS
--
-- Why?
-- Calendar WAU is useful for weekly reporting,
-- but rolling 7-day active users are often better
-- for daily trend monitoring.
-- ============================================================

WITH dates AS (
  SELECT DISTINCT activity_date
  FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`
)

SELECT
  d.activity_date,

  (
    SELECT COUNT(DISTINCT p.user_pseudo_id)
    FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v` p
    WHERE p.activity_date = d.activity_date
  ) AS dau,

  (
    SELECT COUNT(DISTINCT p.user_pseudo_id)
    FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v` p
    WHERE p.activity_date BETWEEN DATE_SUB(d.activity_date, INTERVAL 6 DAY)
                              AND d.activity_date
  ) AS rolling_7d_active

FROM dates d
ORDER BY d.activity_date;



-- ============================================================
-- 5. DAILY DAU + ROLLING 30-DAY ACTIVE USERS + STICKINESS
--
-- Stickiness = DAU / rolling 30-day active users
--
-- Interpretation:
-- Approximate share of monthly active players
-- who are active on a given day.
-- ============================================================

WITH dates AS (
  SELECT DISTINCT activity_date
  FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`
)

SELECT
  d.activity_date,

  (
    SELECT COUNT(DISTINCT p.user_pseudo_id)
    FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v` p
    WHERE p.activity_date = d.activity_date
  ) AS dau,

  (
    SELECT COUNT(DISTINCT p.user_pseudo_id)
    FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v` p
    WHERE p.activity_date BETWEEN DATE_SUB(d.activity_date, INTERVAL 29 DAY)
                              AND d.activity_date
  ) AS rolling_30d_active,

  ROUND(
    SAFE_DIVIDE(
      (
        SELECT COUNT(DISTINCT p.user_pseudo_id)
        FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v` p
        WHERE p.activity_date = d.activity_date
      ),
      (
        SELECT COUNT(DISTINCT p.user_pseudo_id)
        FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v` p
        WHERE p.activity_date BETWEEN DATE_SUB(d.activity_date, INTERVAL 29 DAY)
                                  AND d.activity_date
      )
    ) * 100,
    2
  ) AS dau_mau_stickiness_pct

FROM dates d
ORDER BY d.activity_date;