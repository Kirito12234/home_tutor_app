const mongoose = require('mongoose');

const MONGO_URI =
  'mongodb+srv://home:Oppasd%4012@hometutor.wcjfccj.mongodb.net/home_tutor_app';

const connectDB = async () => {
  const conn = await mongoose.connect(MONGO_URI);
  console.log(`MongoDB Connected: ${conn.connection.host}`);
};

module.exports = connectDB;
