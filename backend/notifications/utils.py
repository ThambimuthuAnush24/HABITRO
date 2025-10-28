import firebase_admin
from firebase_admin import messaging
from datetime import timedelta
from django.utils.timezone import now
from .models import DeviceToken
from rewards.models import Reward
# -------------------------------
# Basic notification functions
# -------------------------------

def send_push_notification(token, title, body, data=None):
    """
    Send a push notification to a single device
    """
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        token=token,
        data=data or {},
    )
    try:
        response = messaging.send(message)
        print('Successfully sent message:', response)
        return True
    except messaging.UnregisteredError:
        DeviceToken.objects.filter(token=token).delete()
        print('Removed invalid token:', token)
        return False
    except Exception as e:
        print('Error sending message:', str(e))
        return False


def send_multicast_message(tokens, title, body, data=None):
    """
    Send push notifications to multiple devices (loop method)
    """
    success_count = 0
    failure_count = 0

    for token in tokens:
        result = send_push_notification(token, title, body, data)
        if result:
            success_count += 1
        else:
            failure_count += 1

    print(f"Multicast result: {success_count} successes, {failure_count} failures")
    return success_count


def send_to_user(user, title, body, data=None):
    """
    Send notification to all devices of a user
    """
    tokens = DeviceToken.objects.filter(user=user).values_list('token', flat=True)
    if tokens:
        return send_multicast_message(list(tokens), title, body, data)
    return 0

# -------------------------------
# Achievement notification
# -------------------------------

def send_achievement_notification(user, achievement):
    tokens = DeviceToken.objects.filter(user=user).values_list('token', flat=True)
    if not tokens:
        print(f"No device tokens for {user}")
        return

    success = send_multicast_message(
        list(tokens),
        "🏆 Achievement Unlocked!",
        f"You've unlocked the {achievement.title} achievement!",
        {"type": "achievement", "achievement_id": str(achievement.id)}
    )
    print(f"Achievement notification sent: {success} successes")

# -------------------------------
# Daily streak notification
# -------------------------------

def send_streak_notification(user):
    """
    Send daily streak notification based on Reward model
    """
    try:
        reward = user.reward
    except Reward.DoesNotExist:
        return

    today = now().date()
    last_claim = reward.last_claim_date.date() if reward.last_claim_date else None

    # Update streak
    if last_claim == today - timedelta(days=1):
        reward.daily_streak += 1
    elif last_claim != today:
        reward.daily_streak = 1  # reset streak

    reward.max_streak = max(reward.max_streak, reward.daily_streak)
    reward.last_claim_date = now()
    reward.save()

    # Send notification
    title = "🔥 Daily Streak!"
    body = f"You've maintained a {reward.daily_streak}-day streak! Keep it up 💪"
    send_to_user(user, title, body, {
        "type": "streak",
        "daily_streak": str(reward.daily_streak),
        "max_streak": str(reward.max_streak)
    })

# -------------------------------
# Daily reminder notification
# -------------------------------

def send_daily_reminder(user):
    """
    Send a static daily reminder to the user
    """
    title = "☀️ Good Morning!"
    body = "Have a great day! Don’t forget to follow your tasks today."
    send_to_user(user, title, body, {"type": "daily_reminder"})

# -------------------------------
# Chat notification
# -------------------------------

def send_chat_notification(sender, receiver, message_text):
    """
    Send a chat notification to the receiver
    """
    title = f"New message from {sender.username}"
    body = message_text if len(message_text) < 100 else message_text[:97] + "..."
    send_to_user(receiver, title, body, {
        "type": "chat",
        "sender_id": str(sender.id),
        "message": message_text
    })
