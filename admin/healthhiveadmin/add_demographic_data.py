import os
import django
import random

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'healthhive_admin.settings')
django.setup()

from django.contrib.auth.models import User
from admin_app.models import UserProfile

# Sample data
cities = ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia', 'San Antonio', 'San Diego']
states = ['California', 'Texas', 'Florida', 'New York', 'Pennsylvania', 'Illinois', 'Ohio', 'Georgia']
blood_groups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
genders = ['male', 'female', 'other']

users = User.objects.all()

for user in users:
    if hasattr(user, 'profile'):
        profile = user.profile
        
        # Add demographic data
        profile.age = random.randint(18, 75)
        profile.gender = random.choice(genders)
        profile.blood_group = random.choice(blood_groups)
        profile.city = random.choice(cities)
        profile.state = random.choice(states)
        
        profile.save()
        print(f"Updated profile for {user.username}: Age {profile.age}, Gender {profile.gender}, Blood {profile.blood_group}")
    else:
        # Create profile with demographic data
        profile = UserProfile.objects.create(
            user=user,
            age=random.randint(18, 75),
            gender=random.choice(genders),
            blood_group=random.choice(blood_groups),
            city=random.choice(cities),
            state=random.choice(states)
        )
        print(f"Created profile for {user.username}: Age {profile.age}, Gender {profile.gender}, Blood {profile.blood_group}")

print("\nDemographic data added successfully!")
