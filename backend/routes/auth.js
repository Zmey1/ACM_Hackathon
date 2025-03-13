require('dotenv').config();
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../db');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');

router.get('/protected', authMiddleware, (req, res) => {
    res.json({ message: "This is a protected route", user: req.user });
});

router.post('/register', async (req, res) => {
    const { email, password, confirmPassword } = req.body;

    console.log("Request Body:", req.body);  

    if (!email || !password || !confirmPassword) {
        return res.status(400).json({ success: false, error: "All fields are required" });
    }

    if (password !== confirmPassword) {
        return res.status(400).json({ success: false, error: "Passwords do not match" });
    }

    try {
        const userExists = await pool.query("SELECT * FROM users WHERE email = $1", [email]);
        if (userExists.rows.length > 0) {
            return res.status(400).json({ success: false, error: "User already exists!" });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        await pool.query(
            "INSERT INTO users (email, password) VALUES ($1, $2)", 
            [email, hashedPassword]
        );

        console.log("User Registered:", { email, hashedPassword });

        return res.status(201).json({ success: true, message: "User registered successfully!" });
    } catch (error) {
        console.error("Error in /register:", error);
        return res.status(500).json({ success: false, error: "Error registering user" });
    }
});

// LOGIN
router.post('/login', async (req, res) => {
    const { email, password } = req.body;

    try {
        const user = await pool.query("SELECT * FROM users WHERE email = $1", [email]);
        if (user.rows.length === 0) {
            return res.status(400).json({ success: false, error: "User not found" });
        }

        const isMatch = await bcrypt.compare(password, user.rows[0].password);
        if (!isMatch) {
            return res.status(400).json({ success: false, error: "Invalid credentials" });
        }

        const token = jwt.sign({ id: user.rows[0].id }, process.env.JWT_SECRET, { expiresIn: "1h" });

        return res.json({ success: true, token });

    } catch (error) {
        console.error("Error in /login:", error);
        return res.status(500).json({ success: false, error: "Server error" });
    }
});

module.exports = router;
//const authMiddleware = require('../middleware/authMiddleware');

/*router.get('/protected', authMiddleware, (req, res) => {
    res.json({ message: "This is a protected route", user: req.user });
});*/

