// backend/app.js
const express = require('express');
const app = express();


app.use(express.json());


// Default route
app.get('/', (req, res) => {
  res.send('Backend is running!');
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server started on port ${PORT}`);
});
