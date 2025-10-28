# notifications/tasks.py
from celery import shared_task
from django.contrib.auth import get_user_model
from .utils import send_streak_notification, send_daily_reminder

User = get_user_model()

@shared_task(bind=True, max_retries=3)
def send_daily_reminder_task(self):
    try:
        for user in User.objects.all():
            send_daily_reminder(user)
    except Exception as e:
        raise self.retry(exc=e, countdown=60)  # Retry after 60 seconds

@shared_task(bind=True, max_retries=3)
def send_streak_notification_task(self):
    try:
        for user in User.objects.all():
            send_streak_notification(user)
    except Exception as e:
        raise self.retry(exc=e, countdown=60)
