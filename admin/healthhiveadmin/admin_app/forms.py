from django import forms
from django.contrib.auth.models import User
from .models import MedicineReminder, AppointmentReminder


class MedicineReminderForm(forms.ModelForm):
    user = forms.ModelChoiceField(
        queryset=User.objects.all(),
        widget=forms.Select(attrs={
            'class': 'form-control',
            'placeholder': 'Select User'
        }),
        empty_label="Select User"
    )
    
    class Meta:
        model = MedicineReminder
        fields = ['user', 'medicine_name', 'days', 'dates', 'doses', 'meal_dependency']
        widgets = {
            'medicine_name': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': 'Enter medicine name'
            }),
            'days': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': 'e.g., M T W T F S S'
            }),
            'dates': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': 'e.g., 21, 22, 23'
            }),
            'doses': forms.NumberInput(attrs={
                'class': 'form-control',
                'min': '1',
                'placeholder': 'Number of doses'
            }),
            'meal_dependency': forms.Select(attrs={
                'class': 'form-control'
            })
        }


class AppointmentReminderForm(forms.ModelForm):
    user = forms.ModelChoiceField(
        queryset=User.objects.all(),
        widget=forms.Select(attrs={
            'class': 'form-control',
            'placeholder': 'Select User'
        }),
        empty_label="Select User"
    )
    
    class Meta:
        model = AppointmentReminder
        fields = ['user', 'appointment_date', 'appointment_time', 'place', 'purpose', 'doctor_name']
        widgets = {
            'appointment_date': forms.DateInput(attrs={
                'class': 'form-control',
                'type': 'date'
            }),
            'appointment_time': forms.TimeInput(attrs={
                'class': 'form-control',
                'type': 'time'
            }),
            'place': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': 'Hospital/Clinic name'
            }),
            'purpose': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': 'Purpose of appointment'
            }),
            'doctor_name': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': 'Doctor name (optional)'
            })
        }