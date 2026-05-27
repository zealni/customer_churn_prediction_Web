from urllib.request import urlopen, Request
from urllib.error import HTTPError
import json

data = json.dumps({
    'customerID': '7590-VHVEG',
    'gender': 'Female',
    'SeniorCitizen': 0,
    'Partner': 'Yes',
    'Dependents': 'No',
    'tenure': 1,
    'Contract': 'Month-to-month',
    'InternetService': 'DSL',
    'PhoneService': 'No',
    'MultipleLines': 'No',
    'OnlineSecurity': 'No',
    'OnlineBackup': 'Yes',
    'DeviceProtection': 'No',
    'TechSupport': 'No',
    'StreamingTV': 'No',
    'StreamingMovies': 'No',
    'PaperlessBilling': 'Yes',
    'PaymentMethod': 'Electronic check',
    'MonthlyCharges': 29.85,
    'TotalCharges': 29.85,
    'CustomerFeedback': 'Service is okay but sometimes slow'
}).encode()

try:
    req = Request('http://localhost:8000/predict', data=data, headers={'Content-Type': 'application/json'})
    resp = urlopen(req)
    print('SUCCESS:', resp.status)
    print(json.dumps(json.loads(resp.read()), indent=2))
except HTTPError as e:
    print('ERROR:', e.code)
    print(e.read().decode())
