const mongoose = require('mongoose');
const dotenv = require('dotenv');

const User = require('./models/User');
const Subject = require('./models/Subject');
const TutorProfile = require('./models/TutorProfile');
const Booking = require('./models/Booking');

dotenv.config({ path: './config/config.env' });

const MONGO_URI =
  'mongodb+srv://home:Oppasd%4012@hometutor.wcjfccj.mongodb.net/home_tutor_app';

const connectDB = async () => {
  await mongoose.connect(MONGO_URI);
  console.log('MongoDB Connected for seeding');
};

const createData = async () => {
  await Booking.deleteMany();
  await TutorProfile.deleteMany();
  await Subject.deleteMany();
  await User.deleteMany();

  const users = await User.create([
    {
      name: 'Admin User',
      email: 'admin@hometutor.com',
      phone: '08000000001',
      password: 'password123',
      role: 'admin',
    },
    {
      name: 'Tutor User',
      email: 'tutor@hometutor.com',
      phone: '08000000002',
      password: 'password123',
      role: 'tutor',
    },
    {
      name: 'Student User',
      email: 'student@hometutor.com',
      phone: '08000000003',
      password: 'password123',
      role: 'student',
    },
  ]);

  const subjects = await Subject.create([
    { title: 'Mathematics' },
    { title: 'English' },
    { title: 'Physics' },
  ]);

  const tutorProfile = await TutorProfile.create({
    user: users[1]._id,
    bio: 'Experienced home tutor with a focus on STEM subjects.',
    subjects: [subjects[0]._id, subjects[2]._id],
    hourlyRate: 25,
    location: 'City Center',
    isVerified: true,
  });

  await Booking.create({
    student: users[2]._id,
    tutor: users[1]._id,
    subject: subjects[0]._id,
    date: new Date(),
    timeSlot: '10:00-11:00',
    address: '123 Main Street',
    status: 'pending',
  });

  return { users, subjects, tutorProfile };
};

const deleteData = async () => {
  await Booking.deleteMany();
  await TutorProfile.deleteMany();
  await Subject.deleteMany();
  await User.deleteMany();
};

const run = async () => {
  try {
    await connectDB();

    if (process.argv[2] === '-i') {
      await createData();
      console.log('Data Imported');
    } else if (process.argv[2] === '-d') {
      await deleteData();
      console.log('Data Destroyed');
    } else {
      console.log('Please use -i to import or -d to delete');
    }
  } catch (err) {
    console.error(err.message);
  } finally {
    process.exit();
  }
};

run();
