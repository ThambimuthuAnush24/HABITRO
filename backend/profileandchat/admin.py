from django.contrib import admin
from .models import Message,UserProfile,Friendship
# Register your models here.
admin.site.register(Message)
admin.site.register(UserProfile)
admin.site.register(Friendship)