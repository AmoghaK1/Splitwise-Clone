const Expense = require("../models/Expense");
const Group = require("../models/Group");
const { BadRequestError, NotFoundError } = require("../utils/errors");

exports.addExpense = async ({ groupId, description, amount, paidBy, splitBetween }) => {
  if (!groupId || !description || !amount || !paidBy || !splitBetween || splitBetween.length === 0) {
    throw new BadRequestError("Missing required fields");
  }

  const group = await Group.findById(groupId);
  if (!group) {
    throw new NotFoundError("Group not found");
  }

  const newExpense = new Expense({
    groupId,
    description,
    amount,
    paidBy,
    splitBetween
  });

  await newExpense.save();

  return newExpense;
};
