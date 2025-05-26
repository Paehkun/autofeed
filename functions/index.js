const { onValueWritten } = require('firebase-functions/v2/database');
const admin = require('firebase-admin');
admin.initializeApp();
const moment = require('moment-timezone');

exports.sendLowFoodLevelNotification = onValueWritten(
  {
    region: 'asia-southeast1', //
    ref: '/users/{userId}/foodLevel',
  },
  async (event) => {
    const foodLevel = parseFloat(event.data.after.val());

    if (foodLevel <= 20) {
      const userId = event.params.userId;

      const message = {
        notification: {
          title: 'Food Level Low ',
          body: `Your fish food is at ${foodLevel}%.`,
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

exports.sendFeedSuccessNotification = onValueWritten(
  {
    region: 'asia-southeast1', // Your Firebase DB region
    ref: '/users/{userId}/feedingLog/success/{date}', // listens to each day's log
  },
  async (event) => {
    const userId = event.params.userId;
    const feedTimes = event.data.after.val();

    if (Array.isArray(feedTimes)) {
      const lastFeedTime = feedTimes.filter(Boolean).pop(); // get last non-null time
      if (!lastFeedTime) return null;

      // ✅ Get the current date in your local timezone
      const date = moment().tz('Asia/Kuala_Lumpur').format('YYYY-MM-DD');

      const message = {
        notification: {
          title: 'Feeding Successful 🐟',
          body: `Food was dispensed at ${lastFeedTime} today.`,
        },
        topic: userId,
      };

      try {
        const response = await admin.messaging().send(message);
        console.log('✅ Feed success notification sent:', response);
      } catch (error) {
        console.error('❌ Error sending feed success notification:', error);
      }
    }

    return null;
  }
);
