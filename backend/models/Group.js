const mongoose = require("mongoose");

const groupSchema = new mongoose.Schema({
  name: { type: String, required: true },
  photoUrl: { type: String, default: "" },
  type: { type: String, enum: ["trip", "friends", "home", "other"], required: true },
  members: { type: [String], required: true },
  createdBy: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("Group", groupSchema);
