const path = require('path');
const gateway = require('express-gateway');

process.env.LOG_LEVEL = 'debug';

gateway()
  .load(path.join(__dirname, 'config'))
  .run();
