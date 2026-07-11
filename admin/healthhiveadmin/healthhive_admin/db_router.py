class HealthHiveRouter:
    """
    A router to control all database operations on models in the
    admin_app application.
    """
    route_app_labels = {'admin_app'}

    def db_for_read(self, model, **hints):
        if model._meta.db_table in ['users', 'medicine_reminders', 'appointment_reminders', 'family_members', 'documents', 'test_reminders']:
            return 'healthhive_db'
        return None

    def db_for_write(self, model, **hints):
        if model._meta.db_table in ['users', 'medicine_reminders', 'appointment_reminders', 'family_members', 'documents', 'test_reminders']:
            return 'healthhive_db'
        return None

    def allow_relation(self, obj1, obj2, **hints):
        return True

    def allow_migrate(self, db, app_label, model_name=None, **hints):
        if db == 'healthhive_db':
            return False # Never migrate healthhive_db from django!
        return None
