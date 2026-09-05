CREATE OR REPLACE VIEW
`mobile-game-product-analytics.game_analytics.bi_level_funnel_v`
AS

WITH level_players AS (

  SELECT
    user_pseudo_id,
    CAST(level AS INT64) AS level,

    MAX(
      CASE
        WHEN event_name = 'level_start'
        THEN 1 ELSE 0
      END
    ) AS started,

    MAX(
      CASE
        WHEN event_name = 'level_complete'
        THEN 1 ELSE 0
      END
    ) AS completed,

    MAX(
      CASE
        WHEN event_name = 'level_fail'
        THEN 1 ELSE 0
      END
    ) AS failed

  FROM
    `mobile-game-product-analytics.game_analytics.cleaned_events_v`

  WHERE event_name IN (
    'level_start',
    'level_complete',
    'level_fail'
  )

    AND level IS NOT NULL

  GROUP BY
    user_pseudo_id,
    level
),

reached AS (

  SELECT DISTINCT
    user_pseudo_id,
    CAST(level AS INT64) AS level

  FROM
    `mobile-game-product-analytics.game_analytics.cleaned_events_v`

  WHERE event_name = 'level_start'
    AND level IS NOT NULL
),

progression AS (

  SELECT
    a.level,

    COUNT(DISTINCT a.user_pseudo_id)
      AS players_at_level,

    COUNT(DISTINCT b.user_pseudo_id)
      AS players_reaching_next_level

  FROM reached a

  LEFT JOIN reached b
    ON a.user_pseudo_id = b.user_pseudo_id
   AND b.level = a.level + 1

  GROUP BY a.level
)

SELECT
  l.level,

  COUNTIF(l.started = 1)
    AS players_started,

  COUNTIF(
    l.started = 1
    AND l.completed = 1
  ) AS players_completed,

  COUNTIF(
    l.started = 1
    AND l.failed = 1
  ) AS players_failed,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        l.started = 1
        AND l.completed = 1
      ),
      COUNTIF(l.started = 1)
    ) * 100,
    2
  ) AS completion_pct,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        l.started = 1
        AND l.failed = 1
      ),
      COUNTIF(l.started = 1)
    ) * 100,
    2
  ) AS failure_pct,

  p.players_reaching_next_level,

  ROUND(
    (
      1 -
      SAFE_DIVIDE(
        p.players_reaching_next_level,
        p.players_at_level
      )
    ) * 100,
    2
  ) AS dropoff_pct

FROM level_players l

JOIN progression p
  ON l.level = p.level

GROUP BY
  l.level,
  p.players_at_level,
  p.players_reaching_next_level;