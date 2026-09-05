CREATE OR REPLACE VIEW
`mobile-game-product-analytics.game_analytics.bi_activation_segments_v`
AS

WITH player_stats AS (

  SELECT
    user_pseudo_id,
    COUNT(*) AS active_days

  FROM
    `mobile-game-product-analytics.game_analytics.player_daily_activity_v`

  GROUP BY user_pseudo_id
),

gameplay_flags AS (

  SELECT
    user_pseudo_id,

    MAX(
      CASE
        WHEN event_name IN (
          'level_start',
          'level_start_quickplay'
        )
        THEN 1 ELSE 0
      END
    ) AS started_gameplay,

    MAX(
      CASE
        WHEN event_name IN (
          'level_complete',
          'level_complete_quickplay'
        )
        THEN 1 ELSE 0
      END
    ) AS completed_gameplay

  FROM
    `mobile-game-product-analytics.game_analytics.cleaned_events_v`

  GROUP BY user_pseudo_id
)

SELECT
  CASE
    WHEN p.active_days = 1
      THEN '1-day player'
    ELSE '2+ day player'
  END AS player_segment,

  COUNT(*) AS players,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(g.started_gameplay = 1),
      COUNT(*)
    ) * 100,
    2
  ) AS gameplay_start_pct,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(g.completed_gameplay = 1),
      COUNT(*)
    ) * 100,
    2
  ) AS gameplay_complete_pct

FROM player_stats p

LEFT JOIN gameplay_flags g
  ON p.user_pseudo_id = g.user_pseudo_id

GROUP BY player_segment;