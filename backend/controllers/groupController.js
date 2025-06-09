const groupService = require("../services/groupService");

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
