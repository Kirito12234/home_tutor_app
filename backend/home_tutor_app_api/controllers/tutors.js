const asyncHandler = require('../middleware/async');
const ErrorResponse = require('../utils/errorResponse');
const TutorProfile = require('../models/TutorProfile');

exports.getTutors = asyncHandler(async (req, res, next) => {
  const page = parseInt(req.query.page, 10) || 1;
  const limit = parseInt(req.query.limit, 10) || 10;
  const startIndex = (page - 1) * limit;

  const total = await TutorProfile.countDocuments();

  const profiles = await TutorProfile.find()
    .populate('user', 'name email phone role')
    .populate('subjects', 'title')
    .skip(startIndex)
    .limit(limit);

  res.status(200).json({
    success: true,
    count: profiles.length,
    total,
    page,
    pages: Math.ceil(total / limit) || 1,
    data: profiles,
  });
});

exports.getTutor = asyncHandler(async (req, res, next) => {
  const profile = await TutorProfile.findOne({ user: req.params.id })
    .populate('user', 'name email phone role')
    .populate('subjects', 'title');

  if (!profile) {
    return next(new ErrorResponse('Tutor profile not found', 404));
  }

  res.status(200).json({
    success: true,
    data: profile,
  });
});

exports.upsertProfile = asyncHandler(async (req, res, next) => {
  const fields = {
    user: req.user.id,
    bio: req.body.bio,
    subjects: req.body.subjects,
    hourlyRate: req.body.hourlyRate,
    location: req.body.location,
    isVerified: req.body.isVerified,
  };

  let profile = await TutorProfile.findOne({ user: req.user.id });

  if (profile) {
    profile = await TutorProfile.findOneAndUpdate({ user: req.user.id }, fields, {
      new: true,
      runValidators: true,
    });
  } else {
    profile = await TutorProfile.create(fields);
  }

  res.status(200).json({
    success: true,
    data: profile,
  });
});
