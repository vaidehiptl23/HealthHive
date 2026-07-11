from django.test import TestCase
from django.contrib.auth.models import User
from .models import UserProfile, MedicineReminder, AppointmentReminder


class UserProfileTestCase(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_profile_creation(self):
        profile = UserProfile.objects.create(
            user=self.user,
            phone='1234567890',
            document_count=5
        )
        self.assertEqual(profile.user, self.user)
        self.assertEqual(profile.phone, '1234567890')
        self.assertEqual(profile.document_count, 5)


class MedicineReminderTestCase(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_medicine_reminder_creation(self):
        reminder = MedicineReminder.objects.create(
            user=self.user,
            medicine_name='Paracetamol',
            days='M T W',
            dates='21, 22, 23',
            doses=2,
            meal_dependency='after'
        )
        self.assertEqual(reminder.user, self.user)
        self.assertEqual(reminder.medicine_name, 'Paracetamol')
        self.assertFalse(reminder.is_sent)