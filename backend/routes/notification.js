const OneSignal = require("onesignal-node");

const client = new OneSignal.Client(
    process.env.ONESIGNAL_APP_ID,
    process.env.ONESIGNAL_API_KEY
);

async function sendWeatherNotification(playerIds, message) {
    if (!playerIds || playerIds.length === 0) {
        console.log("⚠️ No users to send notifications.");
        return;
    }

    const notification = {
        contents: { en: message },
        include_player_ids: playerIds
    };

    try {
        await client.createNotification(notification);
        console.log("✅ Push Notification Sent!");
    } catch (error) {
        console.error("❌ Error Sending Notification:", error);
    }
}

module.exports = { sendWeatherNotification };
