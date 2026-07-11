from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.db.models import Q
from django.utils import timezone
from datetime import date
from .models import AppUser, MedicineReminder, AppointmentReminder, FamilyMember, TestReminder
import json

def login_view(request):
    if request.user.is_authenticated:
        return redirect('dashboard')
    if request.method == 'POST':
        username = request.POST.get('username')
        password = request.POST.get('password')
        user = authenticate(request, username=username, password=password)
        if user is not None:
            login(request, user)
            messages.success(request, f'Welcome back, {user.username}!')
            return redirect('dashboard')
        else:
            messages.error(request, 'Invalid username or password.')
    return render(request, 'admin_app/login.html')

@login_required
def dashboard_view(request):
    from collections import Counter
    from django.db import connections
    from datetime import datetime
    
    total_users = AppUser.objects.using('healthhive_db').count()
    total_medicine_reminders = MedicineReminder.objects.using('healthhive_db').count()
    total_appointment_reminders = AppointmentReminder.objects.using('healthhive_db').count()
    total_test_reminders = TestReminder.objects.using('healthhive_db').count()
    total_reminders = total_medicine_reminders + total_appointment_reminders + total_test_reminders
    
    recent_users = AppUser.objects.using('healthhive_db').order_by('-created_at')[:3]
    recent_medicine_reminders = MedicineReminder.objects.using('healthhive_db').order_by('-created_at')[:3]
    recent_appointment_reminders = AppointmentReminder.objects.using('healthhive_db').order_by('-created_at')[:2]
    recent_test_reminders = TestReminder.objects.using('healthhive_db').order_by('-created_at')[:3]
    
    # Pull real user data via raw SQL
    genders = []
    blood_groups = []
    ages = []
    cities = []
    subscriptions = []
    user_analytics = []
    total_documents = 0
    total_file_size = 0
    
    try:
        with connections['healthhive_db'].cursor() as cursor:
            # Get full user profiles
            cursor.execute("""
                SELECT id, name, email, phone, gender, dob, blood_group, 
                       emergency_blood_group, address, subscription_plan, created_at
                FROM users ORDER BY created_at DESC
            """)
            columns = [col[0] for col in cursor.description]
            users_data = [dict(zip(columns, row)) for row in cursor.fetchall()]
            
            for u in users_data:
                # Medicine/Appointment/Test counts per user
                cursor.execute("SELECT COUNT(*) FROM medicine_reminders WHERE user_id=%s", [u['id']])
                med_count = cursor.fetchone()[0]
                cursor.execute("SELECT COUNT(*) FROM appointment_reminders WHERE user_id=%s", [u['id']])
                apt_count = cursor.fetchone()[0]
                cursor.execute("SELECT COUNT(*) FROM test_reminders WHERE user_id=%s", [u['id']])
                tst_count = cursor.fetchone()[0]
                cursor.execute("SELECT COUNT(*) FROM documents WHERE user_id=%s", [u['id']])
                doc_count = cursor.fetchone()[0]
                
                total = med_count + apt_count + tst_count
                
                # Gender
                gender = (u.get('gender') or '').strip().lower()
                if gender in ('male', 'female', 'other'):
                    genders.append(gender.capitalize())
                
                # Blood group (prefer blood_group, fallback to emergency)
                bg = u.get('blood_group') or u.get('emergency_blood_group') or ''
                bg = bg.strip()
                if bg:
                    blood_groups.append(bg)
                
                # Age from dob
                age = None
                dob_str = u.get('dob') or ''
                if dob_str:
                    try:
                        for fmt in ('%Y-%m-%d', '%d/%m/%Y', '%m/%d/%Y', '%d-%m-%Y'):
                            try:
                                dob_date = datetime.strptime(dob_str.strip(), fmt).date()
                                today = date.today()
                                age = today.year - dob_date.year - ((today.month, today.day) < (dob_date.month, dob_date.day))
                                ages.append(age)
                                break
                            except ValueError:
                                continue
                    except Exception:
                        pass
                
                # City from address
                addr = u.get('address') or ''
                if addr.strip():
                    parts = [p.strip() for p in addr.split(',')]
                    city = parts[0] if parts else ''
                    if city:
                        cities.append(city)
                
                # Subscription
                sub = u.get('subscription_plan') or 'free'
                subscriptions.append(sub)
                
                user_analytics.append({
                    'username': u['name'],
                    'email': u['email'],
                    'age': age,
                    'gender': gender if gender else None,
                    'blood_group': bg if bg else None,
                    'city': city if addr.strip() else None,
                    'state': parts[1] if addr.strip() and len(parts) > 1 else None,
                    'medicine_count': med_count,
                    'appointment_count': apt_count,
                    'test_count': tst_count,
                    'doc_count': doc_count,
                    'total_reminders': total,
                    'subscription': sub,
                    'is_active': True
                })
            
            # Total documents & storage
            cursor.execute("SELECT COUNT(*), COALESCE(SUM(file_size), 0) FROM documents")
            row = cursor.fetchone()
            total_documents = row[0] if row else 0
            total_file_size = row[1] if row else 0
            
    except Exception as e:
        print(f"Analytics error: {e}")
    
    # Sort by total reminders
    user_analytics.sort(key=lambda x: x['total_reminders'], reverse=True)
    user_activity_labels = [u['username'] for u in user_analytics[:5]]
    user_activity_data = [u['total_reminders'] for u in user_analytics[:5]]
    
    # Counters
    gender_counter = Counter(genders)
    blood_counter = Counter(blood_groups)
    city_counter = Counter(cities)
    sub_counter = Counter(subscriptions)
    
    # Age groups
    age_groups = {'0-18': 0, '19-30': 0, '31-45': 0, '46-60': 0, '60+': 0}
    for a in ages:
        if a <= 18: age_groups['0-18'] += 1
        elif a <= 30: age_groups['19-30'] += 1
        elif a <= 45: age_groups['31-45'] += 1
        elif a <= 60: age_groups['46-60'] += 1
        else: age_groups['60+'] += 1
    
    # Format storage
    if total_file_size > 1073741824:
        storage_str = f"{total_file_size / 1073741824:.1f} GB"
    elif total_file_size > 1048576:
        storage_str = f"{total_file_size / 1048576:.1f} MB"
    elif total_file_size > 1024:
        storage_str = f"{total_file_size / 1024:.1f} KB"
    else:
        storage_str = f"{total_file_size} B"
    
    # Engagement rate
    users_with_reminders = len([u for u in user_analytics if u['total_reminders'] > 0])
    engagement_rate = round((users_with_reminders / total_users * 100), 1) if total_users > 0 else 0
    
    context = {
        'total_users': total_users,
        'total_reminders': total_reminders,
        'total_medicine_reminders': total_medicine_reminders,
        'total_appointment_reminders': total_appointment_reminders,
        'total_test_reminders': total_test_reminders,
        'sent_today_total': 0,
        'recent_users': recent_users,
        'recent_medicine_reminders': recent_medicine_reminders,
        'recent_appointment_reminders': recent_appointment_reminders,
        'recent_test_reminders': recent_test_reminders,
        
        'user_analytics': user_analytics,
        'user_activity_labels': json.dumps(user_activity_labels),
        'user_activity_data': json.dumps(user_activity_data),
        
        'gender_labels': json.dumps(list(gender_counter.keys())),
        'gender_data': json.dumps(list(gender_counter.values())),
        'age_labels': json.dumps(list(age_groups.keys())),
        'age_data': json.dumps(list(age_groups.values())),
        'blood_labels': json.dumps(list(blood_counter.keys())),
        'blood_data': json.dumps(list(blood_counter.values())),
        'city_labels': json.dumps(list(city_counter.most_common(5)[:5] and [c[0] for c in city_counter.most_common(5)])),
        'city_data': json.dumps(list(city_counter.most_common(5)[:5] and [c[1] for c in city_counter.most_common(5)])),
        
        'active_users': total_users,
        'users_with_reminders': users_with_reminders,
        'avg_reminders_per_user': round(total_reminders / total_users, 1) if total_users > 0 else 0,
        'engagement_rate': engagement_rate,
        'avg_age': round(sum(ages) / len(ages)) if ages else 'N/A',
        'male_count': gender_counter.get('Male', 0),
        'female_count': gender_counter.get('Female', 0),
        'most_common_blood': blood_counter.most_common(1)[0][0] if blood_counter else 'N/A',
        'total_storage': storage_str,
        'total_documents': total_documents,
    }
    
    return render(request, 'admin_app/dashboard.html', context)

