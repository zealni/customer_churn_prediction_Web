"""
Predictor Module untuk Churn Intelligence System
Load model, handle feature engineering, dan predict churn dengan explainability
"""

import os
import json
import numpy as np
import pandas as pd
import joblib
import warnings
from typing import Dict, List, Any, Tuple
from sentence_transformers import SentenceTransformer
from catboost import CatBoostClassifier, Pool

warnings.filterwarnings('ignore')


class ChurnPredictor:
    """
    Production Predictor untuk Customer Churn Intelligence
    
    Workflow:
    1. Load model artifacts (CatBoost, PCA, Sentiment Classifier)
    2. Process input (feature engineering, embedding, normalization)
    3. Predict churn probability + risk tier
    4. Generate explainability factors
    5. Return business-ready recommendations
    """
    
    def __init__(self, model_dir: str = 'models'):
        """
        Initialize predictor dengan load semua artifacts
        
        Args:
            model_dir (str): Path ke direktori models
        """
        self.model_dir = model_dir
        self.device = 'cpu'  # FastAPI usually run di CPU
        
        print("[*] Loading Churn Predictor...")
        
        # ── Load Metadata ────────────────────────────────────────────────────
        metadata_path = os.path.join(model_dir, 'model_metadata.json')
        with open(metadata_path, 'r', encoding='utf-8') as f:
            self.metadata = json.load(f)
        print("[OK] Metadata loaded")
        
        # ── Load CatBoost Model ──────────────────────────────────────────────
        catboost_path = os.path.join(model_dir, 'catboost_main_model.cbm')
        self.catboost_model = CatBoostClassifier()
        self.catboost_model.load_model(catboost_path)
        print("[OK] CatBoost model loaded")
        
        # ── Load Sentiment Classifier (LogReg on embeddings) ────────────────
        sent_path = os.path.join(model_dir, 'sentiment_classifier.joblib')
        self.sentiment_clf = joblib.load(sent_path)
        print("[OK] Sentiment classifier loaded")
        
        # ── Load PCA (embeddings compressor) ─────────────────────────────────
        pca_path = os.path.join(model_dir, 'embedding_pca.joblib')
        self.pca = joblib.load(pca_path)
        print("[OK] PCA compressor loaded")
        
        # ── Load Sentence Transformer (NLP embedder) ────────────────────────
        embed_model_name = self.metadata.get('embed_model_name', 
                                             'sentence-transformers/all-MiniLM-L6-v2')
        self.embedder = SentenceTransformer(embed_model_name, device=self.device)
        print(f"[OK] Sentence Transformer loaded: {embed_model_name}")
        
        # ── Risk thresholds ──────────────────────────────────────────────────
        self.high_risk_thr = self.metadata['risk_thresholds']['high']
        self.med_risk_thr = self.metadata['risk_thresholds']['medium']
        
        # ── Categorical columns ──────────────────────────────────────────────
        self.cat_cols = self.metadata['cat_cols_combined']
        
        print("[OK] Churn Predictor initialization COMPLETE\n")
    
    # ── Private Methods ──────────────────────────────────────────────────────
    
    def _engineer_features(self, row: pd.Series) -> pd.Series:
        """
        Create derived features dari raw input
        
        Args:
            row (pd.Series): Single customer row
            
        Returns:
            pd.Series: Row dengan fitur engineered
        """
        # Avoid division by zero
        tenure = max(row.get('tenure', 1), 1)
        total_charges = row.get('TotalCharges', 0)
        monthly_charges = row.get('MonthlyCharges', 0)
        
        # Calculate new features (sesuai notebook)
        row['avg_monthly_charge'] = total_charges / tenure
        row['is_new_customer'] = 1 if tenure <= 6 else 0
        row['has_internet'] = 1 if row.get('InternetService', 'No') != 'No' else 0
        
        # Count services
        service_cols = ['OnlineSecurity', 'OnlineBackup', 'DeviceProtection',
                       'TechSupport', 'StreamingTV', 'StreamingMovies']
        num_services = sum(1 for col in service_cols 
                          if row.get(col) == 'Yes')
        row['num_services'] = num_services
        
        # Spending metrics
        median_charge = 65.0  # approximate dari dataset
        row['spending_rate'] = monthly_charges / median_charge if median_charge > 0 else 0
        row['charge_per_service'] = monthly_charges / max(num_services, 1)
        
        return row
    
    def _embed_feedback(self, feedback: str) -> np.ndarray:
        """
        Convert customer feedback ke embedding vector
        
        Args:
            feedback (str): Customer feedback text
            
        Returns:
            np.ndarray: Embedding 384-dim (normalized)
        """
        if not feedback or str(feedback).strip() == '':
            feedback = "no feedback provided"
        
        embedding = self.embedder.encode(
            [str(feedback)],
            batch_size=1,
            normalize_embeddings=True,
            show_progress_bar=False
        )
        return embedding[0]
    
    def _compress_embedding(self, embedding: np.ndarray) -> np.ndarray:
        """
        Compress embedding dari 384-dim → 24-dim via PCA
        
        Args:
            embedding (np.ndarray): Raw embedding (384-dim)
            
        Returns:
            np.ndarray: Compressed embedding (24-dim)
        """
        return self.pca.transform([embedding])[0]
    
    def _predict_sentiment(self, embedding_pca: np.ndarray) -> Tuple[str, float]:
        """
        Predict sentiment dari embedding
        
        Args:
            embedding_pca (np.ndarray): PCA-compressed embedding
            
        Returns:
            Tuple[str, float]: (sentiment_label, confidence)
        """
        pred = self.sentiment_clf.predict([embedding_pca])[0]
        proba = self.sentiment_clf.predict_proba([embedding_pca]).max()
        
        sentiment_map = {0: 'Negative', 1: 'Neutral', 2: 'Positive'}
        label = sentiment_map.get(pred, 'Neutral')
        
        return label, float(proba)
    
    def _get_churn_factors(self, row: pd.Series, churn_prob: float) -> List[str]:
        """
        Generate interpretable churn factors
        
        Args:
            row (pd.Series): Customer features
            churn_prob (float): Predicted churn probability
            
        Returns:
            List[str]: Top 3-5 factors driving churn
        """
        factors = []
        
        # Tenure factor
        tenure = row.get('tenure', 12)
        if tenure <= 6:
            factors.append("New customer (first 6 months)")
        
        # Contract factor
        contract = row.get('Contract', 'Month-to-month')
        if contract == 'Month-to-month':
            factors.append("Month-to-month contract (high-risk)")
        
        # Internet service
        internet = row.get('InternetService', 'DSL')
        if internet == 'Fiber optic':
            factors.append("Fiber optic service (historically higher churn)")
        
        # Monthly charges
        monthly = row.get('MonthlyCharges', 60)
        if monthly > 80:
            factors.append(f"High monthly charge (${monthly:.0f})")
        
        # Sentiment
        feedback = row.get('CustomerFeedback', '')
        if feedback and 'negative' in feedback.lower():
            factors.append("Negative customer feedback")
        
        # Services
        num_services = row.get('num_services', 0)
        if num_services <= 1:
            factors.append("Minimal add-on services")
        
        return factors[:5]  # Top 5 factors
    
    def _get_recommendation(self, risk_tier: str, factors: List[str]) -> str:
        """
        Generate business recommendation berdasarkan risk tier dan factors
        
        Args:
            risk_tier (str): 'HIGH', 'MEDIUM', 'LOW'
            factors (List[str]): Churn factors
            
        Returns:
            str: Actionable recommendation
        """
        if risk_tier == 'HIGH':
            return "[HIGH RISK] URGENT: Immediate customer callback + loyalty discount (20-30%) or service upgrade recommended"
        elif risk_tier == 'MEDIUM':
            return "[MEDIUM RISK] MONITOR: Proactive outreach, personalized offer, or service bundling to increase stickiness"
        else:
            return "[LOW RISK] MAINTAIN: Regular engagement, satisfaction checks, exclusive member perks"
    
    # ── Public Methods ───────────────────────────────────────────────────────
    
    def predict(self, customer_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Main prediction function
        
        Args:
            customer_data (Dict): Raw customer input
            {
                'gender': str,
                'SeniorCitizen': int,
                'tenure': int,
                'MonthlyCharges': float,
                'TotalCharges': float,
                'Contract': str,
                'InternetService': str,
                'CustomerFeedback': str,
                ... (other fields)
            }
            
        Returns:
            Dict: Comprehensive prediction output
            {
                'customer_id': str,
                'churn_probability': float,
                'churn_prediction': int,
                'risk_tier': str,
                'sentiment_label': str,
                'sentiment_confidence': float,
                'top_churn_factors': List[str],
                'recommended_action': str,
                'model_version': str
            }
        """
        try:
            # ── 1) Convert input ke Series ────────────────────────────────────
            row = pd.Series(customer_data).copy()
            
            # ── 2) Feature Engineering ───────────────────────────────────────
            row = self._engineer_features(row)
            
            # ── 3) Embedding & Sentiment Analysis ────────────────────────────
            feedback = str(row.get('CustomerFeedback', '') or '')
            embedding = self._embed_feedback(feedback)
            
            # Sentiment uses raw 384-dim embedding
            sentiment_label, sentiment_conf = self._predict_sentiment(embedding)
            
            # Sentiment probability features (per-class probabilities)
            sent_proba = self.sentiment_clf.predict_proba([embedding])[0]
            row['sent_prob_negative'] = float(sent_proba[0]) if len(sent_proba) > 0 else 0.0
            row['sent_prob_neutral'] = float(sent_proba[1]) if len(sent_proba) > 1 else 0.0
            row['sent_prob_positive'] = float(sent_proba[2]) if len(sent_proba) > 2 else 0.0
            row['sentiment_confidence'] = float(sentiment_conf)
            
            # Feedback text features
            row['feedback_length'] = len(feedback)
            row['feedback_word_count'] = len(feedback.split()) if feedback.strip() else 0
            
            # PCA compress for CatBoost features
            embedding_pca = self._compress_embedding(embedding)
            
            # ── 4) Prepare features untuk CatBoost ───────────────────────────
            # Add embedding columns
            emb_cols = [f'emb_pc_{i+1}' for i in range(24)]
            for i, col in enumerate(emb_cols):
                row[col] = embedding_pca[i]
            
            # Build DataFrame with ONLY the features CatBoost expects
            expected_features = self.catboost_model.feature_names_
            df_input = pd.DataFrame([row])
            
            # Ensure all expected features exist
            for feat in expected_features:
                if feat not in df_input.columns:
                    df_input[feat] = 0
            
            # Select only model features in correct order
            df_input = df_input[expected_features]
            
            # Handle categorical columns
            for col in self.cat_cols:
                if col in df_input.columns:
                    df_input[col] = df_input[col].fillna('missing').astype(str)
            
            # ── 5) Predict churn ─────────────────────────────────────────────
            pool_input = Pool(df_input, cat_features=self.cat_cols)
            prob_churn = self.catboost_model.predict_proba(pool_input)[0][1]
            pred_churn = int(prob_churn >= 0.5)
            
            # ── 6) Determine risk tier ───────────────────────────────────────
            if prob_churn >= self.high_risk_thr:
                risk_tier = 'HIGH'
            elif prob_churn >= self.med_risk_thr:
                risk_tier = 'MEDIUM'
            else:
                risk_tier = 'LOW'
            
            # ── 7) Extract churn factors ─────────────────────────────────────
            churn_factors = self._get_churn_factors(row, prob_churn)
            
            # ── 8) Generate recommendation ───────────────────────────────────
            recommendation = self._get_recommendation(risk_tier, churn_factors)
            
            # ── 9) Return output ─────────────────────────────────────────────
            output = {
                'customer_id': customer_data.get('customerID', 'unknown'),
                'churn_probability': round(float(prob_churn), 4),
                'churn_prediction': pred_churn,
                'risk_tier': risk_tier,
                'sentiment_label': sentiment_label,
                'sentiment_confidence': round(float(sentiment_conf), 4),
                'top_churn_factors': churn_factors,
                'recommended_action': recommendation,
                'model_version': self.metadata.get('notebook_version', 'production_v1')
            }
            
            return output
            
        except Exception as e:
            return {
                'error': str(e),
                'customer_id': customer_data.get('customerID', 'unknown'),
                'status': 'prediction_failed'
            }
    
    def predict_batch(self, customers_data: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Batch prediction untuk multiple customers
        
        Args:
            customers_data (List[Dict]): List of customer data
            
        Returns:
            List[Dict]: List of predictions
        """
        results = []
        for customer in customers_data:
            result = self.predict(customer)
            results.append(result)
        return results


# ── Singleton instance ──────────────────────────────────────────────────────
_predictor_instance = None


def get_predictor(model_dir: str = 'models') -> ChurnPredictor:
    """
    Get or create singleton predictor instance
    
    Args:
        model_dir (str): Path ke model directory
        
    Returns:
        ChurnPredictor: Predictor instance
    """
    global _predictor_instance
    if _predictor_instance is None:
        _predictor_instance = ChurnPredictor(model_dir=model_dir)
    return _predictor_instance


if __name__ == '__main__':
    # Test predictor (local testing only)
    print("Testing Churn Predictor...")
    
    predictor = ChurnPredictor()
    
    # Sample customer
    test_customer = {
        'customerID': 'TEST001',
        'gender': 'Male',
        'SeniorCitizen': 0,
        'Partner': 'Yes',
        'Dependents': 'No',
        'tenure': 2,
        'PhoneService': 'Yes',
        'MultipleLines': 'No',
        'InternetService': 'Fiber optic',
        'OnlineSecurity': 'No',
        'OnlineBackup': 'No',
        'DeviceProtection': 'No',
        'TechSupport': 'No',
        'StreamingTV': 'Yes',
        'StreamingMovies': 'Yes',
        'Contract': 'Month-to-month',
        'PaperlessBilling': 'Yes',
        'PaymentMethod': 'Electronic check',
        'MonthlyCharges': 95.5,
        'TotalCharges': 191.0,
        'CustomerFeedback': 'Service is terrible, very slow and unreliable. Not happy at all.'
    }
    
    result = predictor.predict(test_customer)
    print("\n" + "="*60)
    print("PREDICTION RESULT:")
    print("="*60)
    for key, val in result.items():
        print(f"{key:25s}: {val}")
