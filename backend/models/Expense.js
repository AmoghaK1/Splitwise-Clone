const mongoose = require("mongoose");

const expenseSchema = new mongoose.Schema({
  groupId: { type: mongoose.Schema.Types.ObjectId, ref: 'Group', required: true },
  description: { type: String, required: true },
  amount: { type: Number, required: true },
  paidBy: { type: String, required: true }, // Firebase UID
  splitBetween: { type: [String], required: true }, // Array of Firebase UIDs
  splitType: { type: String, enum: ['equal', 'unequal'], default: 'equal' },
  splitMethod: { type: String, enum: ['amount', 'percentage'], default: 'amount' },
  unequalShares: { type: Map, of: Number }, // Map of user IDs to their share amounts
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model("Expense", expenseSchema);
