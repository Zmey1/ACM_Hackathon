const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const pool = require('./db');
const { fetchWeatherData } = require('./routes/weather.js');
//const { registerUser, loginUser } = require('./routes/auth');

dotenv.config();

const app = express();
app.use(express.json());
app.use(cors());

app.get("/", (req, res) => {
    res.send("Server is running...");
});

pool.connect()
    .then(() => console.log("Database connected successfully!"))
    .catch((err) => console.error("Database connection error:", err.message));

//app.post("/api/auth/register", registerUser);
//app.post("/api/auth/login", loginUser);

app.post("/store-weather", async (req, res) => {
    const { userId, lat, lon } = req.body;
  
    if (!userId || !lat || !lon) {
      return res.status(400).json({ error: "Missing userId, lat, or lon" });
    }
  
    try {
      await fetchWeatherData(lat, lon, userId);
      res.json({ message: "Weather data stored successfully!" });
    } catch (error) {
      console.error("Error in /store-weather:", error);
      res.status(500).json({ error: "Failed to fetch/store weather data" });
    }
  });

// Import Routes
//const authRoutes = require('./routes/auth.js');
//const weatherRoutes = require('./routes/weather');
//const mlRoutes = require('./routes/ml');

//app.use('/api/auth', authRoutes);
//app.use('/api/weather', weatherRoutes);
//app.use('/api/ml', mlRoutes);

const PORT = process.env.PORT || 6000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
