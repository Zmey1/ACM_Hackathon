const OneSignal = require("onesignal-node");

// Initialize OneSignal Client
const client = new OneSignal.Client("6bdd97f9-436f-4728-90b2-03c8985f7312", "os_v2_app_npozp6kdn5dsrefsapejqx3tcilm5qe7lmcu365g5kf2sh7gglknoo42l6t44yz5mnqtumlepf6jvcfigysg7sitdcywosbzjzvthfy");

async function sendPushNotification(userId, message) {
    const notification = {
        contents: { en: message }, // Message in English
        include_external_user_ids: [userId] // User's OneSignal ID
    };

    try {
        await client.createNotification(notification);
        console.log("✅ Push Notification Sent!");
    } catch (error) {
        console.error("❌ Error Sending Notification:", error);
    }
}

async function sendSMSNotification(phone, message) {
    const smsNotification = {
        recipients: [{ number: phone }],
        message: message
    };

    try {
        await client.createSmsNotification(smsNotification);
        console.log("✅ SMS Sent Successfully!");
    } catch (error) {
        console.error("❌ Error Sending SMS:", error);
    }
}