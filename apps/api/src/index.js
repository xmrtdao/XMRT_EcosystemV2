const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/', (req, res) => {
  res.json({ message: 'XMRT API is running!', author: 'Joseph Andrew Lee' });
});

app.listen(PORT, () => {
  console.log(`🚀 XMRT API running on port ${PORT}`);
});