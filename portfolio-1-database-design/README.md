# Portfolio 1: Database Design and Modelling

Database: `lenddesk_users`, the users service database of the simulated
LendDesk loan management platform. All data is simulated.

## Contents
| File | Contents |
|---|---|
| case-study.md | Scenario, users, data stored and key operations |
| er-diagram.md / er-diagram.png | Entity-relationship diagram and relationship descriptions |
| schema.sql | Relational schema (MySQL 8) with keys and constraints |
| keys-and-constraints.md | Primary keys, foreign keys, constraints and the reasoning |
| normalisation.md | Walkthrough from unnormalised data to 3NF |

## How to run
```bash
mysql -u root -p < schema.sql
```
Then check with `SHOW TABLES;` and `SHOW CREATE TABLE users;` in the
`lenddesk_users` database.

## Tested on
MySQL 8.x. Screenshots of the results are in `screenshots/`.

## Design summary
- Six tables: organizations, roles, permissions, users, role_permissions, user_activity_logs
- UUID primary keys for business tables, BIGINT for the high-volume log table
- Roles and permissions are many-to-many through `role_permissions`
- Users are soft-deleted to keep the audit history
