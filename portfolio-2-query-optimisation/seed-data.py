#!/usr/bin/env python3
"""
seed-data.py - Portfolio 2 (Query Processing and Optimisation)
Case study: LendDesk (lenddesk_users database)

Fills the lenddesk_users schema with synthetic but realistic data so that
query execution plans and index effects are measurable.

Default volume:
    50 organizations, 4 roles each, 11 permissions,
    50,000 users, 2,000,000 user_activity_logs rows.

Usage:
    pip install pymysql
    python3 seed-data.py --host 127.0.0.1 --user root --reset
    python3 seed-data.py --dry-run --users 100 --logs 1000     # no database needed

The password is read from the MYSQL_PWD environment variable or asked for
interactively. It is never passed on the command line.
"""
import argparse
import getpass
import os
import random
import sys
import time
import uuid
from datetime import datetime, timedelta

FIRST_NAMES = [
    "Adaeze", "Chinedu", "Ngozi", "Emeka", "Funke", "Tunde", "Aisha", "Ibrahim",
    "Zainab", "Yusuf", "Chioma", "Obinna", "Bisi", "Kunle", "Amaka", "Segun",
    "Halima", "Musa", "Ifeoma", "Femi", "Blessing", "David", "Grace", "Samuel",
    "Mary", "John", "Esther", "Daniel", "Ruth", "Peter",
]
LAST_NAMES = [
    "Okafor", "Adeyemi", "Bello", "Nwosu", "Okonkwo", "Balogun", "Abubakar",
    "Eze", "Ogunleye", "Lawal", "Ibrahim", "Chukwu", "Afolabi", "Danjuma",
    "Obi", "Adebayo", "Yakubu", "Onyeani", "Ojo", "Salami", "Umeh", "Aliyu",
    "Johnson", "Williams", "Akinwale", "Nnamdi", "Olawale", "Idris",
]
ORG_WORDS = [
    "Alpha", "Bravo", "Cedar", "Delta", "Eagle", "Falcon", "Granite", "Harbor",
    "Ivory", "Jade", "Kestrel", "Lagoon", "Meridian", "Nova", "Orion", "Pioneer",
    "Quartz", "Radiant", "Summit", "Terra", "Unity", "Vertex", "Willow", "Zenith",
    "Anchor", "Beacon", "Crest", "Dawn", "Ember", "Frontier", "Gateway", "Horizon",
    "Insight", "Junction", "Keystone", "Legacy", "Maple", "Noble", "Oasis", "Prime",
    "Regal", "Sterling", "Titan", "Upland", "Valor", "Wharf", "Apex", "Birch",
    "Coral", "Dune",
]

ROLE_NAMES = ["Admin", "Manager", "Officer", "Auditor"]

PERMISSIONS = [
    ("loan:view", "View loan records"),
    ("loan:create", "Create loan applications"),
    ("loan:approve", "Approve or reject loans"),
    ("repayment:view", "View repayments"),
    ("repayment:record", "Record repayments"),
    ("customer:view", "View customer profiles"),
    ("customer:edit", "Edit customer profiles"),
    ("report:export", "Export reports"),
    ("user:view", "View users"),
    ("user:manage", "Manage users and roles"),
    ("audit:view", "View audit logs"),
]

ROLE_PERMISSIONS = {
    "Admin": [p[0] for p in PERMISSIONS],
    "Manager": ["loan:view", "loan:create", "loan:approve", "user:view", "report:export"],
    "Officer": ["loan:view", "loan:create", "repayment:view", "repayment:record", "customer:view"],
    "Auditor": ["loan:view", "repayment:view", "customer:view", "report:export", "audit:view"],
}

