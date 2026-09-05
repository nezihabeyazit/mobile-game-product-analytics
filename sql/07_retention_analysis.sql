-- ============================================================
-- 08 — RETENTION & COHORT ANALYSIS
-- Mobile Game Product & User Behavior Analytics
-- ============================================================


-- ============================================================
-- 1. PLAYER COHORTS
--
-- Day 0 = first observed activity date in the dataset.
--
-- Grain:
-- 1 row = 1 player
-- ============================================================

WITH player_cohorts AS (
  SELECT
    user_pseudo_id,
    MIN(activity_date) AS cohort_date
  FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`
  GROUP BY user_pseudo_id
)

SELECT
  cohort_date,
  COUNT(*) AS cohort_size
FROM player_cohorts
GROUP BY cohort_date
ORDER BY cohort_date;



-- ============================================================
-- 2. D1 / D7 / D30 RETENTION BY COHORT DATE
--
-- Exact-day retention:
-- D1  = active exactly 1 day after Day 0
-- D7  = active exactly 7 days after Day 0
-- D30 = active exactly 30 days after Day 0
--
-- IMPORTANT:
-- Only cohorts with enough future observation time should be
-- interpreted for each retention horizon.
-- ============================================================

WITH player_cohorts AS (
  SELECT
    user_pseudo_id,
    MIN(activity_date) AS cohort_date
  FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`
  GROUP BY user_pseudo_id
),

retention_flags AS (
  SELECT
    c.user_pseudo_id,
    c.cohort_date,

    MAX(
      CASE
        WHEN p.activity_date = DATE_ADD(c.cohort_date, INTERVAL 1 DAY)
        THEN 1 ELSE 0
      END
    ) AS retained_d1,

    MAX(
      CASE
        WHEN p.activity_date = DATE_ADD(c.cohort_date, INTERVAL 7 DAY)
        THEN 1 ELSE 0
      END
    ) AS retained_d7,

    MAX(
      CASE
        WHEN p.activity_date = DATE_ADD(c.cohort_date, INTERVAL 30 DAY)
        THEN 1 ELSE 0
      END
    ) AS retained_d30

  FROM player_cohorts c

  LEFT JOIN `mobile-game-product-analytics.game_analytics.player_daily_activity_v` p
    ON c.user_pseudo_id = p.user_pseudo_id

  GROUP BY
    c.user_pseudo_id,
    c.cohort_date
)

SELECT
  cohort_date,
  COUNT(*) AS cohort_size,

  SUM(retained_d1) AS retained_d1_players,
  ROUND(
    SAFE_DIVIDE(SUM(retained_d1), COUNT(*)) * 100,
    2
  ) AS d1_retention_pct,

  SUM(retained_d7) AS retained_d7_players,
  ROUND(
    SAFE_DIVIDE(SUM(retained_d7), COUNT(*)) * 100,
    2
  ) AS d7_retention_pct,

  SUM(retained_d30) AS retained_d30_players,
  ROUND(
    SAFE_DIVIDE(SUM(retained_d30), COUNT(*)) * 100,
    2
  ) AS d30_retention_pct

FROM retention_flags

GROUP BY cohort_date
ORDER BY cohort_date;



-- ============================================================
-- 3. OVERALL RETENTION — ELIGIBLE COHORTS ONLY
--
-- We exclude cohorts that do not have enough future
-- observation time.
--
-- Dataset ends on 2018-10-03.
-- Therefore:
-- D1  eligible cohort <= 2018-10-02
-- D7  eligible cohort <= 2018-09-26
-- D30 eligible cohort <= 2018-09-03
-- ============================================================

