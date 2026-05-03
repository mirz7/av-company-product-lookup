import urllib.request
import json
import re

url = 'http://127.0.0.1:8000/api/register/'
data = {
    'username': 'testuser12345',
    'password': 'Password123!',
    'email': 'test3@test.com',
    'first_name': 'Test',
    'last_name': 'User',
    'role': 'STAFF',
    'phone_number': '1234567890'
}
req = urllib.request.Request(url, data=json.dumps(data).encode('utf-8'), headers={'Content-Type': 'application/json'})
try:
    with urllib.request.urlopen(req) as response:
        print('Status:', response.status)
        print('Response:', response.read().decode('utf-8'))
except urllib.error.HTTPError as e:
    body = e.read().decode('utf-8')
    match = re.search(r'<title>(.*?)</title>', body, re.DOTALL)
    if match:
        print('Error:', match.group(1).strip())
    match2 = re.search(r'<pre class="exception_value">(.*?)</pre>', body, re.DOTALL)
    if match2:
        print('Exception value:', match2.group(1).strip())
