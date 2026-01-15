const mongoose = require('mongoose');

const BookingSchema = new mongoose.Schema({
  student: {
    type: mongoose.Schema.ObjectId,
    ref: 'User',
    required: true,
  },
  tutor: {
    type: mongoose.Schema.ObjectId,
    ref: 'User',
    required: true,
  },
  subject: {
    type: mongoose.Schema.ObjectId,
    ref: 'Subject',
    required: true,
  },
  date: {
    type: Date,
    required: [true, 'Please add a date'],
  },
  timeSlot: {
    type: String,
    required: [true, 'Please add a time slot'],
  },
  address: {
    type: String,
    required: [true, 'Please add an address'],
  },
  status: {
    type: String,
    enum: ['pending', 'accepted', 'rejected', 'completed'],
    default: 'pending',
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Booking', BookingSchema);
