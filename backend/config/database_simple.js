// Simple in-memory database for testing
const users = [];
const reminders = [];
const healthRecords = [];
const documents = [];
const familyMembers = [];

let userIdCounter = 1;
let reminderIdCounter = 1;
let healthRecordIdCounter = 1;
let documentIdCounter = 1;
let familyMemberIdCounter = 1;

// Simple database functions
const db = {
  // Users
  createUser: async (userData) => {
    const user = {
      id: userIdCounter++,
      ...userData,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    users.push(user);
    return user;
  },

  findUserByEmail: async (email) => {
    return users.find(user => user.email === email);
  },

  findUserById: async (id) => {
    return users.find(user => user.id === id);
  },

  // Reminders
  createReminder: async (reminderData) => {
    const reminder = {
      id: reminderIdCounter++,
      ...reminderData,
      completed: false,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    reminders.push(reminder);
    return reminder;
  },

  getRemindersByUserId: async (userId) => {
    return reminders.filter(reminder => reminder.user_id === userId);
  },

  // Health records
  createHealthRecord: async (recordData) => {
    const record = {
      id: healthRecordIdCounter++,
      ...recordData,
      created_at: new Date().toISOString()
    };
    healthRecords.push(record);
    return record;
  },

  getHealthRecordsByUserId: async (userId) => {
    return healthRecords.filter(record => record.user_id === userId);
  },

  // Documents
  createDocument: async (docData) => {
    const document = {
      id: documentIdCounter++,
      ...docData,
      created_at: new Date().toISOString()
    };
    documents.push(document);
    return document;
  },

  getDocumentsByUserId: async (userId) => {
    return documents.filter(doc => doc.user_id === userId);
  },

  // Family members
  createFamilyMember: async (memberData) => {
    const member = {
      id: familyMemberIdCounter++,
      ...memberData,
      created_at: new Date().toISOString()
    };
    familyMembers.push(member);
    return member;
  },

  getFamilyMembersByUserId: async (userId) => {
    return familyMembers.filter(member => member.user_id === userId);
  },

  // Test data
  initializeTestData: () => {
    // Add a test user
    users.push({
      id: 1,
      name: 'Test User',
      email: 'test@example.com',
      password: '$2a$10$TestPasswordHashForTesting',
      phone: '1234567890',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    });

    // Add test reminders
    reminders.push({
      id: 1,
      user_id: 1,
      title: 'Take Medicine',
      description: 'Blood pressure medication',
      date_time: new Date(Date.now() + 3600000).toISOString(),
      completed: false,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    });

    reminders.push({
      id: 2,
      user_id: 1,
      title: 'Doctor Appointment',
      description: 'Annual checkup',
      date_time: new Date(Date.now() + 86400000).toISOString(),
      completed: false,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    });

    console.log('✅ Test data initialized');
  }
};

// Initialize test data
db.initializeTestData();

console.log('✅ Simple in-memory database initialized');

module.exports = db;