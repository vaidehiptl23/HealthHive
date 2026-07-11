import os
import django
import random

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'healthhive_admin.settings')
django.setup()

from django.contrib.auth.models import User
from admin_app.models import UserProfile

users = User.objects.all()

for user in users:
    if hasattr(user, 'profile'):
        profile = user.profile
        
        # Generate random document size between 0.5 MB and 50 MB
        document_size = round(random.uniform(0.5, 50.0), 2)
        profile.document_size = document_size
        
        # Also set document count if not already set
        if profile.document_count == 0:
            profile.document_count = random.randint(1, 15)
        
        profile.save()
        print(f"Updated {user.username}: {profile.document_count} documents, {profile.formatted_document_size}")
    else:
        # Create profile with document data
        document_size = round(random.uniform(0.5, 50.0), 2)
        document_count = random.randint(1, 15)
        
        profile = UserProfile.objects.create(
            user=user,
            document_size=document_size,
            document_count=document_count
        )
        print(f"Created profile for {user.username}: {document_count} documents, {profile.formatted_document_size}")

print("\nDocument sizes added successfully!")
