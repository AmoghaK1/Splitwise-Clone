const express = require("express");
const router = express.Router();
const verifyToken = require("../middleware/verifyToken");
const groupController = require("../controllers/groupController");
const authMiddleware = require("../middleware/authMiddleware");

router.post("/add", verifyToken, groupController.createGroup);
router.get("/my", verifyToken, groupController.getGroupsByUser);
router.post('/:groupId/members', verifyToken, groupController.addMembers);
router.get('/:groupId', verifyToken, groupController.getGroupById);
router.get('/:groupId/members', verifyToken, groupController.getGroupMembers);
router.put('/:groupId/name', verifyToken, groupController.updateGroupName);
router.post('/:groupId/leave', verifyToken, groupController.leaveGroup);
router.delete('/:groupId', verifyToken, groupController.deleteGroup);
router.post("/:groupId/expenses", verifyToken, groupController.addExpenseToGroup);
router.get("/:groupId/expenses", verifyToken, groupController.getGroupExpenses);


module.exports = router;
