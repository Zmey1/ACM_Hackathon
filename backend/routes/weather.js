require("dotenv").config();
const axios = require("axios");
const pool = require("../db.js");

const API_KEY = process.env.OPENWEATHER_API_KEY;

async function fetchWeatherData(lat, lon, userId) {
    try {
        const url = `https://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${lon}&units=metric&appid=${API_KEY}`;
        console.log("Fetching weather data from:", url);

        const response = await axios.get(url);
        console.log("Weather API Response:", JSON.stringify(response.data, null, 2));

        if (!response.data || !response.data.list) {
            throw new Error("Invalid response from OpenWeather API");
        }

        let dailyData = {};
        
        response.data.list.forEach((entry) => {
            const date = entry.dt_txt.split(" ")[0]; 

            if (!dailyData[date]) {
                dailyData[date] = {
                    temperature: 0, 
                    humidity: 0,     
                    wind_speed: 0,   
                    rainfall: 0      
                };
            }

            if (entry.dt_txt.includes("12:00:00")) {
                dailyData[date].temperature = entry.main.temp;
                dailyData[date].humidity = entry.main.humidity;
                dailyData[date].wind_speed = entry.wind.speed;
            }

            if (entry.rain && entry.rain["3h"]) {
                dailyData[date].rainfall += entry.rain["3h"];
            }
        });

        console.log("Parsed Weather Data:", dailyData);

        const next5DaysData = Object.entries(dailyData).slice(0, 5);
        for (const [date, data] of next5DaysData) {
            const { temperature, humidity, wind_speed, rainfall } = data;
            await storeWeatherData(userId, date, temperature, humidity, wind_speed, rainfall);
        }

        console.log("Weather data stored successfully!");
    } catch (error) {
        console.error("Error fetching weather data:", error.message);
    }
}

async function storeWeatherData(userId, date, temperature, humidity, wind_speed, rainfall) {
    const query = `
        INSERT INTO weather_data (user_id, date, temperature, humidity, wind_speed, rainfall)
        VALUES ($1, $2, $3, $4, $5, $6)
        ON CONFLICT (user_id, date) DO UPDATE 
        SET temperature = EXCLUDED.temperature,
            humidity = EXCLUDED.humidity,
            wind_speed = EXCLUDED.wind_speed,
            rainfall = EXCLUDED.rainfall;
    `;
    const values = [userId, date, temperature, humidity, wind_speed, rainfall];

    try {
        console.log("Inserting data into DB:", values);
        await pool.query(query, values);
        console.log("Data inserted successfully!");
    } catch (error) {
        console.error("Error storing weather data:", error.message);
    }
}

module.exports = { fetchWeatherData };


//http://api.openweathermap.org/data/2.5/forecast?lat=44.34&lon=10.99&appid=d98d3c3247855155380cc1c2669abea9