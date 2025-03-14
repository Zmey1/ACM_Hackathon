const express = require("express");
const bodyParser = require("body-parser");
const pool = require('../db');
const axios = require("axios");
require("dotenv").config();
const { sendWeatherNotification } = require("./notification");

const app = express();
app.use(bodyParser.json());

async function fetchWeatherData(lat, lon) {
    try {
        const url = `https://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${lon}&appid=${process.env.WEATHER_API_KEY}&units=metric`;
        const response = await axios.get(url);
        const weatherData = response.data;

        let message = "";
        if (weatherData.list) {
            for (const entry of weatherData.list) {
                if (entry.dt_txt.includes("12:00:00")) {
                    const temp = entry.main.temp;
                    const rainfall = entry.rain ? entry.rain["3h"] : 0;

                    if (temp > 40) {
                        message = "⚠ High temperature alert! Please take necessary precautions.";
                    } else if (rainfall > 20) {
                        message = "🌧 Heavy rainfall expected. Protect your crops accordingly.";
                    }

                    if (message) {
                        const playerIds = await getPlayerIds();
                        if (playerIds.length > 0) {
                            await sendWeatherNotification(playerIds, message);
                        }
                    }
                }
            }
        }
    } catch (error) {
        console.error("Error fetching weather data:", error.message);
    }
}

app.post('/register-device', async (req, res) => {
    const { name, phone, playerId } = req.body;

    const query = `INSERT INTO userNotifications (name, phone, onesignal_player_id) VALUES ($1, $2, $3) RETURNING id`;
    const values = [name, phone, playerId];

    try {
        const result = await pool.query(query, values);
        res.json({ success: true, userId: result.rows[0].id });
    } catch (error) {
        console.error("Error registering device:", error.message);
        res.status(500).json({ error: "Failed to register device" });
    }
});

async function getPlayerIds() {
    try {
        const result = await pool.query("SELECT onesignal_player_id FROM userNotifications WHERE onesignal_player_id IS NOT NULL");
        return result.rows.map(row => row.onesignal_player_id);
    } catch (error) {
        console.error("Error fetching player IDs:", error.message);
        return [];
    }
}

// Send notifications
async function sendNotifications() {
    const playerIds = await getPlayerIds();
    if (playerIds.length > 0) {
        await sendWeatherNotification(playerIds, "Your weather alert message");
    }
}

sendNotifications();

// Start server
app.listen(3000, () => {
    console.log("Server running on port 3000");
});
