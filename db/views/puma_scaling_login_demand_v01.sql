-- This view calculates a 30-day rolling average of distinct successful logins
-- to inform KEDA's Puma worker scaling decisions. It answers the question:
-- "Based on recent login patterns, what is the average number of unique users
-- we can expect to log in during the current 3-hour block?"
--
-- The calculation is broken down into several steps:
--
-- 1. `current_context`: Establishes a fixed "now" (e.g., Tuesday at 10:30 UTC).
--    It captures the current hour, day, and day-of-the-week for all subsequent
--    calculations.
--
-- 2. `demand_window`: Defines the 3-hour block of interest centered on the
--    current hour. For 10:30, this window would be 09:00 to 12:00.
--
-- 3. `historical_windows`: Generates a list of identical 3-hour windows for
--    every matching day-of-the-week over the past 30 days. For example, it
--    finds all previous Tuesdays and defines a 09:00-12:00 window for each.
--
-- 4. `historical_window_counts`: Counts the number of distinct (unique) users
--    with successful logins within each of these historical windows. A user
--    who logs in multiple times within one window is only counted once.
--
-- 5. Final `SELECT`: Averages the counts from all the historical windows to
--    produce the final metric. A `LEFT JOIN` and `COALESCE` ensure that days
--    with zero logins are correctly included in the average.
WITH current_context AS (
  -- Capture current time references truncated to the hour and day (UTC).
  SELECT
    now() AT TIME ZONE 'UTC' AS current_time,
    date_trunc('day', now() AT TIME ZONE 'UTC') AS current_day,
    date_trunc('hour', now() AT TIME ZONE 'UTC') AS current_hour,
    EXTRACT(dow FROM now() AT TIME ZONE 'UTC')::int AS current_dow
),
demand_window AS (
  -- Represent the three-hour demand window and its offsets relative to the day boundary.
  SELECT
    current_time,
    current_day,
    current_dow,
    (current_hour - INTERVAL '1 hour') AS window_start,
    (current_hour + INTERVAL '2 hours') AS window_end,
    (current_hour - INTERVAL '1 hour') - current_day AS window_start_offset,
    (current_hour + INTERVAL '2 hours') - current_day AS window_end_offset
  FROM current_context
),
historical_windows AS (
  -- Generate matching historical windows (same weekday) across the trailing 30 days.
  SELECT
    series_day::date AS window_day,
    (series_day + window_start_offset) AS window_start,
    (series_day + window_end_offset) AS window_end
  FROM demand_window
  CROSS JOIN LATERAL generate_series(
    current_day - INTERVAL '30 days',
    current_day - INTERVAL '1 day',
    INTERVAL '1 day'
  ) AS series_day
  WHERE EXTRACT(dow FROM series_day) = current_dow
),
historical_window_counts AS (
  -- Count distinct successful logins within each historical window.
  SELECT
    window_day,
    COUNT(DISTINCT login_activities.user_id) AS distinct_logins
  FROM historical_windows
  LEFT JOIN login_activities
    ON login_activities.success = true
   AND login_activities.created_at >= historical_windows.window_start
   AND login_activities.created_at < historical_windows.window_end
  GROUP BY window_day
)
SELECT
  COALESCE(AVG(distinct_logins)::numeric, 0) AS projected_unique_users
FROM historical_window_counts;
