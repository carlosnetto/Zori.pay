console.log('=== Authentication Check ===');
console.log('access_token:', localStorage.getItem('access_token') ? 'EXISTS' : 'NOT FOUND');
console.log('refresh_token:', localStorage.getItem('refresh_token') ? 'EXISTS' : 'NOT FOUND');
console.log('user:', localStorage.getItem('user'));
console.log('========================');
