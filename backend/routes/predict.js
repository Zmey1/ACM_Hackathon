require("dotenv").config();
const axios = require("axios");
const express = require("express");
const pool = require("../db"); 

const router = express.Router();

router.post("/get-crop", async (req, res) => {
    const { crop_type, soil_type, plantation_date } = req.body;
    console.log(crop_type, soil_type, plantation_date);

    if (!crop_type || !soil_type || !plantation_date) {
        return res.status(400).json({ error: "All parameters (crop_type, soil_type, plantation_date) are required" });
    }

    try {
        const latestEntryQuery = `
        SELECT 
            latitude, 
            longitude, 
            MAX(max_temp) AS max_temp, 
            MIN(min_temp) AS min_temp, 
            AVG(wind_speed) AS avg_wind_speed, 
            AVG(humidity) AS avg_relative_humidity, 
            SUM(rainfall) AS total_rainfall
        FROM weather_data 
        WHERE date >= NOW() - INTERVAL '5 days' 
        GROUP BY latitude, longitude;
    `;

    const latestEntryResult = await pool.query(latestEntryQuery);

    if (latestEntryResult.rows.length === 0) {
        return res.status(404).json({ error: "No previous weather data found" });
    }

    const { latitude: lat, longitude: lon, max_temp, min_temp, avg_wind_speed, avg_relative_humidity, total_rainfall } = latestEntryResult.rows[0];
    console.log(lat, lon, max_temp, min_temp, avg_wind_speed, avg_relative_humidity, total_rainfall);

    const elevationUrl = `https://api.open-elevation.com/api/v1/lookup?locations=${lat},${lon}`;

    const elevationResponse = await axios.get(elevationUrl);
    const elevation = elevationResponse.data.results[0]?.elevation || null;
    console.log(`Elevation: ${elevation} meters`);

    const insertQuery = `
        INSERT INTO predictwater (
            latitude, longitude, max_temp, min_temp, 
            avg_wind_speed, avg_relative_humidity, total_rainfall, elevation,  
            crop_type, soil_type, plantation_date
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
        RETURNING *;
    `;

    const insertResult = await pool.query(insertQuery, [
        lat, lon, max_temp, min_temp, avg_wind_speed, avg_relative_humidity, total_rainfall, elevation,  
        crop_type, soil_type, plantation_date
    ]);

    res.status(200).json(insertResult.rows[0]);
    console.log(insertResult.rows[0]);

    } catch (error) {
        console.error("Error fetching weather data:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});

router.get("/latest-prediction", async (req, res) => {
    try {
        const query = `
            SELECT latitude, longitude, max_temp, min_temp, 
                   avg_wind_speed, avg_relative_humidity, 
                   total_rainfall, elevation,  
                   crop_type, soil_type, plantation_date
            FROM predictwater
            ORDER BY id DESC 
            LIMIT 1;
        `;
        const result = await pool.query(query);

        if (result.rows.length === 0) {
            return res.status(404).json({ error: "No prediction data found" });
        }

        res.status(200).json(result.rows[0]);
        console.log(result.rows[0]);

    } catch (error) {
        console.error("Error fetching latest prediction:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});


router.post("/store-prediction", async (req, res) => {
    try {
        const { water_predicted, next_water_date, water_frequency } = req.body;
        console.log(req.body);

        if (!id || water_predicted === undefined || !next_water_date || !water_frequency) {
            return res.status(400).json({ error: "All parameters (id, water_predicted, next_water_date, water_frequency) are required" });
        }

        const updateQuery = `
            UPDATE predictwater 
            SET water_predicted = $1, next_water_date = $2, water_frequency = $3
            WHERE id = $4
            RETURNING *;
        `;
        const updateResult = await pool.query(updateQuery, [water_predicted, next_water_date, water_frequency, id]);

        if (updateResult.rows.length === 0) {
            return res.status(404).json({ error: "No matching record found to update" });
        }

        res.status(200).json({ message: "Prediction stored successfully", data: updateResult.rows[0] });
        console.log(updateResult.rows[0]);

    } catch (error) {
        console.error("Error storing prediction:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});

module.exports = router;
