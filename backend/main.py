"""
FastAPI Server untuk Churn Intelligence System
Serve predictions via REST API dengan auto-generated documentation
"""

from fastapi import FastAPI, HTTPException, Request, Depends, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
import os
import hashlib
import sys
import logging
import time
import uuid
import json
import pandas as pd
import io
import traceback
from datetime import datetime
import uvicorn

# Import predictor & database
from predictor import get_predictor
predictor = None
from database import init_db, get_db, PredictionHistory, User

# ── Logging Setup ────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ── FastAPI App ──────────────────────────────────────────────────────────────
app = FastAPI(
    title="🎯 Customer Churn Intelligence API",
    description="Production-grade churn prediction service dengan Sentence Transformers + CatBoost",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)

# ── CORS Configuration (untuk Frontend) ───────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # ⚠️ For production: restrict ke domain tertentu
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Pydantic Models untuk Request/Response ──────────────────────────────────

class CustomerInput(BaseModel):
    """
    Input schema untuk single customer prediction
    """
    customerID: Optional[str] = Field(default="unknown", description="Unique customer ID")
    
    # Demographic
    gender: str = Field(..., description="Male / Female")
    SeniorCitizen: int = Field(..., description="0 atau 1")
    Partner: str = Field(..., description="Yes / No")
    Dependents: str = Field(..., description="Yes / No")
    
    # Service & Contract
    tenure: int = Field(..., description="Bulan menjadi customer")
    Contract: str = Field(..., description="Month-to-month / One year / Two year")
    InternetService: str = Field(..., description="DSL / Fiber optic / No")
    
    # Add-on services
    PhoneService: str = Field(default="No")
    MultipleLines: str = Field(default="No")
    OnlineSecurity: str = Field(default="No")
    OnlineBackup: str = Field(default="No")
    DeviceProtection: str = Field(default="No")
    TechSupport: str = Field(default="No")
    StreamingTV: str = Field(default="No")
    StreamingMovies: str = Field(default="No")
    
    # Billing
    PaperlessBilling: str = Field(..., description="Yes / No")
    PaymentMethod: str = Field(..., description="Electronic check / Mailed check / etc")
    MonthlyCharges: float = Field(..., description="Monthly billing amount")
    TotalCharges: float = Field(..., description="Total lifetime charges")
    
    # Feedback (NLP)
    CustomerFeedback: str = Field(
        default="",
        description="Customer feedback text (akan dianalisis via Sentence Transformers)"
    )
    
    class Config:
        schema_extra = {
            "example": {
                "customerID": "7590-VHVEG",
                "gender": "Female",
                "SeniorCitizen": 0,
                "Partner": "Yes",
                "Dependents": "No",
                "tenure": 1,
                "Contract": "Month-to-month",
                "InternetService": "DSL",
                "PhoneService": "No",
                "MultipleLines": "No",
                "OnlineSecurity": "No",
                "OnlineBackup": "Yes",
                "DeviceProtection": "No",
                "TechSupport": "No",
                "StreamingTV": "No",
                "StreamingMovies": "No",
                "PaperlessBilling": "Yes",
                "PaymentMethod": "Electronic check",
                "MonthlyCharges": 29.85,
                "TotalCharges": 29.85,
                "CustomerFeedback": "Service is okay but sometimes slow"
            }
        }


class PredictionOutput(BaseModel):
    """
    Output schema untuk prediction result
    """
    customer_id: str
    churn_probability: float = Field(..., description="0.0 - 1.0 probability")
    churn_prediction: int = Field(..., description="0 = No churn, 1 = Churn")
    risk_tier: str = Field(..., description="LOW / MEDIUM / HIGH")
    sentiment_label: str = Field(..., description="Negative / Neutral / Positive")
    sentiment_confidence: float = Field(..., description="0.0 - 1.0 confidence")
    top_churn_factors: List[str] = Field(..., description="Top 5 factors driving churn")
    recommended_action: str = Field(..., description="Business recommendation")
    feedback_text: Optional[str] = None
    model_version: str
    timestamp: Optional[str] = None
    process_time_ms: Optional[float] = None


