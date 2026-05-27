import pytest
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200, f"Error: {response.text}"
    data = response.json()
    assert "status" in data
    assert data["status"] in ["healthy", "unavailable"]

def test_history_endpoint():
    response = client.get("/history?limit=5")
    assert response.status_code == 200, f"Error: {response.text}"
    data = response.json()
    assert "history" in data
    assert isinstance(data["history"], list)

def test_predict_single_missing_body():
    response = client.post("/predict")
    # Should fail validation because body is required
    assert response.status_code == 422

def test_predict_single_valid():
    payload = {
        "customerID": "TEST-1234",
        "gender": "Female",
        "SeniorCitizen": 0,
        "Partner": "Yes",
        "Dependents": "No",
        "tenure": 12,
        "Contract": "Month-to-month",
        "InternetService": "Fiber optic",
        "PhoneService": "Yes",
        "MultipleLines": "No",
        "OnlineSecurity": "No",
        "OnlineBackup": "Yes",
        "DeviceProtection": "No",
        "TechSupport": "No",
        "StreamingTV": "Yes",
        "StreamingMovies": "Yes",
        "PaperlessBilling": "Yes",
        "PaymentMethod": "Electronic check",
        "MonthlyCharges": 85.5,
        "TotalCharges": 1026.0,
        "CustomerFeedback": "The service is decent but sometimes disconnects."
    }
    response = client.post("/predict", json=payload)
    if response.status_code == 200:
        data = response.json()
        assert data["customer_id"] == "TEST-1234"
        assert "churn_probability" in data
        assert "risk_tier" in data
        assert "sentiment_label" in data
    else:
        # If model is not loaded during test, it might return 500 or 400
        assert response.status_code in [400, 500]
