const express = require('express');
const cors = require('cors');
const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS for all routes
app.use(cors());

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.get('/billing', (req, res) => {
  const data = [
    { id: 1, customer: "Alice", amount: 120.50, status: "paid" },
    { id: 2, customer: "Bob", amount: 75.00, status: "pending" },
    { id: 3, customer: "Charlie", amount: 300.00, status: "overdue" }
  ];
  res.json(data);
});

if (require.main === module) {
  app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
}

module.exports = app;
