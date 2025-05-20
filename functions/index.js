const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendSessionPush = functions.https.onRequest(async (req, res) => {
  const { token, title, body, data } = req.body;

  if (!token || !title || !body) {
    return res.status(400).send("❌ Missing required fields");
  }

  try {
    await admin.messaging().send({
      token,
      notification: { title, body },
      data: data || {},
    });

    return res.status(200).send("✅ Push sent");
  } catch (error) {
    console.error("❌ Push error:", error);
    return res.status(500).send(`❌ Push failed: ${error.message}`);
  }
});
