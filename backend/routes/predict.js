require("dotenv").config();
const express = require("express");
const pool = require("../db"); 

const router = express.Router();

router.post("/get-crop", async (req, res) => {
    const { crop_type, soil_type, plantation_date } = req.body;
    console.log(crop_type, soil_type, plantation_date);

    //const plantationDateFormatted = new Date(plantation_date).toISOString().split("T")[0];
    //console.log(plantationDateFormatted);

    if (!crop_type || !soil_type || !plantation_date) {
        return res.status(400).json({ error: "All parameters (crop_type, soil_type, plantation_date) are required" });
    }

    try {
        // Fetch latest weather data (optimized query)
        const latestEntryQuery = `
            SELECT latitude, longitude, max_temp, min_temp 
            FROM weather_data 
            ORDER BY date DESC 
            LIMIT 1;
        `;
        const latestEntryResult = await pool.query(latestEntryQuery);

        if (latestEntryResult.rows.length === 0) {
            return res.status(404).json({ error: "No previous weather data found" });
        }

        const { latitude: lat, longitude: lon, max_temp, min_temp } = latestEntryResult.rows[0];
        console.log(lat, lon, max_temp, min_temp);

        // Insert into `predictwater`
        const insertQuery = `
            INSERT INTO predictwater (latitude, longitude, max_temp, min_temp, crop_type, soil_type, plantation_date)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING *;
        `;
        const insertResult = await pool.query(insertQuery, [lat, lon, max_temp, min_temp, crop_type, soil_type, plantation_date]);

        res.status(200).json(insertResult.rows[0]);
        console.log(insertResult.rows[0]);

    } catch (error) {
        console.error("Error fetching weather data:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});

router.post("/store-prediction", async (req, res) => {
    try {
        const { id, water_predicted, next_water_date, water_frequency } = req.body;
        console.log(req.body);

        if (!id || water_predicted === undefined || !next_water_date || !water_frequency) {
            return res.status(400).json({ error: "All parameters (id, water_predicted, next_water_date, water_frequency) are required" });
        }

        // Update prediction
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
