require("dotenv").config();
const axios = require("axios");
const express = require("express");
const pool = require("../db"); 
const { spawn } = require('child_process');
const path = require('path');

const router = express.Router();

// Helper function to run Python script and get its output
const runPythonScript = () => {
  return new Promise((resolve, reject) => {
    // Adjust the path to match your actual directory structure
    const pythonScript = path.join(__dirname, '../../formula_based_water_req.py');
    const pythonProcess = spawn('python', [pythonScript]);
    
    let scriptOutput = '';
    let scriptError = '';

    pythonProcess.stdout.on('data', (data) => {
      scriptOutput += data.toString();
    });

    pythonProcess.stderr.on('data', (data) => {
      scriptError += data.toString();
    });

    pythonProcess.on('close', (code) => {
      if (code !== 0) {
        console.error(`Python script exited with code ${code}`);
        console.error(`Error: ${scriptError}`);
        reject(new Error(`Python script failed: ${scriptError}`));
      } else {
        console.log("Python script executed successfully");
        resolve(scriptOutput);
      }
    });
  });
};

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
    
    // After inserting the data, run the Python script
    try {
        console.log("Running water requirement calculation script...");
        await runPythonScript();
        
        // Get the latest water calculation
        const waterCalcQuery = `
            SELECT water_predicted, water_predicted_acre, next_water_date, water_frequency, simple_instruction
            FROM predictwater
            WHERE id = (SELECT MAX(id) FROM predictwater);
        `;
        
        const waterCalcResult = await pool.query(waterCalcQuery);
        
        if (waterCalcResult.rows.length > 0) {
            // Combine original data with water calculation
            const responseData = {
                ...insertResult.rows[0],
                water_data: waterCalcResult.rows[0]
            };
            
            res.status(200).json(responseData);
        } else {
            // Return original data if water calculation not found
            res.status(200).json(insertResult.rows[0]);
        }
    } catch (scriptError) {
        console.error("Error running Python script:", scriptError);
        // Still return the basic data even if Python script fails
        res.status(200).json({
            ...insertResult.rows[0],
            water_calculation_error: "Failed to calculate water requirements"
        });
    }

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
                   crop_type, soil_type, plantation_date,
                   water_predicted, water_predicted_acre, next_water_date, 
                   water_frequency, simple_instruction
            FROM predictwater
            ORDER BY id DESC 
            LIMIT 1;
        `;
        const result = await pool.query(query);

        if (result.rows.length === 0) {
            return res.status(404).json({ error: "No prediction data found" });
        }

        res.status(200).json(result.rows[0]);

    } catch (error) {
        console.error("Error fetching latest prediction:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});


router.post("/store-prediction", async (req, res) => {
    try {
        const { 
            water_predicted, 
            water_predicted_acre, 
            next_water_date, 
            water_frequency, 
            simple_instruction 
        } = req.body;

        console.log(req.body);

        // Validate required fields
        if (
            water_predicted === undefined || 
            water_predicted_acre === undefined || 
            !next_water_date || 
            !water_frequency || 
            !simple_instruction
        ) {
            return res.status(400).json({ 
                error: "All parameters (water_predicted, water_predicted_acre, next_water_date, water_frequency, simple_instruction) are required" 
            });
        }

        // Fetch the latest id from the predictwater table
        const idQuery = `SELECT id, crop_type FROM predictwater ORDER BY id DESC LIMIT 1;`;
        const idResult = await pool.query(idQuery);

        if (idResult.rows.length === 0) {
            return res.status(404).json({ error: "No records found in predictwater table" });
        }

        const latestId = idResult.rows[0].id;
        const cropType = idResult.rows[0].crop_type; // Extract crop_type

        // Update the latest record with the new values
        const updateQuery = `
            UPDATE predictwater 
            SET 
                water_predicted = $1, 
                water_predicted_acre = $2, 
                next_water_date = $3, 
                water_frequency = $4, 
                simple_instruction = $5
            WHERE id = $6
            RETURNING *;
        `;

        const updateResult = await pool.query(updateQuery, [
            water_predicted, 
            water_predicted_acre, 
            next_water_date, 
            water_frequency,  
            simple_instruction, 
            latestId
        ]);
        
        // Fix: Use updateResult.rows[0] instead of undefined variable
        const updatedData = updateResult.rows[0];

        res.status(200).json({ 
            message: "Prediction stored successfully", 
            data: {
                // Convert all values to strings
                water_predicted: updatedData.water_predicted.toString(),
                water_predicted_acre: updatedData.water_predicted_acre.toString(),
                next_water_date: updatedData.next_water_date.toISOString(), // Convert Date to string in ISO format
                water_frequency: updatedData.water_frequency.toString(),
                simple_instruction: updatedData.simple_instruction.toString(),
                crop_type: cropType.toString() // Convert crop_type to string
            }
        });
    } catch (error) {
        console.error("Error storing prediction:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});

module.exports = router;