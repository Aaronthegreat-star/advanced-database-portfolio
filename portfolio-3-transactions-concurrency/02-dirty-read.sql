-- Portfolio 3, part 2: isolation level and the dirty read (screenshot 03-dirty-read.png, taken in B).
-- Two HeidiSQL windows, A and B (SELECT CONNECTION_ID() must differ).
-- Reset first:  UPDATE users SET failed_logins = 0 WHERE id = 'demo-user-b';

-- [A] press F9 first, then switch to B at once:
USE lenddesk_users;
START TRANSACTION;
UPDATE users SET failed_logins = 9 WHERE id = 'demo-user-b';
DO SLEEP(25);
ROLLBACK;

-- [B] press F9 within 20 seconds:
-- USE lenddesk_users;
-- SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- START TRANSACTION;
-- SELECT failed_logins INTO @first FROM users WHERE id = 'demo-user-b';
-- DO SLEEP(30);
-- SELECT @first AS first_read, failed_logins AS second_read FROM users WHERE id = 'demo-user-b';
-- COMMIT;
-- Result in B: first_read 9 (uncommitted data), second_read 0 (A rolled back)

-- Afterwards, in both windows:
-- SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
