from django.db import models

class AppUser(models.Model):
    id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=100)
    email = models.CharField(max_length=100)
    phone = models.CharField(max_length=20, null=True, blank=True)
    emergency_blood_group = models.CharField(max_length=10, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        managed = False
        db_table = 'users'
        
    def __str__(self):
        return f"{self.name} ({self.email})"
        
    @property
    def username(self):
        return self.name
        
    @property
    def profile(self):
        return self
        
    @property
    def full_name(self):
        return self.name
        
    @property
    def document_count(self):
        try:
            from django.db import connections
            with connections['healthhive_db'].cursor() as cursor:
                cursor.execute("SELECT COUNT(*) FROM documents WHERE user_id = %s", [self.id])
                row = cursor.fetchone()
                return row[0] if row else 0
        except Exception:
            return 0
        
    @property
    def formatted_document_size(self):
        return "0 KB"
    
    @property
    def is_active(self):
        return True

class FamilyMember(models.Model):
    id = models.AutoField(primary_key=True)
    user = models.ForeignKey(AppUser, on_delete=models.CASCADE, db_column='user_id', related_name='family_members')
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    email = models.CharField(max_length=100, null=True, blank=True)
    blood_group = models.CharField(max_length=10, null=True, blank=True)
    gender = models.CharField(max_length=20, null=True, blank=True)
    phone = models.CharField(max_length=20, null=True, blank=True)
    dob = models.CharField(max_length=50, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        managed = False
        db_table = 'family_members'
    
    def __str__(self):
        return f"{self.first_name} {self.last_name}"
    
    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"

class MedicineReminder(models.Model):
    id = models.AutoField(primary_key=True)
    user = models.ForeignKey(AppUser, on_delete=models.CASCADE, db_column='user_id', related_name='medicine_reminders')
    name = models.CharField(max_length=200, db_column='name')
    dose = models.CharField(max_length=100, null=True, blank=True)
    meal = models.CharField(max_length=100, null=True, blank=True)
    morning = models.BooleanField(default=False)
    morning_time = models.CharField(max_length=20, null=True, blank=True)
    afternoon = models.BooleanField(default=False)
    afternoon_time = models.CharField(max_length=20, null=True, blank=True)
    night = models.BooleanField(default=False)
    night_time = models.CharField(max_length=20, null=True, blank=True)
    repeat_days = models.CharField(max_length=100, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    # Adding mock properties to allow old dashboard code to continue to render
    @property
    def medicine_name(self):
        return self.name
        
    @property
    def is_sent(self):
        return False
        
    class Meta:
        managed = False
        db_table = 'medicine_reminders'
        
    def __str__(self):
        return f"{self.name} for {self.user.name}"

class AppointmentReminder(models.Model):
    id = models.AutoField(primary_key=True)
    user = models.ForeignKey(AppUser, on_delete=models.CASCADE, db_column='user_id', related_name='appointment_reminders')
    place = models.CharField(max_length=200)
    date = models.CharField(max_length=100)
    time = models.CharField(max_length=100)
    purpose = models.CharField(max_length=300)
    created_at = models.DateTimeField(auto_now_add=True)
    
    @property
    def appointment_date(self):
        return self.date
        
    @property
    def appointment_time(self):
        return self.time

    @property
    def is_sent(self):
        return False
        
    class Meta:
        managed = False
        db_table = 'appointment_reminders'
        ordering = ['-created_at']
        
    def __str__(self):
        return f"Appointment for {self.user.name} at {self.place}"

class TestReminder(models.Model):
    id = models.AutoField(primary_key=True)
    user = models.ForeignKey(AppUser, on_delete=models.CASCADE, db_column='user_id', related_name='test_reminders')
    name = models.CharField(max_length=200)
    meal = models.CharField(max_length=100, null=True, blank=True)
    morning = models.BooleanField(default=False)
    morning_time = models.CharField(max_length=20, null=True, blank=True)
    afternoon = models.BooleanField(default=False)
    afternoon_time = models.CharField(max_length=20, null=True, blank=True)
    night = models.BooleanField(default=False)
    night_time = models.CharField(max_length=20, null=True, blank=True)
    repeat_days = models.CharField(max_length=100, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    @property
    def test_name(self):
        return self.name
    
    @property
    def is_sent(self):
        return False
        
    class Meta:
        managed = False
        db_table = 'test_reminders'
        ordering = ['-created_at']
        
    def __str__(self):
        return f"Test {self.name} for {self.user.name}"