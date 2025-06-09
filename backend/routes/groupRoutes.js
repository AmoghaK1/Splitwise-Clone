const express = require("express");
const router = express.Router();
const verifyToken = require("../middleware/verifyToken");
const groupController = require("../controllers/groupController");

router.post("/add", verifyToken, groupController.createGroup);
router.get("/my", verifyToken, groupController.getGroupsByUser);

module.exports = router;