class BatchPredictionRequest(BaseModel):
    """
    Input schema untuk batch prediction
    """
    customers: List[CustomerInput] = Field(..., description="List of customers")


class DeleteHistoryRequest(BaseModel):
    """
    Request schema untuk menghapus riwayat predcitions secara bulk
    """
    ids: List[int]


class BatchPredictionOutput(BaseModel):
    """
    Output schema untuk batch prediction
    """
    total_predictions: int
    high_risk_count: int
    medium_risk_count: int
    low_risk_count: int
    results: List[PredictionOutput]
    timestamp: str


class HealthCheck(BaseModel):
    """
    Health check response
    """
    status: str
    model_loaded: bool
    predictor_version: str
    timestamp: str


class AuthInput(BaseModel):
    """
    Schema for Authentication (Login / Signup)
    """
    username: str
    password: str
    name: Optional[str] = None


# ── Startup Event ────────────────────────────────────────────────────────────

@app.on_event("startup")
def startup_event():
    global predictor
    print("Initializing system components...")
    try:
        predictor = get_predictor()
    except Exception as e:
        print(f"Error loading predictor: {e}")
    init_db()
    print("Database initialized.")

# ── API Endpoints ────────────────────────────────────────────────────────────

def hash_password(password: str) -> str:
    salt = "churn_system_secret_salt_123"
    return hashlib.sha256((password + salt).encode()).hexdigest()