WITH player_cohorts AS (
  SELECT
    user_pseudo_id,
    MIN(activity_date) AS cohort_date
  FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`
  GROUP BY user_pseudo_id
),

retention_flags AS (
  SELECT
    c.user_pseudo_id,
    c.cohort_date,

    MAX(
      CASE
        WHEN p.activity_date = DATE_ADD(c.cohort_date, INTERVAL 1 DAY)
        THEN 1 ELSE 0
      END
    ) AS retained_d1,

    MAX(
      CASE
        WHEN p.activity_date = DATE_ADD(c.cohort_date, INTERVAL 7 DAY)
        THEN 1 ELSE 0
      END
    ) AS retained_d7,

    MAX(
      CASE
        WHEN p.activity_date = DATE_ADD(c.cohort_date, INTERVAL 30 DAY)
        THEN 1 ELSE 0
      END
    ) AS retained_d30

  FROM player_cohorts c

  LEFT JOIN `mobile-game-product-analytics.game_analytics.player_daily_activity_v` p
    ON c.user_pseudo_id = p.user_pseudo_id

  GROUP BY
    c.user_pseudo_id,
    c.cohort_date
)

SELECT
  COUNTIF(cohort_date <= DATE '2018-10-02') AS d1_eligible_players,

  COUNTIF(
    cohort_date <= DATE '2018-10-02'
    AND retained_d1 = 1
  ) AS d1_retained_players,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        cohort_date <= DATE '2018-10-02'
        AND retained_d1 = 1
      ),
      COUNTIF(cohort_date <= DATE '2018-10-02')
    ) * 100,
    2
  ) AS overall_d1_retention_pct,


  COUNTIF(cohort_date <= DATE '2018-09-26') AS d7_eligible_players,

  COUNTIF(
    cohort_date <= DATE '2018-09-26'
    AND retained_d7 = 1
  ) AS d7_retained_players,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        cohort_date <= DATE '2018-09-26'
        AND retained_d7 = 1
      ),
      COUNTIF(cohort_date <= DATE '2018-09-26')
    ) * 100,
    2
  ) AS overall_d7_retention_pct,


  COUNTIF(cohort_date <= DATE '2018-09-03') AS d30_eligible_players,

  COUNTIF(
    cohort_date <= DATE '2018-09-03'
    AND retained_d30 = 1
  ) AS d30_retained_players,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        cohort_date <= DATE '2018-09-03'
        AND retained_d30 = 1
      ),
      COUNTIF(cohort_date <= DATE '2018-09-03')
    ) * 100,
    2
  ) AS overall_d30_retention_pct

FROM retention_flags;



-- ============================================================
-- 4. WEEKLY COHORT RETENTION
--
-- Business Question:
-- Are newer acquisition cohorts retaining differently?
--
-- Cohort week = first observed activity week.
-- ============================================================

WITH player_cohorts AS (
  SELECT
    user_pseudo_id,
    MIN(activity_date) AS cohort_date
  FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`
  GROUP BY user_pseudo_id
),

retention_flags AS (
  SELECT
    c.user_pseudo_id,
    c.cohort_date,

    MAX(
      CASE
        WHEN p.activity_date = DATE_ADD(c.cohort_date, INTERVAL 1 DAY)
        THEN 1 ELSE 0
      END
    ) AS retained_d1,

    MAX(
      CASE
        WHEN p.activity_date = DATE_ADD(c.cohort_date, INTERVAL 7 DAY)
        THEN 1 ELSE 0
      END
    ) AS retained_d7,

    MAX(
      CASE
        WHEN p.activity_date = DATE_ADD(c.cohort_date, INTERVAL 30 DAY)
        THEN 1 ELSE 0
      END
    ) AS retained_d30

  FROM player_cohorts c

  LEFT JOIN `mobile-game-product-analytics.game_analytics.player_daily_activity_v` p
    ON c.user_pseudo_id = p.user_pseudo_id

  GROUP BY
    c.user_pseudo_id,
    c.cohort_date
)

SELECT
  DATE_TRUNC(cohort_date, WEEK(MONDAY)) AS cohort_week,

  COUNT(*) AS cohort_size,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(retained_d1 = 1),
      COUNT(*)
    ) * 100,
    2
  ) AS d1_retention_pct,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        cohort_date <= DATE '2018-09-26'
        AND retained_d7 = 1
      ),
      COUNTIF(
        cohort_date <= DATE '2018-09-26'
      )
    ) * 100,
    2
  ) AS d7_retention_pct,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        cohort_date <= DATE '2018-09-03'
        AND retained_d30 = 1
      ),
      COUNTIF(
        cohort_date <= DATE '2018-09-03'
      )
    ) * 100,
    2
  ) AS d30_retention_pct

FROM retention_flags

GROUP BY cohort_week
ORDER BY cohort_week;



-- ============================================================
-- 5. LEVEL 27 EXPOSURE vs RETENTION
--
-- Exploratory association analysis.
--
-- Question:
-- Do players who reached Level 27 show different retention
-- behavior than players who did not?
--
-- IMPORTANT:
-- This is NOT causal.
-- Players reaching Level 27 are inherently more engaged,
-- so selection bias is expected.
-- ============================================================

