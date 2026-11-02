-- Portfolio 2: optimisation
-- Run AFTER the "before" evidence (screenshots 01 and 02) has been taken.
USE lenddesk_users;

-- Q1: range filter on created_at, user_id included so the index covers the query
CREATE INDEX idx_logs_created_user
  ON user_activity_logs (created_at, user_id);

-- Refresh the optimiser statistics
ANALYZE TABLE user_activity_logs;

-- Roll back (to repeat the experiment):
-- DROP INDEX idx_logs_created_user ON user_activity_logs;