@login_required
def users_view(request):
    users = AppUser.objects.using('healthhive_db').order_by('-created_at')
    return render(request, 'admin_app/users.html', {'users': users})

@login_required
def user_detail_view(request, user_id):
    user = get_object_or_404(AppUser.objects.using('healthhive_db'), id=user_id)
    medicine_reminders = MedicineReminder.objects.using('healthhive_db').filter(user_id=user.id)
    appointment_reminders = AppointmentReminder.objects.using('healthhive_db').filter(user_id=user.id)
    test_reminders = TestReminder.objects.using('healthhive_db').filter(user_id=user.id)
    family_members = FamilyMember.objects.using('healthhive_db').filter(user_id=user.id)
    
    # Get subscription plan via raw query (column may exist)
    subscription_plan = 'free'
    try:
        from django.db import connections
        with connections['healthhive_db'].cursor() as cursor:
            cursor.execute("SELECT subscription_plan FROM users WHERE id = %s", [user.id])
            row = cursor.fetchone()
            if row and row[0]:
                subscription_plan = row[0]
    except Exception:
        pass
    
    # Get document count
    document_count = 0
    try:
        from django.db import connections
        with connections['healthhive_db'].cursor() as cursor:
            cursor.execute("SELECT COUNT(*) FROM documents WHERE user_id = %s", [user.id])
            row = cursor.fetchone()
            if row:
                document_count = row[0]
    except Exception:
        pass
    
    context = {
        'user': user,
        'medicine_reminders': medicine_reminders,
        'appointment_reminders': appointment_reminders,
        'test_reminders': test_reminders,
        'family_members': family_members,
        'subscription_plan': subscription_plan,
        'document_count': document_count,
    }
    return render(request, 'admin_app/user_detail.html', context)

