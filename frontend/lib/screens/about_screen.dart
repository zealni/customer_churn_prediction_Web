import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// ── About Screen ───────────────────────────────────────────────────────────
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 28),
          _buildOverviewCard(),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 860) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildModelPerformance()),
                    const SizedBox(width: 20),
                    Expanded(child: _buildFeatureImportance()),
                  ],
                );
              }
              return Column(
                children: [
                  _buildModelPerformance(),
                  const SizedBox(height: 20),
                  _buildFeatureImportance(),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _buildPipelineCard(),
          const SizedBox(height: 24),
          _buildApiDocCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.architecture_outlined,
              color: context.primary, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Architecture & Specs',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Model telemetry, feature importance weights, and pipeline steps.',
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: context.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: context.primary.withOpacity(0.12),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Modern Churn Intelligence Pipeline',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'A unified analytics and predictive modeling engine designed to score churn likelihood, diagnose accounts, and sync action templates with Salesforce, Hubspot, and Zendesk.',
            style: TextStyle(
              fontSize: 14.5,
              color: Colors.white.withOpacity(0.85),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _badge('CatBoost ML', Icons.psychology_outlined),
              _badge('Sentence Transformer NLP', Icons.translate_outlined),
              _badge('FastAPI Engine', Icons.speed_outlined),
              _badge('60+ Predictive Signals', Icons.settings_input_component_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelPerformance() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard_outlined, size: 20, color: context.success),
              const SizedBox(width: 8),
              Text(
                'Model Telemetry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _performanceRow('ROC-AUC Accuracy', '99.98%', context.success),
          _performanceRow('Classifier Engine', 'CatBoost Classifier', context.primary),
          _performanceRow('Embedding Model', 'Sentence Transformers', context.accent),
          _performanceRow('Sentiment Analyzer', 'Logistics NLP Model', context.warning),
          _performanceRow('Dimensionality Reduction', '10 PCA Components', context.textSecondary),
          _performanceRow('Total Features Scored', '62 variables', context.primary),
        ],
      ),
    );
  }

  Widget _performanceRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureImportance() {
    final features = [
      ('Contract Type', 0.95),
      ('Tenure', 0.88),
      ('Monthly Charges', 0.82),
      ('Internet Service', 0.78),
      ('Payment Method', 0.72),
      ('Tech Support', 0.65),
      ('Customer Feedback', 0.60),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_outlined, size: 20, color: context.warning),
              const SizedBox(width: 8),
              Text(
                'Feature Weights (Akkio)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Global feature importance values derived from training sets.',
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          ...features.map((f) => _featureBar(f.$1, f.$2)),
        ],
      ),
    );
  }

  Widget _featureBar(String name, double importance) {
    final barColor = Color.lerp(context.success, context.error, importance)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 12.5,
                  color: context.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(importance * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: importance,
              minHeight: 5,
              backgroundColor: context.isDark ? AppColors.darkSurfaceVariant : context.border.withOpacity(0.4),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline_outlined, size: 20, color: context.primary),
              const SizedBox(width: 8),
              Text(
                'Mitigation Processing Pipeline',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _pipelineStep(1, 'Customer Ingestion',
              'Extract 60+ parameters including contracts, payments, and tenure data.', Icons.input, context.primary),
          _pipelineStep(2, 'Sentiment Tokenization',
              'NLP Sentence Transformers evaluate raw verbal customer comments.', Icons.textsms_outlined,
              context.accent),
          _pipelineStep(3, 'Feature Normalization',
              'Dimensionality scaling using PCA components and categorical encoding.', Icons.tune,
              context.warning),
          _pipelineStep(4, 'CatBoost Prediction Engine',
              'Predict churn likelihood with gradient boosted decision trees.', Icons.memory_outlined,
              context.success),
          _pipelineStep(5, 'Action Routing',
              'Generate playbooks and automatically sync template checkboxes.', Icons.assessment_outlined,
              context.error),
        ],
      ),
    );
  }

  Widget _pipelineStep(int step, String title, String desc, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$step',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ),
            if (step < 5)
              Container(
                width: 2,
                height: 36,
                color: context.border,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Icon(icon, size: 18, color: color.withOpacity(0.4)),
        ),
      ],
    );
  }

  Widget _buildApiDocCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.integration_instructions_outlined, size: 20, color: context.accent),
              const SizedBox(width: 8),
              Text(
                'REST API Registry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _apiEndpoint('GET', '/health', 'System health check and loaded weights.'),
          _apiEndpoint('POST', '/predict', 'Calculate risk and action for a single client.'),
          _apiEndpoint('POST', '/predict_batch', 'Bulk cohort uploads via standard CSV.'),
          _apiEndpoint('GET', '/metrics', 'CatBoost metrics, accuracy scores, and logs.'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.link_outlined, size: 16, color: context.textSecondary),
                const SizedBox(width: 10),
                Text(
                  'Documentation Docs: http://localhost:8000/docs',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _apiEndpoint(String method, String path, String desc) {
    final methodColor =
        method == 'GET' ? context.success : context.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 54,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: methodColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              method,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: methodColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            path,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
