const express = require('express');
const {
  createBooking,
  getMyBookings,
  updateBookingStatus,
} = require('../controllers/bookings');
const { protect, authorize } = require('../middleware/auth');

const router = express.Router();

router.post('/', protect, authorize('student'), createBooking);
router.get('/my', protect, getMyBookings);
router.put('/:id/status', protect, authorize('tutor'), updateBookingStatus);

module.exports = router;
