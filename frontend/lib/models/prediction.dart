/// ── Prediction Result Model ────────────────────────────────────────────────
class PredictionResult {
  final int? id;
  final String customerId;
  final double churnProbability;
  final int churnPrediction;
  final String riskTier;
  final String sentimentLabel;
  final double sentimentConfidence;
  final List<String> topChurnFactors;
  final String recommendedAction;
  final String? feedbackText;
  final String modelVersion;
  final String? timestamp;

  PredictionResult({
    this.id,
    required this.customerId,
    required this.churnProbability,
    required this.churnPrediction,
    required this.riskTier,
    required this.sentimentLabel,
    required this.sentimentConfidence,
    required this.topChurnFactors,
    required this.recommendedAction,
    this.feedbackText,
    required this.modelVersion,
    this.timestamp,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      id: json['id'],
      customerId: json['customer_id'] ?? '',
      churnProbability: (json['churn_probability'] ?? 0).toDouble(),
      churnPrediction: json['churn_prediction'] ?? 0,
      riskTier: json['risk_tier'] ?? 'LOW',
      sentimentLabel: json['sentiment_label'] ?? 'Neutral',
      sentimentConfidence: (json['sentiment_confidence'] ?? 0).toDouble(),
      feedbackText: json['feedback_text'],
      topChurnFactors: List<String>.from(json['top_churn_factors'] ?? []),
      recommendedAction: json['recommended_action'] ?? '',
      modelVersion: json['model_version'] ?? '',
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'churn_probability': churnProbability,
        'churn_prediction': churnPrediction,
        'risk_tier': riskTier,
        'sentiment_label': sentimentLabel,
        'sentiment_confidence': sentimentConfidence,
        'feedback_text': feedbackText,
        'top_churn_factors': topChurnFactors,
        'recommended_action': recommendedAction,
        'model_version': modelVersion,
        'timestamp': timestamp,
      };

  /// Churn probability as percentage string
  String get probabilityPercent =>
      '${(churnProbability * 100).toStringAsFixed(1)}%';

  /// Whether the customer is likely to churn
  bool get isChurning => churnPrediction == 1;

  /// Risk icon emoji
  String get riskIcon {
    switch (riskTier.toUpperCase()) {
      case 'HIGH':
        return '🔴';
      case 'MEDIUM':
        return '🟡';
      case 'LOW':
        return '🟢';
      default:
        return '⚪';
    }
  }

  /// Sentiment icon emoji
  String get sentimentIcon {
    switch (sentimentLabel.toLowerCase()) {
      case 'negative':
        return '😠';
      case 'neutral':
        return '😐';
      case 'positive':
        return '😊';
      default:
        return '❓';
    }
  }
}

/// ── Batch Prediction Result ────────────────────────────────────────────────
class BatchPredictionResult {
  final int totalPredictions;
  final int highRiskCount;
  final int mediumRiskCount;
  final int lowRiskCount;
  final List<PredictionResult> results;
  final String timestamp;

  BatchPredictionResult({
    required this.totalPredictions,
    required this.highRiskCount,
    required this.mediumRiskCount,
    required this.lowRiskCount,
    required this.results,
    required this.timestamp,
  });

  factory BatchPredictionResult.fromJson(Map<String, dynamic> json) {
    return BatchPredictionResult(
      totalPredictions: json['total_predictions'] ?? 0,
      highRiskCount: json['high_risk_count'] ?? 0,
      mediumRiskCount: json['medium_risk_count'] ?? 0,
      lowRiskCount: json['low_risk_count'] ?? 0,
      results: (json['results'] as List? ?? [])
          .map((r) => PredictionResult.fromJson(r))
          .toList(),
      timestamp: json['timestamp'] ?? '',
    );
  }

  double get highRiskPercent =>
      totalPredictions > 0 ? (highRiskCount / totalPredictions) * 100 : 0;
  double get mediumRiskPercent =>
      totalPredictions > 0 ? (mediumRiskCount / totalPredictions) * 100 : 0;
  double get lowRiskPercent =>
      totalPredictions > 0 ? (lowRiskCount / totalPredictions) * 100 : 0;
}

/// ── Health Check Model ─────────────────────────────────────────────────────
class HealthCheck {
  final String status;
  final bool modelLoaded;
  final String predictorVersion;
  final String timestamp;

  HealthCheck({
    required this.status,
    required this.modelLoaded,
    required this.predictorVersion,
    required this.timestamp,
  });

  factory HealthCheck.fromJson(Map<String, dynamic> json) {
    return HealthCheck(
      status: json['status'] ?? 'unknown',
      modelLoaded: json['model_loaded'] ?? false,
      predictorVersion: json['predictor_version'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }

  bool get isHealthy => status == 'healthy' && modelLoaded;
}

/// ── Model Metrics ──────────────────────────────────────────────────────────
class ModelMetrics {
  final String model;
  final String nlpEngine;
  final dynamic testRocAuc;
  final dynamic cvRocAuc;
  final Map<String, dynamic> riskThresholds;
  final int totalFeatures;
  final String version;

  ModelMetrics({
    required this.model,
    required this.nlpEngine,
    required this.testRocAuc,
    required this.cvRocAuc,
    required this.riskThresholds,
    required this.totalFeatures,
    required this.version,
  });

  factory ModelMetrics.fromJson(Map<String, dynamic> json) {
    return ModelMetrics(
      model: json['model'] ?? '',
      nlpEngine: json['nlp_engine'] ?? '',
      testRocAuc: json['test_roc_auc'],
      cvRocAuc: json['cv_roc_auc'],
      riskThresholds:
          Map<String, dynamic>.from(json['risk_thresholds'] ?? {}),
      totalFeatures: json['total_features'] ?? 0,
      version: json['version'] ?? '',
    );
  }

  String get rocAucDisplay {
    if (testRocAuc is num) {
      return (testRocAuc as num).toStringAsFixed(4);
    }
    return testRocAuc?.toString() ?? 'N/A';
  }
}
