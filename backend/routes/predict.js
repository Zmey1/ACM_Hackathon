require("dotenv").config();
const express = require("express");
const pool = require("../db"); 
const axios = require("axios");

const router = express.Router();

router.post("/predict-water", async (req, res) => {
    try {
        const { lat, lon, crop_type, soil_type, plantation_date } = req.body;

        const weatherQuery = "SELECT Tmax, Tmin FROM weather_data WHERE latitude = $1 AND longitude = $2 ORDER BY date DESC LIMIT 1";
        const weatherResult = await pool.query(weatherQuery, [lat, lon]);

        if (weatherResult.rows.length === 0) {
            return res.status(404).json({ error: "No weather data found for the given location" });
        }

        const { Tmax, Tmin } = weatherResult.rows[0];

        const insertQuery = `
            INSERT INTO predictwater (latitude, longitude, Tmax, Tmin, crop_type, soil_type, plantation_date)
            VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`;
        
        const insertResult = await pool.query(insertQuery, [lat, lon, Tmax, Tmin, crop_type, soil_type, plantation_date]);
        const insertedData = insertResult.rows[0];

        const flaskResponse = await axios.post("http://localhost:5001/calculate-water", {
            id: insertedData.id,
            latitude: lat,
            longitude: lon,
            Tmax,
            Tmin,
            crop_type,
            soil_type,
            plantation_date
        });

        const { water_predicted, next_water_date, water_frequency } = flaskResponse.data;

        const updateQuery = `
            UPDATE predictwater 
            SET water_predicted = $1, next_water_date = $2, water_frequency = $3
            WHERE id = $4`;
        
        await pool.query(updateQuery, [water_predicted, next_water_date, water_frequency, insertedData.id]);

        res.json({
            water_predicted,
            next_water_date,
            water_frequency
        });

    } catch (error) {
        console.error("Error processing prediction:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});

module.exports = router;
