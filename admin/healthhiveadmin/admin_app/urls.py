from django.urls import path
from . import views

urlpatterns = [
    path('', views.login_view, name='login'),
    path('dashboard/', views.dashboard_view, name='dashboard'),
    path('users/', views.users_view, name='users'),
    path('user/<int:user_id>/', views.user_detail_view, name='user_detail'),
    path('reminders/', views.reminders_view, name='reminders'),
    
    # User management
    path('toggle-user-block/<int:user_id>/', views.toggle_user_block, name='toggle_user_block'),
    
    # Medicine reminder URLs
    path('add-medicine-reminder/', views.add_medicine_reminder, name='add_medicine_reminder'),
    path('edit-medicine-reminder/<int:reminder_id>/', views.edit_medicine_reminder, name='edit_medicine_reminder'),
    path('delete-medicine-reminder/<int:reminder_id>/', views.delete_medicine_reminder, name='delete_medicine_reminder'),
    path('send-medicine-reminder/<int:reminder_id>/', views.send_medicine_reminder, name='send_medicine_reminder'),
    
    # Appointment reminder URLs
    path('add-appointment-reminder/', views.add_appointment_reminder, name='add_appointment_reminder'),
    path('edit-appointment-reminder/<int:reminder_id>/', views.edit_appointment_reminder, name='edit_appointment_reminder'),
    path('delete-appointment-reminder/<int:reminder_id>/', views.delete_appointment_reminder, name='delete_appointment_reminder'),
    path('send-appointment-reminder/<int:reminder_id>/', views.send_appointment_reminder, name='send_appointment_reminder'),
    
    # Test reminder URLs
    path('send-test-reminder/<int:reminder_id>/', views.send_test_reminder, name='send_test_reminder'),
    path('delete-test-reminder/<int:reminder_id>/', views.delete_test_reminder, name='delete_test_reminder'),
    
    path('logout/', views.logout_view, name='logout'),
]