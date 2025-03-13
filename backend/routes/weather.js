const axios = require("axios");
const pool = require("../db.js");
require("dotenv").config();

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

        let minTempToday = null;
        let maxTempToday = null;
        let mainWeatherToday = "";

        response.data.list.forEach((entry) => {
            const entryDate = entry.dt_txt.split(" ")[0];

            if (!dailyData[entryDate]) {
                dailyData[entryDate] = {
                    temperature: null,
                    humidity: null,
                    wind_speed: null,
                    rainfall: 0,
                    min_temp: null,
                    max_temp: null,
                };
            }

            if (entry.dt_txt.includes("12:00:00")) {
                dailyData[entryDate].temperature = entry.main.temp;
                dailyData[entryDate].humidity = entry.main.humidity;
                dailyData[entryDate].wind_speed = entry.wind.speed;
            }

            if (dailyData[entryDate].min_temp === null || entry.main.temp_min < dailyData[entryDate].min_temp) {
                dailyData[entryDate].min_temp = entry.main.temp_min;
            }

            if (dailyData[entryDate].max_temp === null || entry.main.temp_max > dailyData[entryDate].max_temp) {
                dailyData[entryDate].max_temp = entry.main.temp_max;
            }

            if (entry.rain && entry.rain["3h"]) {
                dailyData[entryDate].rainfall += entry.rain["3h"];
            }

            // Updating today's weather
            if (entryDate === today) {
                if (minTempToday === null || entry.main.temp_min < minTempToday) {
                    minTempToday = entry.main.temp_min;
                }
                if (maxTempToday === null || entry.main.temp_max > maxTempToday) {
                    maxTempToday = entry.main.temp_max;
                }
                if (!mainWeatherToday) {
                    mainWeatherToday = entry.weather[0].main;
                }
            }
        });

        if (minTempToday === null || maxTempToday === null) {
            throw new Error("No valid weather data for today.");
        }

        await storeTodayData(today, minTempToday, maxTempToday, mainWeatherToday);
        console.log(`Today's Weather: Min Temp = ${minTempToday}°C, Max Temp = ${maxTempToday}°C, Condition = ${mainWeatherToday}`);
        console.log("Parsed Weather Data:", dailyData);

        for (const [entryDate, data] of Object.entries(dailyData).slice(0, 5)) {
            const { temperature, humidity, wind_speed, rainfall, min_temp, max_temp } = data;
            await storeWeatherData(lat, lon, entryDate, temperature, humidity, wind_speed, rainfall, min_temp, max_temp);
        }

        console.log("Weather data stored successfully!");

        return {
            minTempToday,
            maxTempToday,
            mainWeatherToday
        };
    } catch (error) {
        console.error("Error fetching weather data:", error.message);
    }
}

async function storeWeatherData(lat, lon, date, temperature, humidity, wind_speed, rainfall, min_temp, max_temp) {
    const query = `
        INSERT INTO weather_data (latitude, longitude, date, temperature, humidity, wind_speed, rainfall, min_temp, max_temp)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        ON CONFLICT (date) DO UPDATE 
        SET temperature = EXCLUDED.temperature,
            humidity = EXCLUDED.humidity,
            wind_speed = EXCLUDED.wind_speed,
            rainfall = EXCLUDED.rainfall,
            min_temp = EXCLUDED.min_temp,
            max_temp = EXCLUDED.max_temp;
    `;
    const values = [lat, lon, date, temperature, humidity, wind_speed, rainfall, min_temp, max_temp];

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
