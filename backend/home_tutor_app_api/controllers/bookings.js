const asyncHandler = require('../middleware/async');
const ErrorResponse = require('../utils/errorResponse');
const Booking = require('../models/Booking');

exports.createBooking = asyncHandler(async (req, res, next) => {
  const { tutorId, subjectId, date, timeSlot, address } = req.body;

  const booking = await Booking.create({
    student: req.user.id,
    tutor: tutorId,
    subject: subjectId,
    date,
    timeSlot,
    address,
  });

  res.status(201).json({
    success: true,
    data: booking,
  });
});

exports.getMyBookings = asyncHandler(async (req, res, next) => {
  let filter = {};

  if (req.user.role === 'student') {
    filter = { student: req.user.id };
  } else if (req.user.role === 'tutor') {
    filter = { tutor: req.user.id };
  }

  const bookings = await Booking.find(filter)
    .populate('student', 'name email phone role')
    .populate('tutor', 'name email phone role')
    .populate('subject', 'title');

  res.status(200).json({
    success: true,
    count: bookings.length,
    total: bookings.length,
    page: 1,
    pages: 1,
    data: bookings,
  });
});

exports.updateBookingStatus = asyncHandler(async (req, res, next) => {
  const { status } = req.body;

  if (!status) {
    return next(new ErrorResponse('Please provide a status', 400));
  }

  let booking = await Booking.findById(req.params.id);

  if (!booking) {
    return next(new ErrorResponse('Booking not found', 404));
  }

  if (req.user.role === 'tutor' && booking.tutor.toString() !== req.user.id) {
    return next(new ErrorResponse('Not authorized to update this booking', 403));
  }

  booking.status = status;
  await booking.save();

  res.status(200).json({
    success: true,
    data: booking,
  });
});
