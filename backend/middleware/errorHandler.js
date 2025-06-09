const mongoose = require('mongoose');

function errorHandler(err, req, res, next) {
  console.error(err.stack);

  if (err instanceof mongoose.Error.ValidationError) {
    return res.status(400).json({ 
      success: false, 
      message: err.message 
    });
  }

  if (err instanceof mongoose.Error.CastError) {
    return res.status(400).json({ 
      success: false, 
      message: 'Invalid ID format' 
    });
  }

  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal Server Error';

  res.status(statusCode).json({ 
    success: false, 
    message 
  });
}

module.exports = errorHandler;