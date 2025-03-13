const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const pool = require('./db.js');
const { fetchWeatherData } = require('./routes/weather.js');
//const { registerUser, loginUser } = require('./routes/auth');
const authRoutes = require('./routes/auth.js'); // Import auth routes
const cropRoutes = require('./routes/predict.js'); 
const authMiddleware = require('./middleware/authMiddleware'); // Import middleware

dotenv.config();

const app = express();
app.use(express.json());
app.use(cors({ origin: "*" }));

app.get("/", (req, res) => {
    res.send("Server is running...");
});

pool.connect()
    .then(() => console.log("Database connected successfully!"))
    .catch((err) => console.error("Database connection error:", err.message));

app.use('/api/auth', authRoutes);
app.use('/api/crop', cropRoutes); 

app.post("/store-weather", async (req, res) => {
    //console.log("Received request with body:", req.body);
    const { lat, lon } = req.body;
  
    if (!lat || !lon) {
      return res.status(400).json({ error: "Missing lat, or lon" });
    }
  
    try {
      const weatherData = await fetchWeatherData(lat, lon);
      res.json({ 
        message: "Weather data stored successfully!"
      });

      console.log("Received request with body:", req.body);

    } catch (error) {
      console.error("Error in /store-weather:", error);
      res.status(500).json({ error: "Failed to fetch/store weather data" });
    }
  });

app.get("/get-weather", async (req, res) => {
    try {
        const today = new Date().toISOString().split("T")[0]; 

        const query = "SELECT min_temp, max_temp, main_weather FROM today_data WHERE date = $1";
        const { rows } = await pool.query(query, [today]);

        if (rows.length === 0) {
            return res.status(404).json({ error: "No weather data available for today" });
        }

        const { min_temp, max_temp, main_weather } = rows[0];

        res.json({
            minTemp: min_temp.toString(),
            maxTemp: max_temp.toString(),
            mainWeather: main_weather.toString()
        });

    } catch (error) {
        console.error("Error fetching stored weather data:", error);
        res.status(500).json({ error: "Failed to fetch stored weather data" });
    }
});

// Import Routes
//const authRoutes = require('./routes/auth.js');
//const weatherRoutes = require('./routes/weather');
//const mlRoutes = require('./routes/ml');

//app.use('/api/auth', authRoutes);
//app.use('/api/weather', weatherRoutes);
//app.use('/api/ml', mlRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on port ${PORT}`);
});
