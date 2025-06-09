const Group = require("../models/Group");
const { BadRequestError, NotFoundError } = require('../utils/errors');

const VALID_TYPES = ["trip", "friends", "home", "other"];

exports.createGroup = async ({ name, photoUrl, type, members, createdBy }) => {
  if (!VALID_TYPES.includes(type)) {
    throw new Error("Invalid group type");
  }

  const newGroup = new Group({
    name,
    photoUrl,
    type,
    members,
    createdBy,
  });

  return await newGroup.save();
};

exports.getGroupsByUser = async (uid) => {
  return await Group.find({ members: uid });
};

exports.addMembersToGroup = async ({ groupId, memberIds, userId }) => {
  if (!groupId || !memberIds || !userId) {
    throw new BadRequestError('Missing required parameters');
  }

  const group = await Group.findById(groupId);
  if (!group) {
    throw new NotFoundError('Group not found');
  }

  // Convert all IDs to strings for consistent comparison
  const creatorId = group.createdBy.toString();
  const requestorId = userId.toString();

  const existingMembers = new Set(
    group.members.map(id => id.toString())
  );
  
  // Ensure all member IDs are strings and filter out duplicates
  const newMembers = memberIds
    .map(id => id.toString())
    .filter(id => !existingMembers.has(id));

  if (newMembers.length === 0) {
    throw new BadRequestError('All selected members are already in the group');
  }

  try {
    const updatedGroup = await Group.findByIdAndUpdate(
      groupId,
      { $addToSet: { members: { $each: newMembers } } },
      { new: true }
    );

    return {
      addedMembers: newMembers,
      group: updatedGroup
    };
  } catch (error) {
    console.error('Error adding members:', error);
    throw new Error('Failed to update group with new members');
  }
};