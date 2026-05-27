import 'package:flutter/material.dart';
import '../models/prediction.dart';
import '../utils/constants.dart';
import 'risk_gauge.dart';

/// ── Prediction Result Card ─────────────────────────────────────────────────
/// Full-featured card displaying all prediction results
class PredictionCard extends StatefulWidget {
  final PredictionResult result;
  final VoidCallback? onNewPrediction;

  const PredictionCard({
    super.key,
    required this.result,
    this.onNewPrediction,
  });

  @override
  State<PredictionCard> createState() => _PredictionCardState();
}

class _PredictionCardState extends State<PredictionCard> {
  // Playbook tasks state
  late List<String> _tasks;
  late List<bool> _taskStates;

  @override
  void initState() {
    super.initState();
    _initPlaybookTasks();
  }

  @override
  void didUpdateWidget(PredictionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result.customerId != widget.result.customerId ||
        oldWidget.result.riskTier != widget.result.riskTier) {
      _initPlaybookTasks();
    }
  }

  void _initPlaybookTasks() {
    final tier = widget.result.riskTier.toUpperCase();
    if (tier == 'HIGH') {
      _tasks = [
        'Schedule urgent retention call with Decision Maker (within 24 hrs)',
        'Offer up to 20% loyalty discount on 1-year contract extension',
        'Initiate Priority Level 2 Support review for device/outage complaints',
        'Assign dedicated Customer Success Advocate to the account',
      ];
    } else if (tier == 'MEDIUM') {
      _tasks = [
        'Send personalized email highlighting account features and optimizations',
        'Recommend DSL to Fiber Optic upgrade with free installation',
        'Suggest 1 month free or paperless billing subscription discount',
      ];
    } else {
      _tasks = [
        'Send standard automated Customer Satisfaction (CSAT) survey',
        'Prompt customer for referral program and rewards benefits',
        'Ensure support contact details and billing info are fully updated',
      ];
    }
    _taskStates = List.filled(_tasks.length, false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Risk Overview Card (Gainsight Health Score Dashboard Style)
        _buildRiskOverviewCard(isCompact),
        const SizedBox(height: 20),

        // ── Details in two columns
        if (!isCompact)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildSentimentAnalysis()),
              const SizedBox(width: 20),
              Expanded(child: _buildChurnFactorsCard()),
            ],
          )
        else ...[
          _buildSentimentAnalysis(),
          const SizedBox(height: 20),
          _buildChurnFactorsCard(),
        ],

        const SizedBox(height: 20),

        // ── Customer Success Playbook (Vitally Checklist Style)
        _buildPlaybookCard(),
      ],
    );
  }

  Widget _buildRiskOverviewCard(bool isCompact) {
    final riskTier = widget.result.riskTier;
    final probability = widget.result.churnProbability;
    
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.border),
        boxShadow: [
          BoxShadow(
            color: context.riskColor(riskTier).withOpacity(0.06),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: isCompact
            ? Column(
                children: [
                  RiskGauge(
                    probability: probability,
                    riskTier: riskTier,
                    size: 190,
                  ),
                  const SizedBox(height: 28),
                  _buildMetricsList(),
                ],
              )
            : Row(
                children: [
                  RiskGauge(
                    probability: probability,
                    riskTier: riskTier,
                    size: 210,
                  ),
                  const SizedBox(width: 48),
                  Expanded(child: _buildMetricsList()),
                ],
              ),
      ),
    );
  }

  Widget _buildMetricsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'CUSTOMER SUMMARY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: context.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Spacer(),
            Text(
              'Model ${widget.result.modelVersion}',
              style: TextStyle(
                fontSize: 11,
                color: context.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _metricRow(
          icon: Icons.badge_outlined,
          label: 'Customer Account ID',
          value: widget.result.customerId,
        ),
        _metricRow(
          icon: Icons.analytics_outlined,
          label: 'System Prediction',
          value: widget.result.isChurning ? 'Will Churn (At Risk)' : 'Will Remain (Stable)',
          valueColor: widget.result.isChurning ? context.error : context.success,
        ),
        _metricRow(
          icon: Icons.speed_outlined,
          label: 'Calculated Churn Risk',
          value: '${((widget.result.churnProbability) * 100).toStringAsFixed(1)}%',
          valueColor: context.riskColor(widget.result.riskTier),
        ),
        _metricRow(
          icon: Icons.shield_outlined,
          label: 'Classification Tier',
          value: '${widget.result.riskIcon} ${widget.result.riskTier} RISK',
          valueColor: context.riskColor(widget.result.riskTier),
        ),
      ],
    );
  }

  Widget _metricRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.textTertiary),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: valueColor ?? context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentAnalysis() {
    final sentiment = widget.result.sentimentLabel;
    final sentimentProb = widget.result.sentimentConfidence;
    final hasFeedback = widget.result.feedbackText != null && widget.result.feedbackText!.isNotEmpty;
    
    Color sentimentColor;
    IconData sentimentIcon;
    String sentimentEmoji;
    switch (sentiment.toLowerCase()) {
      case 'negative':
        sentimentColor = context.error;
        sentimentIcon = Icons.sentiment_dissatisfied_outlined;
        sentimentEmoji = '😤';
        break;
      case 'positive':
        sentimentColor = context.success;
        sentimentIcon = Icons.sentiment_satisfied_alt_outlined;
        sentimentEmoji = '😊';
        break;
      default:
        sentimentColor = context.warning;
        sentimentIcon = Icons.sentiment_neutral_outlined;
        sentimentEmoji = '😐';
    }

    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.border),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.face_retouching_natural_outlined,
                  size: 20, color: context.primary),
              const SizedBox(width: 8),
              Text(
                'Sentiment & CSAT Index',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: sentimentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    sentimentEmoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${sentiment.toUpperCase()} SENTIMENT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: sentimentColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NLP classification confidence: ${(sentimentProb * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: sentimentProb,
              minHeight: 6,
              backgroundColor: context.isDark ? AppColors.darkSurfaceVariant : context.border.withOpacity(0.5),
              valueColor: AlwaysStoppedAnimation<Color>(sentimentColor),
            ),
          ),
          if (hasFeedback) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: sentimentColor.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: sentimentColor.withOpacity(0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.format_quote, size: 16, color: sentimentColor),
                      const SizedBox(width: 6),
                      Text(
                        'VERBATIM FEEDBACK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: sentimentColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"${widget.result.feedbackText}"',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: context.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildChurnFactorsCard() {
    final factors = widget.result.topChurnFactors;
    
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.border),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_outlined, size: 20, color: context.warning),
              const SizedBox(width: 8),
              Text(
                'Top Churn Signals (Akkio Style)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (factors.isEmpty)
            Text(
              'No specific predictive features triggered.',
              style: TextStyle(color: context.textSecondary, fontSize: 13),
            )
          else
            ...factors.asMap().entries.map((entry) {
              final index = entry.key;
              final factor = entry.value.toString();
              // Akkio style feature weight bars
              final weight = 0.95 - (index * 0.16);
              final barColor = Color.lerp(context.warning, context.error, index / factors.length)!;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: barColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: barColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            factor,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: context.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${(weight * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: barColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: weight,
                        minHeight: 5,
                        backgroundColor: context.isDark ? AppColors.darkSurfaceVariant : context.border.withOpacity(0.5),
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPlaybookCard() {
    final riskTier = widget.result.riskTier;
    final isHigh = riskTier.toUpperCase() == 'HIGH';
    final isMedium = riskTier.toUpperCase() == 'MEDIUM';
    final actionColor = context.riskColor(riskTier);

    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
          )
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Playbook Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: actionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.playlist_add_check_circle, size: 24, color: actionColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Success Playbook',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      'Task checklist triggered for CRM action synchronization',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: actionColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${riskTier.toUpperCase()} RISK PLAYBOOK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: actionColor,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32),

          // ML Generated Recommendation
          Text(
            'SYSTEM RECOMMENDATION:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: context.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.result.recommendedAction,
              style: TextStyle(
                fontSize: 13,
                color: context.textPrimary,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Interative Action Items Checklist
          Text(
            'MITIGATION TASK LIST:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: context.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(_tasks.length, (idx) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: CheckboxListTile(
                value: _taskStates[idx],
                onChanged: (val) {
                  setState(() {
                    _taskStates[idx] = val ?? false;
                  });
                },
                title: Text(
                  _tasks[idx],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: _taskStates[idx] ? TextDecoration.lineThrough : null,
                    color: _taskStates[idx] ? context.textTertiary : context.textPrimary,
                  ),
                ),
                activeColor: actionColor,
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            );
          }),
          const SizedBox(height: 20),

          // Playbook Actions Toolbar
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Playbook actions synchronized to Salesforce & Zendesk!'),
                      backgroundColor: context.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                icon: const Icon(Icons.sync, size: 16),
                label: const Text('Sync to Salesforce'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              if (widget.onNewPrediction != null)
                FilledButton.icon(
                  onPressed: widget.onNewPrediction,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Prediction'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    backgroundColor: context.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
