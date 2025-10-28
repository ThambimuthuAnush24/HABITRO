from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Achievement , UserAchievement
from rewards.models import Reward
from game.models import GameStats
from django.apps import apps

@receiver(post_save, sender=GameStats)
def check_game_achievements(sender, instance, **kwargs):
    user = instance.user
    achievements = Achievement.objects.all()

    for achievement in achievements:
        if achievement.unlock_condition == 'first_win' and instance.games_won >= 1:
            user_achievement, created = UserAchievement.objects.get_or_create(
                user=user,
                achievement=achievement,
                defaults={'unlocked': True}
            )
            if created:
                send_achievement_notification(user, achievement)

        elif achievement.unlock_condition == '5_win' and instance.games_won >= 5:
            user_achievement, created = UserAchievement.objects.get_or_create(
                user=user,
                achievement=achievement,
                defaults={'unlocked': True}
            )
            if created:
                send_achievement_notification(user, achievement)

        elif achievement.unlock_condition == '10_win' and instance.games_won >= 10:
            user_achievement, created = UserAchievement.objects.get_or_create(
                user=user,
                achievement=achievement,
                defaults={'unlocked': True}
            )
            if created:
                send_achievement_notification(user, achievement)

        elif achievement.unlock_condition == '25_win' and instance.games_won >= 25:
            user_achievement, created = UserAchievement.objects.get_or_create(
                user=user,
                achievement=achievement,
                defaults={'unlocked': True}
            )
            if created:
                send_achievement_notification(user, achievement)
                
        elif achievement.unlock_condition == '50_win' and instance.games_won >= 50:
            user_achievement, created = UserAchievement.objects.get_or_create(
                user=user,
                achievement=achievement,
                defaults={'unlocked': True}
            )
            if created:
                send_achievement_notification(user, achievement)
                
        elif achievement.unlock_condition == '100_win' and instance.games_won >= 100:
            user_achievement, created = UserAchievement.objects.get_or_create(
                user=user,
                achievement=achievement,
                defaults={'unlocked': True}
            )
            if created:
                send_achievement_notification(user, achievement)


@receiver(post_save, sender=Reward)
def check_streak_achievements(sender, instance, **kwargs):
    user = instance.user
    if instance.daily_streak >= 3:
        achievement = Achievement.objects.get(unlock_condition='3_day_streak')
        user_achievement, created = UserAchievement.objects.get_or_create(
            user=user,
            achievement=achievement,
            defaults={'unlocked': True}
        )
        if created:
            send_achievement_notification(user, achievement)
        
def send_achievement_notification(user, achievement):
    """
    Send notification about an unlocked achievement
    """
    try:
        # Import here to avoid circular imports
        DeviceToken = apps.get_model('notifications', 'DeviceToken')
        from notifications.utils import send_achievement_notification as send_notification
        
        tokens = DeviceToken.objects.filter(user=user).values_list('token', flat=True)
        
        if tokens:
            title = "Achievement Unlocked!"
            body = f"You've unlocked the {achievement.title} achievement!"
            
            # Send to all user devices
            send_notification(user, achievement)
    except Exception as e:
        # Handle exceptions (e.g., app not installed, model not found)
        print(f"Error sending achievement notification: {e}")