# (action, weight, status codes with weights)
ACTIONS = [
    ("LOGIN", 22, [(200, 88), (401, 10), (403, 2)]),
    ("LOGOUT", 12, [(200, 100)]),
    ("VIEW_LOAN", 20, [(200, 97), (404, 3)]),
    ("CREATE_LOAN", 6, [(201, 94), (422, 5), (500, 1)]),
    ("APPROVE_LOAN", 4, [(200, 95), (403, 5)]),
    ("RECORD_REPAYMENT", 12, [(201, 96), (422, 3), (500, 1)]),
    ("VIEW_CUSTOMER", 12, [(200, 98), (404, 2)]),
    ("UPDATE_CUSTOMER", 5, [(200, 95), (422, 5)]),
    ("EXPORT_REPORT", 4, [(200, 90), (500, 10)]),
    ("PASSWORD_RESET", 3, [(200, 85), (429, 15)]),
]
ACTION_NAMES = [a[0] for a in ACTIONS]
ACTION_WEIGHTS = [a[1] for a in ACTIONS]
STATUS_BY_ACTION = {a[0]: ([s[0] for s in a[2]], [s[1] for s in a[2]]) for a in ACTIONS}

# A fixed fake bcrypt-looking value. These are not real credentials.
DUMMY_HASH = "$2b$12$" + "x" * 53


def batches(rows, size):
    batch = []
    for row in rows:
        batch.append(row)
        if len(batch) >= size:
            yield batch
            batch = []
    if batch:
        yield batch


def gen_orgs(n):
    """Organizations named like the normalisation example: Alpha Lending / slug alpha."""
    now = datetime.now()
    rows = []
    for i in range(n):
        word = ORG_WORDS[i % len(ORG_WORDS)]
        suffix = "" if i < len(ORG_WORDS) else f" {i // len(ORG_WORDS) + 1}"
        name = f"{word} Lending{suffix}"
        slug = f"{word.lower()}{suffix.strip()}"
        created = now - timedelta(days=random.randint(400, 1500))
        rows.append((str(uuid.uuid4()), name, slug, created))
    return rows


def gen_roles(orgs):
    rows = []
    for org in orgs:
        for name in ROLE_NAMES:
            rows.append((str(uuid.uuid4()), org[0], name))
    return rows


def gen_permissions():
    return [(str(uuid.uuid4()), name, desc) for name, desc in PERMISSIONS]


def gen_role_permissions(roles, permissions):
    pid = {p[1]: p[0] for p in permissions}
    rows = []
    for role in roles:
        for perm_name in ROLE_PERMISSIONS[role[2]]:
            rows.append((role[0], pid[perm_name]))
    return rows


def gen_users(n, orgs, roles):
    roles_by_org = {}
    for r in roles:
        roles_by_org.setdefault(r[1], []).append(r[0])
    now = datetime.now()
    rows = []
    for i in range(n):
        org = random.choice(orgs)
        first = random.choice(FIRST_NAMES)
        last = random.choice(LAST_NAMES)
        # index in the address guarantees (organization_id, email) is unique
        domain = f"{org[2]}lending.com"
        email = f"{first}.{last}.{i}@{domain}".lower()
        role_id = random.choice(roles_by_org[org[0]]) if random.random() > 0.01 else None
        is_active = 1 if random.random() > 0.08 else 0
        failed = 0 if random.random() < 0.9 else random.randint(1, 6)
        created = now - timedelta(days=random.randint(1, 700), seconds=random.randint(0, 86399))
        deleted = created + timedelta(days=random.randint(1, 200)) if random.random() < 0.03 else None
        if deleted and deleted > now:
            deleted = None
        rows.append((str(uuid.uuid4()), org[0], role_id, first, last, email,
                     DUMMY_HASH, is_active, failed, created, deleted))
    return rows


def gen_logs(n, user_ids):
    """Yield n log rows. A few users generate far more activity than the rest."""
    now = datetime.now()
    total = len(user_ids)
    for _ in range(n):
        # squaring skews picks toward the start of the list: heavy users exist
        uid = user_ids[int(total * (random.random() ** 2))]
        action = random.choices(ACTION_NAMES, ACTION_WEIGHTS)[0]
        codes, weights = STATUS_BY_ACTION[action]
        status = random.choices(codes, weights)[0]
        ts = now - timedelta(seconds=random.randint(0, 365 * 86400))
        yield (uid, action, status, ts)


