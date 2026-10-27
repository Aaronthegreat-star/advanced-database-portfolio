# Normalisation

This shows how the design was reached, starting from one unnormalised table.

## Unnormalised starting table (UNF)
| user_id | user_name | email | org_name | org_slug | role_name | permissions |
|---|---|---|---|---|---|---|
| U1 | Ada Obi | ada.obi@alphalending.com | Alpha Lending | alpha | Manager | loan:view, loan:create, user:view |
| U2 | Tunde Bello | tunde.bello@alphalending.com | Alpha Lending | alpha | Officer | loan:view |

Problems:
- **Repeating group:** the permissions column holds several values.
- **Redundancy:** organisation data repeats for every user.
- **Update anomaly:** renaming an organisation means changing many rows.
- **Insert anomaly:** a role cannot exist until a user has it.
- **Delete anomaly:** deleting the last user of a role loses that role's permissions.

## First normal form (1NF)
Rule: every column holds one atomic value; no repeating groups.

The permissions list is split into one row per permission. The key becomes
(user_id, permission_name).

| user_id | permission_name | user_name | email | org_name | org_slug | role_name |
|---|---|---|---|---|---|---|
| U1 | loan:view | Ada Obi | ada.obi@alphalending.com  | Alpha Lending | alpha | Manager |
| U1 | loan:create | Ada Obi | ada.obi@alphalending.com  | Alpha Lending | alpha | Manager |
| U1 | user:view | Ada Obi | ada.obi@alphalending.com  | Alpha Lending | alpha | Manager |
| U2 | loan:view | Tunde Bello | tunde.bello@alphalending.com | Alpha Lending | alpha | Officer |

## Second normal form (2NF)
Rule: 1NF, and no non-key column depends on only part of a composite key.

With the key (user_id, permission_name):
- user_name, email, org_name, org_slug and role_name depend on **user_id only**.
- Permission details depend on **permission_name only**.

These are partial dependencies, so the table is split:
- `users` (user_id, name, email, organisation, role)
- `permissions` (permission_name)
- a link table between roles and permissions

## Third normal form (3NF)
Rule: 2NF, and no non-key column depends on another non-key column.

- org_name and org_slug depend on the organisation, not the user
  (user_id -> organization_id -> org_name). They move to `organizations`.
- Permissions depend on the role, not the user
  (user_id -> role_id -> permissions). They move to `role_permissions`.

## Final design
`organizations`, `roles`, `permissions`, `users`, `role_permissions`,
`user_activity_logs` (see `schema.sql`). Every non-key column depends on the
key, the whole key and nothing but the key.

## Anomalies removed
| Anomaly | Before | After |
|---|---|---|
| Update | Rename an organisation in every user row | One row in `organizations` |
| Insert | A role needs a user to exist | A role or permission can exist on its own |
| Delete | Removing a user loses organisation data | Organisation data is stored once |

## Note on BCNF
All determinants are candidate keys in the final tables, so the design is also
in Boyce-Codd normal form.