@app.post("/api/auth/signup", tags=["Auth"])
def auth_signup(auth_data: AuthInput, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(User.username == auth_data.username).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Username/Email already registered")
    
    hashed = hash_password(auth_data.password)
    new_user = User(
        username=auth_data.username,
        name=auth_data.name or auth_data.username.split('@')[0],
        password_hash=hashed
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return {"status": "success", "username": new_user.username, "name": new_user.name}

@app.post("/api/auth/login", tags=["Auth"])
def auth_login(auth_data: AuthInput, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == auth_data.username).first()
    if not user:
        raise HTTPException(status_code=401, detail="Invalid username or password")
    
    hashed = hash_password(auth_data.password)
    if user.password_hash != hashed:
        raise HTTPException(status_code=401, detail="Invalid username or password")
    
    return {"status": "success", "username": user.username, "name": user.name}

@app.get("/", tags=["Info"])
async def root():
    """Root endpoint dengan info"""
    return {
        "service": "Customer Churn Intelligence API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health",
        "predict": "/predict (POST)",
        "predict_batch": "/predict_batch (POST)",
        "history": "/history (GET)"
    }


@app.get("/health", tags=["Health"], response_model=HealthCheck)
async def health_check():
    """Health check endpoint"""
    try:
        is_loaded = predictor is not None and predictor.catboost_model is not None
        version = predictor.metadata.get('notebook_version', 'production_v1') if predictor else 'unknown'
        
        return HealthCheck(
            status="healthy" if is_loaded else "unavailable",
            model_loaded=is_loaded,
            predictor_version=version,
            timestamp=datetime.utcnow().isoformat() + "Z"
        )
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/predict", tags=["Prediction"], response_model=PredictionOutput, summary="Predict churn for a single customer")
async def predict_single(data: dict, db: Session = Depends(get_db)):
    """
    Predict churn probability for a single customer.
    Requires a dictionary containing all features.
    """
    start_time = time.time()
    try:
        customer_id = str(data.get('customerID', uuid.uuid4()))
        input_data = data.copy()
        
        # Predict
        result = predictor.predict(input_data)
        
        if result.get('status') == 'error':
            raise HTTPException(status_code=400, detail=result.get('message', 'Prediction failed'))
            
        process_time = time.time() - start_time
        
        # Construct response
        response = {
            "customer_id": customer_id,
            "churn_probability": result['churn_probability'],
            "churn_prediction": result['churn_prediction'],
            "risk_tier": result['risk_tier'],
            "sentiment_label": result['sentiment_label'],
            "sentiment_confidence": result['sentiment_confidence'],
            "feedback_text": input_data.get('CustomerFeedback', ''),
            "top_churn_factors": result['top_churn_factors'],
            "recommended_action": result['recommended_action'],
            "model_version": predictor.metadata.get('notebook_version', 'production_v1'),
            "process_time_ms": round(process_time * 1000, 2),
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
        
        # Save to DB
        try:
            db_record = PredictionHistory(
                customer_id=customer_id,
                churn_probability=result['churn_probability'],
                churn_prediction=result['churn_prediction'],
                risk_tier=result['risk_tier'],
                sentiment_label=result['sentiment_label'],
                sentiment_confidence=result['sentiment_confidence'],
                feedback_text=input_data.get('CustomerFeedback', ''),
                top_churn_factors=json.dumps(result['top_churn_factors']),
                recommended_action=result['recommended_action'],
                model_version=predictor.metadata.get('notebook_version', 'production_v1')
            )
            db.add(db_record)
            db.commit()
        except Exception as dbe:
            logger.error(f"DB Error: {dbe}")
            
        return response
        
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/predict_batch", tags=["Prediction"], response_model=BatchPredictionOutput, summary="Batch predict churn from CSV")
async def predict_batch(batch_request: BatchPredictionRequest, db: Session = Depends(get_db)):
    """
    Predict churn probability for multiple customers via JSON batch.
    """
    start_time = time.time()
    try:
        customers_dict = [c.dict() for c in batch_request.customers]
        results = predictor.predict_batch(customers_dict)
        
        db_records = []
        parsed_results = []
        for idx, r in enumerate(results):
            r['timestamp'] = datetime.utcnow().isoformat() + "Z"
            r['model_version'] = predictor.metadata.get('notebook_version', 'production_v1')
            r['feedback_text'] = customers_dict[idx].get('CustomerFeedback', '')
            parsed_results.append(PredictionOutput(**r))
            
            # Prepare DB record
            db_records.append(PredictionHistory(
                customer_id=r['customer_id'],
                churn_probability=r['churn_probability'],
                churn_prediction=r['churn_prediction'],
                risk_tier=r['risk_tier'],
                sentiment_label=r['sentiment_label'],
                sentiment_confidence=r['sentiment_confidence'],
                feedback_text=r['feedback_text'],
                top_churn_factors=json.dumps(r['top_churn_factors']),
                recommended_action=r['recommended_action'],
                model_version=r['model_version']
            ))
            
        high_count = sum(1 for r in results if r.get('risk_tier') == 'HIGH')
        med_count = sum(1 for r in results if r.get('risk_tier') == 'MEDIUM')
        low_count = sum(1 for r in results if r.get('risk_tier') == 'LOW')
        
        # Save to DB
        if db_records:
            try:
                db.add_all(db_records)
                db.commit()
            except Exception as dbe:
                logger.error(f"DB Error: {dbe}")
                
        return BatchPredictionOutput(
            total_predictions=len(results),
            high_risk_count=high_count,
            medium_risk_count=med_count,
            low_risk_count=low_count,
            results=parsed_results,
            timestamp=datetime.utcnow().isoformat() + "Z"
        )
        
    except Exception as e:
        logger.error(f"Batch prediction error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/metrics", tags=["Analytics"])
async def get_metrics():
    """Get model metrics"""
    try:
        metadata = predictor.metadata
        return {
            "test_roc_auc": metadata.get('test_roc_auc', 'N/A'),
            "cv_roc_auc": metadata.get('cv_roc_auc', 'N/A'),
            "risk_thresholds": metadata.get('risk_thresholds', {}),
            "total_features": len(metadata.get('cat_cols_combined', [])) + 24,
            "version": metadata.get('notebook_version', 'N/A')
        }
    except Exception as e:
        logger.error(f"Metrics retrieval failed: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/history", tags=["Analytics"], summary="Get prediction history")
def get_history(limit: int = 100, db: Session = Depends(get_db)):
    """Get prediction history"""
    records = db.query(PredictionHistory).order_by(PredictionHistory.timestamp.desc()).limit(limit).all()
    results = []
    for r in records:
        try:
            factors = json.loads(r.top_churn_factors) if r.top_churn_factors else []
        except:
            factors = []
        results.append({
            "id": r.id,
            "customer_id": r.customer_id,
            "churn_probability": r.churn_probability,
            "churn_prediction": r.churn_prediction,
            "risk_tier": r.risk_tier,
            "sentiment_label": r.sentiment_label,
            "sentiment_confidence": r.sentiment_confidence,
            "feedback_text": r.feedback_text,
            "top_churn_factors": factors,
            "recommended_action": r.recommended_action,
            "timestamp": r.timestamp.isoformat() + "Z"
        })
    return {"history": results}


@app.delete("/history/batch", tags=["Analytics"], summary="Bulk delete prediction history by ID list")
def delete_batch(req: DeleteHistoryRequest, db: Session = Depends(get_db)):
    """Menghapus data riwayat berdasarkan ID list"""
    try:
        if not req.ids:
            return {"status": "success", "deleted_count": 0}
        deleted = db.query(PredictionHistory).filter(PredictionHistory.id.in_(req.ids)).delete(synchronize_session=False)
        db.commit()
        return {"status": "success", "deleted_count": deleted}
    except Exception as e:
        db.rollback()
        logger.error(f"Failed to delete batch history: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/history/duplicates", tags=["Analytics"], summary="Delete duplicate history entries (keep latest)")
def delete_duplicates(db: Session = Depends(get_db)):
    """Menghapus data riwayat duplikat, hanya menyisakan satu (yang paling baru) untuk setiap customerID"""
    try:
        records = db.query(PredictionHistory).order_by(PredictionHistory.timestamp.desc()).all()
        seen_customers = set()
        to_delete = []
        for r in records:
            if r.customer_id in seen_customers:
                to_delete.append(r.id)
            else:
                seen_customers.add(r.customer_id)
        
        if to_delete:
            db.query(PredictionHistory).filter(PredictionHistory.id.in_(to_delete)).delete(synchronize_session=False)
            db.commit()
        return {"status": "success", "deleted_count": len(to_delete)}
    except Exception as e:
        db.rollback()
        logger.error(f"Failed to delete duplicates: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ── Error Handlers ───────────────────────────────────────────────────────────

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Generic exception handler"""
    logger.error(f"Unhandled exception: {str(exc)}")
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal server error",
            "detail": str(exc),
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
    )


# ── Main Entry Point ─────────────────────────────────────────────────────────

if __name__ == "__main__":
    """
    Run server dengan:
    
    uvicorn main:app --host 0.0.0.0 --port 8000 --reload
    
    Atau production:
    gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:8000
    """
    
    import argparse
    
    parser = argparse.ArgumentParser(description="Churn Intelligence API Server")
    parser.add_argument("--host", default="0.0.0.0", help="Server host")
    parser.add_argument("--port", type=int, default=8000, help="Server port")
    parser.add_argument("--reload", action="store_true", help="Enable auto-reload")
    parser.add_argument("--model-dir", default="models", help="Model directory path")
    
    args = parser.parse_args()
    
    # Set model dir env var
    os.environ['MODEL_DIR'] = args.model_dir
    
    # Run server
    logger.info(f"Starting Churn Intelligence API Server...")
    logger.info(f"   Host: {args.host}")
    logger.info(f"   Port: {args.port}")
    logger.info(f"   Model Dir: {args.model_dir}")
    logger.info(f"   API Docs: http://{args.host}:{args.port}/docs")
    
    uvicorn.run(
        "main:app",
        host=args.host,
        port=args.port,
        reload=args.reload,
        log_level="info"
    )
