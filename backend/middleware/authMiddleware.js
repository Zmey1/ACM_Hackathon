const jwt = require('jsonwebtoken');

module.exports = (req, res, next) => {
    const token = req.header('Authorization');
    
    if (!token) return res.status(401).json({ error: "Access denied, no token provided" });

    try {
        const verified = jwt.verify(token, process.env.JWT_SECRET);
        req.user = verified; // Attach user info to request
        next();
    } catch (err) {
        res.status(400).json({ error: "Invalid token" });
    }
};