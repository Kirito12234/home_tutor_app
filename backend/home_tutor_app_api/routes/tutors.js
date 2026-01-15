const express = require('express');
const { getTutors, getTutor, upsertProfile } = require('../controllers/tutors');
const { protect, authorize } = require('../middleware/auth');

const router = express.Router();

router.get('/', getTutors);
router.get('/:id', getTutor);
router.post('/profile', protect, authorize('tutor'), upsertProfile);

module.exports = router;
