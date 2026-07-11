const http = require('http');

console.log('🔐 Testing Login API Response for Unregistered User\n');

// Test 1: Unregistered user
const testData1 = JSON.stringify({
  email: 'notregistered@test.com',
  password: 'anypassword'
});

const options1 = {
  hostname: 'localhost',
  port: 5000,
  path: '/api/auth/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(testData1)
  }
};

console.log('Test 1: Unregistered user login');
console.log('Email: notregistered@test.com');
console.log('Password: anypassword\n');

const req1 = http.request(options1, (res) => {
  console.log(`Status Code: ${res.statusCode}`);
  console.log(`Status: ${res.statusMessage}`);
  
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    try {
      const response = JSON.parse(data);
      console.log('Response:', response);
      
      if (res.statusCode === 401 && response.message === 'Invalid credentials') {
        console.log('\n✅ BACKEND IS WORKING CORRECTLY!');
        console.log('Unregistered users are rejected with "Invalid credentials"');
      } else {
        console.log('\n❌ ISSUE DETECTED!');
        console.log('Expected: 401 status with "Invalid credentials" message');
        console.log(`Got: ${res.statusCode} status with message: ${response.message}`);
      }
    } catch (e) {
      console.log('Error parsing response:', e.message);
    }
    
    // Now test with registered user
    console.log('\n' + '='.repeat(50));
    console.log('\nTest 2: Registered user login');
    console.log('Email: testuser@example.com');
    console.log('Password: mypassword123\n');
    
    const testData2 = JSON.stringify({
      email: 'testuser@example.com',
      password: 'mypassword123'
    });
    
    const options2 = {
      hostname: 'localhost',
      port: 5000,
      path: '/api/auth/login',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(testData2)
      }
    };
    
    const req2 = http.request(options2, (res2) => {
      console.log(`Status Code: ${res2.statusCode}`);
      console.log(`Status: ${res2.statusMessage}`);
      
      let data2 = '';
      res2.on('data', (chunk) => {
        data2 += chunk;
      });
      
      res2.on('end', () => {
        try {
          const response2 = JSON.parse(data2);
          console.log('Response:', response2);
          
          if (res2.statusCode === 200 && response2.success) {
            console.log('\n✅ Registered user can login successfully');
          } else {
            console.log('\n❌ Registered user login failed');
          }
        } catch (e) {
          console.log('Error parsing response:', e.message);
        }
      });
    });
    
    req2.on('error', (e) => {
      console.error(`Problem with request: ${e.message}`);
    });
    
    req2.write(testData2);
    req2.end();
  });
});

req1.on('error', (e) => {
  console.error(`Problem with request: ${e.message}`);
});

req1.write(testData1);
req1.end();