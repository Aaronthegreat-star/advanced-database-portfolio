-- Portfolio 3, part 1: COMMIT and ROLLBACK (one HeidiSQL tab).
USE lenddesk_users;

-- 1. COMMIT: onboard a user and log it as one unit of work (screenshot 01-commit.png)
START TRANSACTION;
INSERT INTO users (id, organization_id, role_id, first_name, last_name, email, password_hash)
SELECT 'demo-user-c', o.id, r.id, 'Chika', 'Eze', 'chika.eze@alphalending.com', 'x'
FROM organizations o JOIN roles r ON r.organization_id = o.id AND r.name = 'Officer'
WHERE o.slug = 'alpha';
INSERT INTO user_activity_logs (user_id, action, status_code) VALUES ('demo-user-c', 'USER_CREATED', 201);
COMMIT;
SELECT u.email, l.action, l.status_code
FROM users u JOIN user_activity_logs l ON l.user_id = u.id WHERE u.id = 'demo-user-c';

-- 2. ROLLBACK: a mistaken bulk update is undone (screenshot 02-rollback.png)
SELECT COUNT(*) AS active_before FROM users
WHERE organization_id = (SELECT id FROM organizations WHERE slug = 'alpha') AND is_active = 1;
START TRANSACTION;
UPDATE users SET is_active = 0 WHERE organization_id = (SELECT id FROM organizations WHERE slug = 'alpha');
SELECT COUNT(*) AS active_inside_transaction FROM users
WHERE organization_id = (SELECT id FROM organizations WHERE slug = 'alpha') AND is_active = 1;
ROLLBACK;
SELECT COUNT(*) AS active_after_rollback FROM users
WHERE organization_id = (SELECT id FROM organizations WHERE slug = 'alpha') AND is_active = 1;
