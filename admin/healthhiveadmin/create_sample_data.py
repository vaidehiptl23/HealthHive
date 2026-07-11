#!/usr/bin/env python
import os
import django
from datetime import date, time

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'healthhive_admin.settings')
django.setup()

from django.contrib.auth.models import User
from admin_app.models import UserProfile, MedicineReminder, AppointmentReminder

# Create sample users if they don't exist
users_data = [
    {'username': 'john_doe', 'email': 'john@example.com', 'first_name': 'John', 'last_name': 'Doe'},
    {'username': 'jane_smith', 'email': 'jane@example.com', 'first_name': 'Jane', 'last_name': 'Smith'},
    {'username': 'bob_wilson', 'email': 'bob@example.com', 'first_name': 'Bob', 'last_name': 'Wilson'},
]

created_users = []
for user_data in users_data:
    user, created = User.objects.get_or_create(
        username=user_data['username'],
        defaults={
            'email': user_data['email'],
            'first_name': user_data['first_name'],
            'last_name': user_data['last_name']
        }
    )
    if created:
        print(f"✅ Created user: {user.username}")
        # Create user profile
        profile, _ = UserProfile.objects.get_or_create(
            user=user,
            defaults={
                'phone': '1234567890',
                'document_count': 5
            }
        )
    created_users.append(user)

# Create sample medicine reminders
medicine_reminders_data = [
    {
        'medicine_name': 'Paracetamol',
        'days': 'M T W T F',
        'dates': '1, 2, 3, 4, 5',
        'doses': 2,
        'meal_dependency': 'after'
    },
    {
        'medicine_name': 'Vitamin D',
        'days': 'Daily',
        'dates': 'Every day',
        'doses': 1,
        'meal_dependency': 'with'
    },
    {
        'medicine_name': 'Blood Pressure Medicine',
        'days': 'M W F',
        'dates': '1, 3, 5',
        'doses': 1,
        'meal_dependency': 'before'
    }
]

for i, reminder_data in enumerate(medicine_reminders_data):
    if i < len(created_users):
        reminder, created = MedicineReminder.objects.get_or_create(
            user=created_users[i],
            medicine_name=reminder_data['medicine_name'],
            defaults=reminder_data
        )
        if created:
            print(f"✅ Created medicine reminder: {reminder.medicine_name} for {reminder.user.username}")

# Create sample appointment reminders
appointment_reminders_data = [
    {
        'appointment_date': date(2026, 2, 15),
        'appointment_time': time(10, 30),
        'place': 'City General Hospital',
        'purpose': 'Regular Checkup',
        'doctor_name': 'Dr. Smith'
    },
    {
        'appointment_date': date(2026, 2, 20),
        'appointment_time': time(14, 0),
        'place': 'Heart Care Clinic',
        'purpose': 'Cardiology Consultation',
        'doctor_name': 'Dr. Johnson'
    }
]

for i, appointment_data in enumerate(appointment_reminders_data):
    if i < len(created_users):
        reminder, created = AppointmentReminder.objects.get_or_create(
            user=created_users[i],
            appointment_date=appointment_data['appointment_date'],
            appointment_time=appointment_data['appointment_time'],
            defaults=appointment_data
        )
        if created:
            print(f"✅ Created appointment reminder for {reminder.user.username} on {reminder.appointment_date}")

print("\n🎉 Sample data created successfully!")
print("\n📋 What was created:")
print(f"   👥 Users: {len(created_users)}")
print(f"   💊 Medicine Reminders: {MedicineReminder.objects.count()}")
print(f"   📅 Appointment Reminders: {AppointmentReminder.objects.count()}")
print("\n🌐 Visit http://127.0.0.1:8000/ to see the data in your admin panel!")