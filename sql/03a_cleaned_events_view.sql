SELECT
  COUNT(*) AS event_rows,
  COUNT(DISTINCT user_pseudo_id) AS unique_players,
  MIN(event_date) AS first_date,
  MAX(event_date) AS last_date
FROM `mobile-game-product-analytics.game_analytics.cleaned_events_v`;