@login_required
def reminders_view(request):
    medicine_reminders = MedicineReminder.objects.using('healthhive_db').order_by('-created_at')
    appointment_reminders = AppointmentReminder.objects.using('healthhive_db').order_by('-created_at')
    test_reminders = TestReminder.objects.using('healthhive_db').order_by('-created_at')
    total_medicine = medicine_reminders.count()
    total_appointments = appointment_reminders.count()
    total_tests = test_reminders.count()
    total_reminders = total_medicine + total_appointments + total_tests
    
    context = {
        'medicine_reminders': medicine_reminders,
        'appointment_reminders': appointment_reminders,
        'test_reminders': test_reminders,
        'total_reminders': total_reminders,
        'total_medicine': total_medicine,
        'total_appointments': total_appointments,
        'total_tests': total_tests,
        'total_pending': total_reminders,
        'pending_medicine': total_medicine,
        'pending_appointments': total_appointments,
        'total_sent': 0,
        'sent_medicine': 0,
        'sent_appointments': 0,
        'sent_today_total': 0,
        'sent_today_medicine': 0,
        'sent_today_appointments': 0,
        'users_with_reminders': AppUser.objects.using('healthhive_db').count(),
        'priority_total': 0,
        'priority_medicine': 0,
        'priority_appointments': 0,
        'completion_rate': 0,
    }
    return render(request, 'admin_app/reminders.html', context)

@login_required
def add_medicine_reminder(request):
    return redirect('reminders')

@login_required
def add_appointment_reminder(request):
    return redirect('reminders')

@login_required
def edit_medicine_reminder(request, reminder_id):
    return redirect('reminders')

@login_required
def edit_appointment_reminder(request, reminder_id):
    return redirect('reminders')

@login_required
def delete_medicine_reminder(request, reminder_id):
    reminder = get_object_or_404(MedicineReminder.objects.using('healthhive_db'), id=reminder_id)
    reminder.delete()
    messages.success(request, f'Medicine reminder deleted!')
    return redirect('reminders')

@login_required
def delete_appointment_reminder(request, reminder_id):
    reminder = get_object_or_404(AppointmentReminder.objects.using('healthhive_db'), id=reminder_id)
    reminder.delete()
    messages.success(request, f'Appointment reminder deleted!')
    return redirect('reminders')

@login_required
def send_medicine_reminder(request, reminder_id):
    messages.success(request, f'Reminder marked as sent (Mock)!')
    return redirect('reminders')

@login_required
def send_appointment_reminder(request, reminder_id):
    messages.success(request, f'Reminder marked as sent (Mock)!')
    return redirect('reminders')

@login_required
def send_test_reminder(request, reminder_id):
    messages.success(request, f'Test reminder marked as sent (Mock)!')
    return redirect('reminders')

@login_required
def delete_test_reminder(request, reminder_id):
    reminder = get_object_or_404(TestReminder.objects.using('healthhive_db'), id=reminder_id)
    reminder.delete()
    messages.success(request, f'Test reminder deleted!')
    return redirect('reminders')

@login_required
def toggle_user_block(request, user_id):
    messages.success(request, f'User block status toggled (Mock)!')
    return redirect('users')

def logout_view(request):
    logout(request)
    messages.info(request, 'You have been logged out successfully.')
    return redirect('login')