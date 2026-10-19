# Case Study: User and Access Management Database for a Loan Management SaaS Platform

## 1. Organisation / Scenario
**LendDesk** (a simulated organisation) is a multi-tenant Software-as-a-Service
platform that helps lending institutions manage their loan operations. The
scenario is inspired by a real class of fintech systems, but all names, data
and structures in this portfolio are simulated and simplified.

This portfolio focuses on one part of that platform: the **user and access
management database**, which controls who can log in, what they belong to,
and what they are allowed to do.

## 2. Nature of the Business / System
LendDesk serves many independent lending organisations (tenants) on one shared
platform. Each organisation has staff who log in to review loan applications,
manage customers and track repayments. Because many organisations share one
system, the database must:
- keep each organisation's users separate (multi-tenancy),
- control access through roles and permissions,
- keep a reliable record of user activity for security and audit.

## 3. Users of the Database
| User | How they use the database |
|---|---|
| Platform administrator | Creates organisations, manages roles and permissions |
| Organisation staff | Log in and work within the permissions of their role |
| Authentication service | Validates credentials, checks permissions, records login attempts |
| Auditor / compliance officer | Reviews activity logs |
| Reporting analyst | Queries usage statistics |

## 4. Major Data to Be Stored
- **Organisations:** name, unique identifier (slug), creation date
- **Users:** name, email, hashed password, status, failed login count, organisation, role
- **Roles:** name, belonging to one organisation
- **Permissions:** named actions such as `loan:view` or `user:create`
- **Role-permission assignments:** which role holds which permissions
- **User activity logs:** user, action performed, result status, timestamp (a large, fast-growing table)

## 5. Key Operations the Database Will Support
1. Register a new user in an organisation and assign a role.
2. Authenticate a user and verify their permissions at login.
3. Lock an account after repeated failed logins, and reactivate it.
4. Create roles and assign or remove permissions.
5. Record every significant user action in the activity log.
6. Report on activity: most active users, activity per organisation, users without roles.
7. Remove or deactivate users without breaking the audit history.

## 6. Why This Case Study Suits the Portfolio
| Portfolio | How the case study supports it |
|---|---|
| 1. Design | Clear entities, one-to-many and many-to-many relationships, strong normalisation example (roles and permissions) |
| 2. Query optimisation | The activity log grows to hundreds of thousands of rows, so indexing and execution plans show real impact |
| 3. Transactions | Concurrent login attempts and role changes demonstrate locking, isolation and rollback |
| 4. NoSQL | Activity logs with variable details suit a document store; sessions suit key-value |
| 5. Distributed and cloud | Multi-tenant data supports sharding by organisation; login reads suit replicas |

## 7. Assumptions and Scope
- All data is dummy data generated for this assignment.
- No real customer, employee or company data is used.
- The scope is limited to six core tables so the work stays deep rather than broad.
- The DBMS used is MySQL 8, with MongoDB and Redis for the NoSQL portfolio.
