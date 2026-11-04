-- Portfolio 3, part 3: lost update (problem) and SELECT ... FOR UPDATE (control).
-- Two HeidiSQL windows. Two failed logins for one user at once: failed_logins should go 0 -> 2.
-- Reset before each test:  UPDATE users SET failed_logins = 0 WHERE id = 'demo-user-a';

-- ===== PROBLEM: lost update (screenshot 04-lost-update.png, taken in A) =====
-- [A] press F9 first:
USE lenddesk_users;
START TRANSACTION;
SELECT failed_logins INTO @v FROM users WHERE id = 'demo-user-a';
DO SLEEP(25);
UPDATE users SET failed_logins = @v + 1 WHERE id = 'demo-user-a';
COMMIT;
SELECT failed_logins AS final_value FROM users WHERE id = 'demo-user-a';

-- [B] press F9 within the 25 seconds:
USE lenddesk_users;
START TRANSACTION;
SELECT failed_logins INTO @v FROM users WHERE id = 'demo-user-a';
UPDATE users SET failed_logins = @v + 1 WHERE id = 'demo-user-a';
COMMIT;
Result in A: final_value 1 (should be 2: one update was lost)

-- ===== CONTROL: SELECT ... FOR UPDATE (screenshot 05-for-update.png, taken in B) =====
-- Reset first. Same scripts, but both SELECT lines end with FOR UPDATE, and B ends with
-- SELECT failed_logins AS final_value FROM users WHERE id = 'demo-user-a';
-- B waits for A's lock (about 25 s in the log). Result in B: final_value 2 (correct).
