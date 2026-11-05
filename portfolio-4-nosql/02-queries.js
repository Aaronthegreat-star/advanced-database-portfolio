// 1. One user, with the role and every permission, in a single read (no joins)
db.users.findOne({ email: "ada.obi@alphalending.com" })

// 2. Active users per organization (aggregation pipeline)
db.users.aggregate([
  { $match: { isActive: true } },
  { $group: { _id: "$organizationId", activeUsers: { $sum: 1 } } },
  { $sort: { activeUsers: -1 } }
])

// 3. Failed logins in the last 7 days, per user (top 5)
db.user_activity_logs.aggregate([
  { $match: { action: "LOGIN", statusCode: { $in: [401, 403] },
              createdAt: { $gte: new Date(Date.now() - 7 * 86400000) } } },
  { $group: { _id: "$userId", failures: { $sum: 1 } } },
  { $sort: { failures: -1 } },
  { $limit: 5 }
])

// 4. Atomic update of one document (the lost-update problem from Portfolio 3 cannot happen here)
db.users.updateOne({ email: "ada.obi@alphalending.com" }, { $inc: { failedLogins: 1 } })
db.users.findOne({ email: "ada.obi@alphalending.com" }, { email: 1, failedLogins: 1 })

// 5. Indexing in MongoDB: the same query before and after an index (compare totalDocsExamined)
const someUser = db.users.findOne({ email: "ada.obi@alphalending.com" })._id;
db.user_activity_logs.find({ userId: someUser }).sort({ createdAt: -1 }).limit(10).explain("executionStats")
// look at: executionStats.totalDocsExamined and the winning plan stage (COLLSCAN)

db.user_activity_logs.createIndex({ userId: 1, createdAt: -1 })
db.user_activity_logs.find({ userId: someUser }).sort({ createdAt: -1 }).limit(10).explain("executionStats")
// look at: the winning plan stage is now IXSCAN, and totalDocsExamined is much smaller
