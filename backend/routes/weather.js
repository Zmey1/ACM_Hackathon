require("dotenv").config();
const axios = require("axios");
const pool = require("../db.js");

const API_KEY = process.env.OPENWEATHER_API_KEY;

async function fetchWeatherData(lat, lon) {
    try {
        const url = `https://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${lon}&units=metric&appid=${API_KEY}`;
        console.log("Fetching weather data from:", url);

        const response = await axios.get(url);
        console.log("Weather API Response:", JSON.stringify(response.data, null, 2));

        if (!response.data || !response.data.list) {
            throw new Error("Invalid response from OpenWeather API");
        }

        let dailyData = {};

        const today = new Date().toISOString().split("T")[0]; 
        let minTemp = Infinity;
        let maxTemp = -Infinity;
        let mainWeather = "";
        
        response.data.list.forEach((entry) => {
            const entryDate = entry.dt_txt.split(" ")[0];  

            if (!dailyData[entryDate]) {
                dailyData[entryDate] = {
                    temperature: 0, 
                    humidity: 0,     
                    wind_speed: 0,   
                    rainfall: 0      
                };
            }

            if (entry.dt_txt.includes("12:00:00")) {
                dailyData[entryDate].temperature = entry.main.temp;
                dailyData[entryDate].humidity = entry.main.humidity;
                dailyData[entryDate].wind_speed = entry.wind.speed;
            }

            if (entry.rain && entry.rain["3h"]) {
                dailyData[entryDate].rainfall += entry.rain["3h"];
            }

            if (entryDate === today) {
                minTemp = Math.min(minTemp, entry.main.temp_min);
                maxTemp = Math.max(maxTemp, entry.main.temp_max);

                if (!mainWeather) {
                    mainWeather = entry.weather[0].main; 
                }
            }
        });

        if (minTemp === Infinity || maxTemp === -Infinity) {
            throw new Error("No valid weather data for today.");
        }

        await storeTodayData(today, minTemp, maxTemp, mainWeather);

        console.log(`Today's Weather: Min Temp = ${minTemp}°C, Max Temp = ${maxTemp}°C, Condition = ${mainWeather}`);

        console.log("Parsed Weather Data:", dailyData);

        const next5DaysData = Object.entries(dailyData).slice(0, 5);
        for (const [entryDate, data] of next5DaysData) {
            const { temperature, humidity, wind_speed, rainfall } = data;
            await storeWeatherData(lat, lon, entryDate, temperature, humidity, wind_speed, rainfall);
        }

        console.log("Weather data stored successfully!");

        return {
            minTemp,
            maxTemp,
            mainWeather
        };

    } catch (error) {
        console.error("Error fetching weather data:", error.message);
    }
}

async function storeWeatherData(lat, lon, date, temperature, humidity, wind_speed, rainfall) {
    const query = `
        INSERT INTO weather_data (latitude, longitude, date, temperature, humidity, wind_speed, rainfall)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        ON CONFLICT (date) DO UPDATE 
        SET temperature = EXCLUDED.temperature,
            humidity = EXCLUDED.humidity,
            wind_speed = EXCLUDED.wind_speed,
            rainfall = EXCLUDED.rainfall;
    `;
    const values = [lat, lon, date, temperature, humidity, wind_speed, rainfall];

    try {
        console.log("Inserting data into DB:", values);
        await pool.query(query, values);
        console.log("Data inserted successfully!");
    } catch (error) {
        console.error("Error storing weather data:", error.message);
    }
}

async function storeTodayData(date, minTemp, maxTemp, mainWeather) {
    const query = `
        INSERT INTO today_data (date, min_temp, max_temp, main_weather)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (date) DO UPDATE 
        SET min_temp = EXCLUDED.min_temp,
            max_temp = EXCLUDED.max_temp,
            main_weather = EXCLUDED.main_weather;
    `;
    const values = [date, minTemp, maxTemp, mainWeather];

    try {
        console.log("Inserting data into DB:", values);
        await pool.query(query, values);
        console.log("Data inserted successfully!");
    } catch (error) {
        console.error("Error storing weather data:", error.message);
    }
}

module.exports = { fetchWeatherData };

//https://ba7f-103-238-230-194.ngrok-free.app/store-weather

//http://api.openweathermap.org/data/2.5/forecast?lat=44.34&lon=10.99&appid=d98d3c3247855155380cc1c2669abea9