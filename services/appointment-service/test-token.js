// fresh-token.js - Save this in your appointment-service directory
const jwt = require('jsonwebtoken');
require('dotenv').config({ path: './src/.env' });

// Get the JWT secret from environment variables
const JWT_SECRET = process.env.JWT_SECRET;

if (!JWT_SECRET) {
  console.error('Error: JWT_SECRET is not defined in your .env file');
  process.exit(1);
}

console.log('Using JWT_SECRET:', JWT_SECRET);

// Create a test doctor user
const testDoctor = {
  id: 'test-doctor-id',
  name: 'Test Doctor',
  role: 'doctor'
};

// Generate a token with standard algorithm and short expiration
const token = jwt.sign(testDoctor, JWT_SECRET, { 
  expiresIn: '1h',
  algorithm: 'HS256'
});

console.log('\nFresh Test JWT Token:');
console.log(token);
console.log('\nToken decoded payload:');
console.log(jwt.decode(token));
console.log('\nUse this token in your x-auth-token header for testing.');