const express = require("express");
const router = express.Router();
const verifyToken = require("../middleware/verifyToken");
const groupController = require("../controllers/groupController");
const authMiddleware = require("../middleware/authMiddleware");

router.post("/add", verifyToken, groupController.createGroup);
router.get("/my", verifyToken, groupController.getGroupsByUser);
router.post('/:groupId/members', verifyToken, groupController.addMembers);
router.get('/:groupId', verifyToken, groupController.getGroupById);

module.exports = router;
