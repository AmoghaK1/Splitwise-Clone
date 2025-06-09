const groupService = require("../services/groupService");
const Group = require('../models/Group');
const { NotFoundError, BadRequestError } = require('../utils/errors');

exports.createGroup = async (req, res) => {
  try {
    const { name, photoUrl, type, members } = req.body;
    const createdBy = req.user.uid;

    const group = await groupService.createGroup({ name, photoUrl, type, members, createdBy });

    res.status(200).json({ success: true, group });
  } catch (err) {
    console.error("Group creation error:", err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.getGroupsByUser = async (req, res) => {
  try {
    const uid = req.user.uid;
    const groups = await groupService.getGroupsByUser(uid);
    res.status(200).json(groups);
  } catch (err) {
    console.error("Get groups error:", err.message);
    res.status(500).json({ message: "Failed to fetch groups" });
  }
};

exports.addMembers = async (req, res, next) => {
  try {
    const { groupId } = req.params;
    const { memberIds } = req.body;
    const userId = req.user.uid;

    // Basic validation
    if (!memberIds || !Array.isArray(memberIds)) {
      throw new BadRequestError('Invalid member IDs');
    }

    // Delegate to service
    const { addedMembers, group } = await groupService.addMembersToGroup({ groupId, memberIds, userId });

    res.status(200).json({
      success: true,
      addedMembers,
      group
    });
  } catch (error) {
    next(error);
  }
};


