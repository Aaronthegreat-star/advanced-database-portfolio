-- Portfolio 2: query tested (run in HeidiSQL against lenddesk_users)
USE lenddesk_users;

-- Reference point: newest log time, so the 30-day window is repeatable
SET @ref = (SELECT MAX(created_at) FROM user_activity_logs);

-- Q1: the 10 most active users in the last 30 days
SELECT user_id, COUNT(*) AS actions
FROM user_activity_logs
WHERE created_at >= @ref - INTERVAL 30 DAY
GROUP BY user_id
ORDER BY actions DESC
LIMIT 10;

-- Execution plan for Q1 (run the same query with EXPLAIN in front)
EXPLAIN
SELECT user_id, COUNT(*) AS actions
FROM user_activity_logs
WHERE created_at >= @ref - INTERVAL 30 DAY
GROUP BY user_id
ORDER BY actions DESC
LIMIT 10;
