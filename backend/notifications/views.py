from rest_framework import status, generics
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import DeviceToken
from .serializers import DeviceTokenSerializer
from .utils import send_to_user, send_push_notification
from rest_framework.decorators import api_view, permission_classes

class SaveDeviceTokenView(generics.CreateAPIView):
    serializer_class = DeviceTokenSerializer
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        token = request.data.get("token")
        if not token:
            return Response({"error": "Token is required"}, status=status.HTTP_400_BAD_REQUEST)

        # Check if token already exists for another user
        existing_token = DeviceToken.objects.filter(token=token).exclude(user=request.user).first()
        if existing_token:
            existing_token.delete()  # Remove from previous user

        device_token, created = DeviceToken.objects.get_or_create(
            user=request.user, 
            token=token
        )

        return Response(
            {"message": "Token saved", "created": created},
            status=status.HTTP_201_CREATED
        )

