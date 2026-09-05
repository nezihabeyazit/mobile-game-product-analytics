CREATE OR REPLACE VIEW
`mobile-game-product-analytics.game_analytics.bi_weekly_retention_v`
AS

WITH player_cohorts AS (

  SELECT
    user_pseudo_id,
    MIN(activity_date) AS cohort_date

  FROM
    `mobile-game-product-analytics.game_analytics.player_daily_activity_v`

  GROUP BY user_pseudo_id
),

retention_flags AS (

  SELECT
    c.user_pseudo_id,
    c.cohort_date,

    MAX(
      CASE
        WHEN p.activity_date =
             DATE_ADD(c.cohort_date, INTERVAL 1 DAY)
        THEN 1 ELSE 0
      END
    ) AS retained_d1,

    MAX(
      CASE
        WHEN p.activity_date =
             DATE_ADD(c.cohort_date, INTERVAL 7 DAY)
        THEN 1 ELSE 0
      END
    ) AS retained_d7,

    MAX(
      CASE
        WHEN p.activity_date =
             DATE_ADD(c.cohort_date, INTERVAL 30 DAY)
        THEN 1 ELSE 0
      END
    ) AS retained_d30

  FROM player_cohorts c

  LEFT JOIN
    `mobile-game-product-analytics.game_analytics.player_daily_activity_v` p
    ON c.user_pseudo_id = p.user_pseudo_id

  GROUP BY
    c.user_pseudo_id,
    c.cohort_date
)

SELECT
  DATE_TRUNC(
    cohort_date,
    WEEK(MONDAY)
  ) AS cohort_week,

  COUNT(*) AS cohort_size,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        cohort_date <= DATE '2018-10-02'
        AND retained_d1 = 1
      ),
      COUNTIF(
        cohort_date <= DATE '2018-10-02'
      )
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

GROUP BY cohort_week;