from django.urls import path
from .views import SaveDeviceTokenView

urlpatterns = [
    path("save-token/", SaveDeviceTokenView.as_view(), name="save-token"),
]
