CREATE OR REPLACE VIEW
  `mobile-game-product-analytics.game_analytics.player_daily_activity_v`
AS

SELECT
  user_pseudo_id,
  event_date AS activity_date,

  ANY_VALUE(platform) AS platform,
  ANY_VALUE(country) AS country,
  ANY_VALUE(traffic_source) AS traffic_source,
  ANY_VALUE(traffic_medium) AS traffic_medium,

  COUNT(*) AS event_count,

  COUNTIF(event_name = 'session_start') AS session_starts,

  COUNTIF(
    event_name IN ('level_start', 'level_start_quickplay')
  ) AS level_starts,

  COUNTIF(
    event_name IN ('level_complete', 'level_complete_quickplay')
  ) AS level_completes,

  COUNTIF(
    event_name IN ('level_fail', 'level_fail_quickplay')
  ) AS level_fails,

  COUNTIF(event_name = 'user_engagement') AS engagement_events

FROM `mobile-game-product-analytics.game_analytics.cleaned_events_v`

GROUP BY
  user_pseudo_id,
  event_date;