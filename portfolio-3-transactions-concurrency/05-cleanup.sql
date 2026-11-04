-- Remove the demo data created for Portfolio 3
USE lenddesk_users;
DELETE FROM user_activity_logs WHERE user_id LIKE 'demo-user-%';
DELETE FROM users WHERE id LIKE 'demo-user-%';