WITH player_cohorts AS (
  SELECT
    user_pseudo_id,
    MIN(activity_date) AS cohort_date
  FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`
  GROUP BY user_pseudo_id
),

level27_flag AS (
  SELECT
    user_pseudo_id,
    MAX(
      CASE
        WHEN event_name = 'level_start'
         AND CAST(level AS INT64) = 27
        THEN 1 ELSE 0
      END
    ) AS reached_level_27

  FROM `mobile-game-product-analytics.game_analytics.cleaned_events_v`
  GROUP BY user_pseudo_id
),

retention_flags AS (
  SELECT
    c.user_pseudo_id,
    c.cohort_date,

    MAX(
      CASE
        WHEN p.activity_date = DATE_ADD(c.cohort_date, INTERVAL 1 DAY)
        THEN 1 ELSE 0
      END
    ) AS retained_d1,

    MAX(
      CASE
        WHEN p.activity_date = DATE_ADD(c.cohort_date, INTERVAL 7 DAY)
        THEN 1 ELSE 0
      END
    ) AS retained_d7,

    MAX(
      CASE
        WHEN p.activity_date = DATE_ADD(c.cohort_date, INTERVAL 30 DAY)
        THEN 1 ELSE 0
      END
    ) AS retained_d30

  FROM player_cohorts c

  LEFT JOIN `mobile-game-product-analytics.game_analytics.player_daily_activity_v` p
    ON c.user_pseudo_id = p.user_pseudo_id

  GROUP BY
    c.user_pseudo_id,
    c.cohort_date
)

SELECT
  COALESCE(l.reached_level_27, 0) AS reached_level_27,

  COUNT(*) AS players,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        r.cohort_date <= DATE '2018-10-02'
        AND r.retained_d1 = 1
      ),
      COUNTIF(
        r.cohort_date <= DATE '2018-10-02'
      )
    ) * 100,
    2
  ) AS d1_retention_pct,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        r.cohort_date <= DATE '2018-09-26'
        AND r.retained_d7 = 1
      ),
      COUNTIF(
        r.cohort_date <= DATE '2018-09-26'
      )
    ) * 100,
    2
  ) AS d7_retention_pct,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        r.cohort_date <= DATE '2018-09-03'
        AND r.retained_d30 = 1
      ),
      COUNTIF(
        r.cohort_date <= DATE '2018-09-03'
      )
    ) * 100,
    2
  ) AS d30_retention_pct

FROM retention_flags r

LEFT JOIN level27_flag l
  ON r.user_pseudo_id = l.user_pseudo_id

GROUP BY reached_level_27
ORDER BY reached_level_27 DESC;



-- ============================================================
-- 6. EARLY PROGRESSION vs RETENTION
--
-- Compare players who reached Level 10 with those who did not.
--
-- This is exploratory association, NOT causation.
-- ============================================================

WITH player_cohorts AS (
  SELECT
    user_pseudo_id,
    MIN(activity_date) AS cohort_date
  FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`
  GROUP BY user_pseudo_id
),

progression_flag AS (
  SELECT
    user_pseudo_id,

    MAX(
      CASE
        WHEN event_name = 'level_start'
         AND CAST(level AS INT64) >= 10
        THEN 1 ELSE 0
      END
    ) AS reached_level_10_plus

  FROM `mobile-game-product-analytics.game_analytics.cleaned_events_v`

  GROUP BY user_pseudo_id
),

retention_flags AS (
  SELECT
    c.user_pseudo_id,
    c.cohort_date,

    MAX(
      CASE
        WHEN p.activity_date = DATE_ADD(c.cohort_date, INTERVAL 1 DAY)
        THEN 1 ELSE 0
      END
    ) AS retained_d1,

    MAX(
      CASE
        WHEN p.activity_date = DATE_ADD(c.cohort_date, INTERVAL 7 DAY)
        THEN 1 ELSE 0
      END
    ) AS retained_d7,

    MAX(
      CASE
        WHEN p.activity_date = DATE_ADD(c.cohort_date, INTERVAL 30 DAY)
        THEN 1 ELSE 0
      END
    ) AS retained_d30

  FROM player_cohorts c

  LEFT JOIN `mobile-game-product-analytics.game_analytics.player_daily_activity_v` p
    ON c.user_pseudo_id = p.user_pseudo_id

  GROUP BY
    c.user_pseudo_id,
    c.cohort_date
)

SELECT
  COALESCE(p.reached_level_10_plus, 0)
    AS reached_level_10_plus,

  COUNT(*) AS players,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        r.cohort_date <= DATE '2018-10-02'
        AND r.retained_d1 = 1
      ),
      COUNTIF(
        r.cohort_date <= DATE '2018-10-02'
      )
    ) * 100,
    2
  ) AS d1_retention_pct,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        r.cohort_date <= DATE '2018-09-26'
        AND r.retained_d7 = 1
      ),
      COUNTIF(
        r.cohort_date <= DATE '2018-09-26'
      )
    ) * 100,
    2
  ) AS d7_retention_pct,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        r.cohort_date <= DATE '2018-09-03'
        AND r.retained_d30 = 1
      ),
      COUNTIF(
        r.cohort_date <= DATE '2018-09-03'
      )
    ) * 100,
    2
  ) AS d30_retention_pct

FROM retention_flags r

LEFT JOIN progression_flag p
  ON r.user_pseudo_id = p.user_pseudo_id

GROUP BY reached_level_10_plus
ORDER BY reached_level_10_plus DESC;