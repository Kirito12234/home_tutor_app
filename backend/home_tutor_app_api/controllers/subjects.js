const asyncHandler = require('../middleware/async');
const ErrorResponse = require('../utils/errorResponse');
const Subject = require('../models/Subject');

exports.getSubjects = asyncHandler(async (req, res, next) => {
  const subjects = await Subject.find();

  res.status(200).json({
    success: true,
    count: subjects.length,
    total: subjects.length,
    page: 1,
    pages: 1,
    data: subjects,
  });
});

exports.createSubject = asyncHandler(async (req, res, next) => {
  const subject = await Subject.create(req.body);

  res.status(201).json({
    success: true,
    data: subject,
  });
});

exports.updateSubject = asyncHandler(async (req, res, next) => {
  let subject = await Subject.findById(req.params.id);

  if (!subject) {
    return next(new ErrorResponse('Subject not found', 404));
  }

  subject = await Subject.findByIdAndUpdate(req.params.id, req.body, {
    new: true,
    runValidators: true,
  });

  res.status(200).json({
    success: true,
    data: subject,
  });
});

exports.deleteSubject = asyncHandler(async (req, res, next) => {
  const subject = await Subject.findById(req.params.id);

  if (!subject) {
    return next(new ErrorResponse('Subject not found', 404));
  }

  await subject.deleteOne();

  res.status(200).json({
    success: true,
    data: {},
  });
});
