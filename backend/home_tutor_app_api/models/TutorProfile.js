const mongoose = require('mongoose');

const TutorProfileSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.ObjectId,
    ref: 'User',
    required: true,
    unique: true,
  },
  bio: {
    type: String,
  },
  subjects: [
    {
      type: mongoose.Schema.ObjectId,
      ref: 'Subject',
    },
  ],
  hourlyRate: {
    type: Number,
  },
  location: {
    type: String,
  },
  isVerified: {
    type: Boolean,
    default: false,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('TutorProfile', TutorProfileSchema);
