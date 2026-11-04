-- Portfolio 3: setup. Creates two demo users in "Alpha Lending" with fixed ids.
USE lenddesk_users;

-- Step 1: clear leftovers from any earlier run (only deletes).
DELETE FROM user_activity_logs WHERE user_id LIKE 'demo-user-%';
DELETE FROM users WHERE id LIKE 'demo-user-%' OR email LIKE 'demo.%@alphalending.com' OR email = 'chika.eze@alphalending.com';

-- Step 2: insert exactly two demo users: demo-user-a and demo-user-b.
INSERT INTO users (id, organization_id, role_id, first_name, last_name, email, password_hash, failed_logins)
SELECT CONCAT('demo-user-', x.n), o.id, r.id, 'Demo', UPPER(x.n), CONCAT('demo.', x.n, '@alphalending.com'), 'x', 0
FROM organizations o
JOIN roles r ON r.organization_id = o.id AND r.name = 'Officer'
JOIN (SELECT 'a' AS n UNION SELECT 'b') x
WHERE o.slug = 'alpha';

SELECT id, email, failed_logins FROM users WHERE id LIKE 'demo-user-%';
