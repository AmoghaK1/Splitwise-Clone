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


exports.getGroupById = async (req, res) => {
  try {
    const group = await Group.findById(req.params.groupId);
    if (!group) {
      return res.status(404).json({ message: 'Group not found' });
    }

    res.status(200).json({
      _id: group._id,
      name: group.name,
      members: group.members,
      createdBy: group.createdBy,
      createdAt: group.createdAt,
    });
  } catch (err) {
    console.error("Error fetching group:", err);
    res.status(500).json({ message: "Server error" });
  }
};

exports.getGroupMembers = async (req, res) => {
  try {
    const group = await Group.findById(req.params.groupId);
    if (!group) {
      return res.status(404).json({ message: 'Group not found' });
    }

    res.status(200).json({ members: group.members });
  } catch (err) {
    console.error('Failed to fetch group members:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
};


