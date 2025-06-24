const Expense = require("../models/Expense");
const Group = require("../models/Group");
const { BadRequestError, NotFoundError } = require("../utils/errors");

exports.addExpense = async ({ groupId, description, amount, paidBy, splitBetween, splitType, unequalShares, splitMethod }) => {
  if (!groupId || !description || !amount || !paidBy || !splitBetween || splitBetween.length === 0) {
    throw new BadRequestError("Missing required fields");
  }

  const group = await Group.findById(groupId);
  if (!group) {
    throw new NotFoundError("Group not found");
  }
  
  // Validate unequal splits if applicable
  if (splitType === 'unequal' && (!unequalShares || Object.keys(unequalShares).length === 0)) {
    throw new BadRequestError("Unequal split requires share values");
  }

  const newExpense = new Expense({
    groupId,
    description,
    amount,
    paidBy,
    splitBetween,
    splitType: splitType || 'equal',
    splitMethod: splitMethod || 'amount',
    unequalShares: splitType === 'unequal' ? unequalShares : undefined
  });

  await newExpense.save();

  return newExpense;
};
