// Creates: organizations (5), users (200, with the role and its permissions embedded),
// and user_activity_logs (20,000). The data is generated test data, not real customer data.
//
//   docker cp 01-seed.js lenddesk-mongo:/seed.js
//   docker exec -it lenddesk-mongo mongosh --file /seed.js

db = db.getSiblingDB("lenddesk_nosql");
db.dropDatabase();
db = db.getSiblingDB("lenddesk_nosql");

const pick = (arr) => arr[Math.floor(Math.random() * arr.length)];
const daysAgo = (n) => new Date(Date.now() - Math.floor(Math.random() * n * 86400000));

const orgWords = ["Alpha", "Bravo", "Cedar", "Delta", "Eagle"];
const firstNames = ["Adaeze", "Chinedu", "Ngozi", "Emeka", "Funke", "Tunde", "Aisha", "Ibrahim", "Zainab", "Yusuf", "Chioma", "Obinna"];
const lastNames = ["Okafor", "Adeyemi", "Bello", "Nwosu", "Okonkwo", "Balogun", "Abubakar", "Eze", "Ogunleye", "Lawal"];

// The same roles and permissions as the relational design (Portfolio 1)
const roles = {
  Admin: ["loan:view", "loan:create", "loan:approve", "repayment:view", "repayment:record",
          "customer:view", "customer:edit", "report:export", "user:view", "user:manage", "audit:view"],
  Manager: ["loan:view", "loan:create", "loan:approve", "user:view", "report:export"],
  Officer: ["loan:view", "loan:create", "repayment:view", "repayment:record", "customer:view"],
  Auditor: ["loan:view", "repayment:view", "customer:view", "report:export", "audit:view"]
};
const roleNames = Object.keys(roles);

// activity: [action, status codes]
const activities = [
  ["LOGIN", [200, 200, 200, 401, 403]],
  ["LOGOUT", [200]],
  ["VIEW_LOAN", [200, 200, 404]],
  ["CREATE_LOAN", [201, 201, 422]],
  ["APPROVE_LOAN", [200, 403]],
  ["RECORD_REPAYMENT", [201, 201, 422]],
  ["VIEW_CUSTOMER", [200]],
  ["EXPORT_REPORT", [200, 500]]
];

// organizations
const organizations = orgWords.map((w) => ({
  _id: w.toLowerCase(),
  name: w + " Lending",
  slug: w.toLowerCase(),
  createdAt: daysAgo(1000)
}));
db.organizations.insertMany(organizations);

// users: the role and its permissions are embedded in each user document
const users = [];
for (let i = 0; i < 200; i++) {
  const org = pick(organizations);
  const first = pick(firstNames);
  const last = pick(lastNames);
  const roleName = pick(roleNames);
  users.push({
    organizationId: org._id,
    firstName: first,
    lastName: last,
    email: (first + "." + last + "." + i + "@" + org.slug + "lending.com").toLowerCase(),
    role: { name: roleName, permissions: roles[roleName] },
    isActive: Math.random() > 0.08,
    failedLogins: Math.random() < 0.9 ? 0 : Math.floor(Math.random() * 6) + 1,
    createdAt: daysAgo(700)
  });
}
// one known user, so the example queries are easy to read
users.push({
  organizationId: "alpha",
  firstName: "Ada",
  lastName: "Obi",
  email: "ada.obi@alphalending.com",
  role: { name: "Officer", permissions: roles.Officer },
  isActive: true,
  failedLogins: 0,
  createdAt: new Date()
});
db.users.insertMany(users);

// activity logs: a separate collection, because it grows without limit
const userDocs = db.users.find({}, { _id: 1, organizationId: 1 }).toArray();
const logs = [];
for (let i = 0; i < 20000; i++) {
  const u = pick(userDocs);
  const a = pick(activities);
  logs.push({
    userId: u._id,
    organizationId: u.organizationId,
    action: a[0],
    statusCode: pick(a[1]),
    createdAt: daysAgo(90)
  });
}
db.user_activity_logs.insertMany(logs);

print("organizations: " + db.organizations.countDocuments());
print("users:         " + db.users.countDocuments());
print("activity logs: " + db.user_activity_logs.countDocuments());
