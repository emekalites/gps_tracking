const express = require('express');
const bodyParser = require('body-parser');

const app = express();

app.use(bodyParser.json());

app.post('/location', (req, res) => {
  const { latitude, longitude, timestamp } = req.body;
  console.log(`[Server] Received location: ${latitude}, ${longitude} at ${timestamp}`);
  res.status(200).json({ status: 'ok' });
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`[Server] Listening on port ${PORT}`);
});

// I want a flutter app with features:
// - read gps coordinates every 2minutes
// - display lng lat on the screen as it changes while app is running
// - log on console if the app is minimized
// - keep running as notification if the app is closed
// - store coordinates in sqlite in phone
// - push to server every 1minute from sqlite any time there is network and flag as sent meanwhile