def main():
    ap = argparse.ArgumentParser(description="Seed the lenddesk_users database")
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--port", type=int, default=3306)
    ap.add_argument("--user", default="root")
    ap.add_argument("--db", default="lenddesk_users")
    ap.add_argument("--orgs", type=int, default=50)
    ap.add_argument("--users", type=int, default=50_000)
    ap.add_argument("--logs", type=int, default=2_000_000)
    ap.add_argument("--batch", type=int, default=5000)
    ap.add_argument("--seed", type=int, default=8103)
    ap.add_argument("--reset", action="store_true", help="empty the tables first")
    ap.add_argument("--dry-run", action="store_true", help="generate data, do not touch a database")
    args = ap.parse_args()

    random.seed(args.seed)
    t0 = time.time()

    orgs = gen_orgs(args.orgs)
    roles = gen_roles(orgs)
    perms = gen_permissions()
    role_perms = gen_role_permissions(roles, perms)
    users = gen_users(args.users, orgs, roles)
    user_ids = [u[0] for u in users]

    print(f"organizations={len(orgs)} roles={len(roles)} permissions={len(perms)} "
          f"role_permissions={len(role_perms)} users={len(users)} logs={args.logs}")

    if args.dry_run:
        sample = list(gen_logs(5, user_ids))
        print("sample user:", users[0][3:6])
        print("sample logs:")
        for s in sample:
            print("  ", s)
        print(f"dry run finished in {time.time() - t0:.1f}s")
        return

    try:
        import pymysql
    except ImportError:
        sys.exit("pymysql is missing. Run: pip install pymysql")

    password = os.environ.get("MYSQL_PWD")
    if password is None:
        password = getpass.getpass(f"Password for {args.user}@{args.host}: ")
    conn = pymysql.connect(host=args.host, port=args.port, user=args.user,
                           password=password, database=args.db, autocommit=False)
    cur = conn.cursor()
    cur.execute("SET SESSION foreign_key_checks=0")
    cur.execute("SET SESSION unique_checks=0")

    if args.reset:
        for table in ["user_activity_logs", "role_permissions", "users",
                      "roles", "permissions", "organizations"]:
            cur.execute(f"TRUNCATE TABLE {table}")
        conn.commit()
        print("tables emptied")

    def load(table, columns, rows, total=None):
        sql = f"INSERT INTO {table} ({columns}) VALUES ({', '.join(['%s'] * (columns.count(',') + 1))})"
        done = 0
        start = time.time()
        for batch in batches(rows, args.batch):
            cur.executemany(sql, batch)
            conn.commit()
            done += len(batch)
            if total and done % (args.batch * 20) == 0:
                rate = done / (time.time() - start)
                print(f"  {table}: {done:,}/{total:,} ({rate:,.0f} rows/s)")
        print(f"{table}: {done:,} rows loaded in {time.time() - start:.1f}s")

    load("organizations", "id, name, slug, created_at", orgs)
    load("roles", "id, organization_id, name", roles)
    load("permissions", "id, name, description", perms)
    load("role_permissions", "role_id, permission_id", role_perms)
    load("users",
         "id, organization_id, role_id, first_name, last_name, email, password_hash, "
         "is_active, failed_logins, created_at, deleted_at",
         users, total=len(users))
    load("user_activity_logs", "user_id, action, status_code, created_at",
         gen_logs(args.logs, user_ids), total=args.logs)

    cur.execute("SET SESSION unique_checks=1")
    cur.execute("SET SESSION foreign_key_checks=1")
    print("updating table statistics for the optimiser...")
    for table in ["organizations", "roles", "permissions", "role_permissions",
                  "users", "user_activity_logs"]:
        cur.execute(f"ANALYZE TABLE {table}")
        cur.fetchall()
    conn.commit()
    conn.close()
    print(f"done in {time.time() - t0:.1f}s")


if __name__ == "__main__":
    main()
