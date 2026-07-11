# Data Analytics Features Added

## Overview
Comprehensive data analytics dashboard with demographic insights for users and their members.

## New Features Added

### 1. Demographic Fields in UserProfile Model
- **Age**: Integer field for user age
- **Gender**: Choice field (Male, Female, Other)
- **Blood Group**: Choice field (A+, A-, B+, B-, AB+, AB-, O+, O-)
- **City**: Text field for user's city
- **State**: Text field for user's state

### 2. Analytics Charts (6 Total)

#### User Activity Chart
- Bar chart showing total reminders per user
- Displays top 5 most active users
- Color: Purple gradient

#### Reminder Distribution Chart
- Doughnut chart showing medicine vs appointment reminders
- Colors: Orange for medicine, Green for appointments

#### Gender Distribution Chart
- Pie chart showing male, female, and other gender distribution
- Colors: Blue (Male), Pink (Female), Purple (Other)

#### Age Distribution Chart
- Bar chart with age ranges: 18-30, 31-45, 46-60, 60+
- Color: Green gradient

#### Blood Group Distribution Chart
- Doughnut chart showing all blood group types
- Color: Red gradient variations

#### Location Distribution Chart
- Horizontal bar chart showing top 5 cities
- Color: Blue gradient

### 3. Enhanced User Analytics Table
Now includes:
- User name and email
- Age
- Gender (with icons)
- Blood group
- Location (City, State)
- Medicine reminder count
- Appointment reminder count
- Total reminders
- Active/Blocked status

### 4. Key Insights Cards (8 Total)

#### General Insights
1. **Active Users**: Total number of active users
2. **Avg Reminders/User**: Average reminders per user
3. **Users with Reminders**: Count of users who have reminders
4. **Engagement Rate**: Percentage of users with reminders

#### Demographic Insights
5. **Average Age**: Mean age of all users
6. **Female Users**: Total female user count
7. **Male Users**: Total male user count
8. **Most Common Blood**: Most frequent blood group

## Technical Implementation

### Database Changes
- Migration created: `0003_userprofile_age_userprofile_blood_group_and_more.py`
- Added 5 new fields to UserProfile model

### Files Modified
1. `admin_app/models.py` - Added demographic fields
2. `admin_app/views.py` - Added analytics calculations
3. `templates/admin_app/dashboard.html` - Added charts and tables
4. `add_demographic_data.py` - Script to populate sample data

### Libraries Used
- Chart.js 4.4.0 for data visualization
- Django ORM for data aggregation
- Python Collections.Counter for demographic analysis

## Sample Data
Script `add_demographic_data.py` populates:
- Random ages between 18-75
- Random gender distribution
- Random blood groups
- Random cities from major US cities
- Random states

## Visual Design
- Pastel color gradients for all charts
- Responsive grid layout
- Icons for better visual representation
- Smooth animations and transitions
- Mobile-friendly design

## Usage
1. Run migrations: `python manage.py migrate`
2. Add demographic data: `python add_demographic_data.py`
3. Start server: `python manage.py runserver`
4. Visit: http://127.0.0.1:8000/
5. Login with: admin/admin123

## Benefits
- Complete demographic overview of user base
- Visual insights into user engagement
- Easy identification of trends and patterns
- Better understanding of user distribution
- Data-driven decision making for admin
