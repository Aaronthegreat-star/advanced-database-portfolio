-- Portfolio 3, part 4: deadlock (screenshot 06-deadlock.png, taken in the window that gets the error).
-- Reset first:  UPDATE users SET failed_logins = 0 WHERE id IN ('demo-user-a', 'demo-user-b');

-- [A] press F9 first:
USE lenddesk_users;
START TRANSACTION;
UPDATE users SET failed_logins = 1 WHERE id = 'demo-user-a';
DO SLEEP(10);
UPDATE users SET failed_logins = 2 WHERE id = 'demo-user-b';
COMMIT;

-- [B] press F9 within 5 seconds:
USE lenddesk_users;
START TRANSACTION;
UPDATE users SET failed_logins = 1 WHERE id = 'demo-user-b';
DO SLEEP(3);
UPDATE users SET failed_logins = 2 WHERE id = 'demo-user-a';
COMMIT;
-- Each session waits for the row the other holds. MySQL detects the cycle and returns
-- ERROR 1213 (Deadlock found when trying to get lock) to one session, which is rolled back.
-- The other session finishes. Prevention: lock rows in the same order every time.
