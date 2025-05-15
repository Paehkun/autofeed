const { onValueWritten } = require('firebase-functions/v2/database');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendLowFoodLevelNotification = onValueWritten(
  {
    region: 'asia-southeast1', // <-- Change this to your actual database region
    ref: '/users/{userId}/foodLevel',
  },
  async (event) => {
    const foodLevel = parseFloat(event.data.after.val());

    if (foodLevel <= 20) {
      const userId = event.params.userId;

      const message = {
        notification: {
          title: 'Food Level Low ',
          body: `Your fish food is at ${foodLevel}%..`,
        },
        topic: userId,
      };

      try {
        const response = await admin.messaging().send(message);
        console.log('✅ Notification sent:', response);
      } catch (error) {
        console.error('❌ Error sending notification:', error);
      }
    }

    return null;
  }
);
