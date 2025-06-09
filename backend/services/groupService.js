const Group = require("../models/Group");

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
