import os, re

path = os.path.join(os.path.dirname(__file__), '..', 'frontend', 'lib', 'widgets', 'prediction_card.dart')
with open(path, 'r', encoding='utf-8') as f: c = f.read()

c = re.sub(r'class PredictionCard extends StatefulWidget \{.*?State<PredictionCard> createState\(\) => _PredictionCardState\(\);\n\}', '''class PredictionCard extends StatefulWidget {
  final PredictionResult result;
  final VoidCallback? onNewPrediction;

  const PredictionCard({
    super.key,
    required this.result,
    this.onNewPrediction,
  });

  @override
  State<PredictionCard> createState() => _PredictionCardState();
}''', c, flags=re.DOTALL)

c = c.replace("widget.predictionData['risk_tier'] ?? 'Unknown'", "widget.result.riskTier")
c = c.replace("widget.predictionData['churn_probability'] ?? 0.0", "widget.result.churnProbability")
c = c.replace("widget.predictionData['customer_id']?.toString() ?? 'N/A'", "widget.result.customerId")
c = c.replace("(widget.predictionData['is_churning'] ?? false)", "widget.result.isChurning")
c = c.replace("${((widget.predictionData['churn_probability'] ?? 0.0) * 100).toStringAsFixed(1)}%", "${widget.result.probabilityPercent}")
c = c.replace("${widget.predictionData['risk_tier'] ?? 'N/A'}", "${widget.result.riskIcon} ${widget.result.riskTier}")
c = c.replace("context.riskColor(widget.predictionData['risk_tier'] ?? 'Low')", "context.riskColor(widget.result.riskTier)")
c = c.replace("widget.predictionData['model_version'] ?? 'N/A'", "widget.result.modelVersion")
c = c.replace("widget.predictionData['sentiment_label'] ?? 'Neutral'", "widget.result.sentimentLabel")
c = c.replace("widget.predictionData['sentiment_confidence'] ?? 0.0", "widget.result.sentimentConfidence")
c = c.replace("(widget.predictionData['top_churn_factors'] as List<dynamic>?) ?? []", "widget.result.topChurnFactors")
c = c.replace("widget.predictionData['risk_tier'] ?? 'Low'", "widget.result.riskTier")

# Also the recommendation variables
c = c.replace("widget.predictionData['recommended_action'] ?? 'No action required.'", "widget.result.recommendedActions")

c = re.sub(r'(?<!widget\.)result\.', 'widget.result.', c)
c = c.replace('widget.widget.', 'widget.')
c = c.replace('onNewPrediction', 'widget.onNewPrediction')
c = c.replace('widget.widget.onNewPrediction', 'widget.onNewPrediction')

with open(path, 'w', encoding='utf-8') as f: f.write(c)
