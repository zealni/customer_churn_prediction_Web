import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../providers/prediction_provider.dart';
import '../utils/constants.dart';
import '../widgets/customer_form.dart';
import '../widgets/prediction_card.dart';

/// ── Single Prediction Screen ───────────────────────────────────────────────
class SinglePredictScreen extends StatefulWidget {
  const SinglePredictScreen({super.key});

  @override
  State<SinglePredictScreen> createState() => _SinglePredictScreenState();
}

class _SinglePredictScreenState extends State<SinglePredictScreen> {
  bool _showResults = false;

  void _handlePredict(Customer customer) async {
    final provider =
        Provider.of<PredictionProvider>(context, listen: false);
    final result = await provider.predictCustomer(customer);
    if (result != null && mounted) {
      setState(() => _showResults = true);
    }
  }

  void _handleNewPrediction() {
    final provider =
        Provider.of<PredictionProvider>(context, listen: false);
    provider.clearLastPrediction();
    setState(() => _showResults = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PredictionProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 24),

              // Error message
              if (provider.error != null) ...[
                _buildErrorBanner(provider.error!),
                const SizedBox(height: 16),
              ],

              // Results or Form
              if (_showResults && provider.lastPrediction != null)
                PredictionCard(
                  result: provider.lastPrediction!,
                  onNewPrediction: _handleNewPrediction,
                )
              else
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.border),
                  ),
                  child: CustomerForm(
                    isLoading: provider.isLoading,
                    onSubmit: _handlePredict,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.accent.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.person_search,
                  color: context.accent, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Single Customer Prediction',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Quickly score one customer and see churn probability, sentiment, and retention guidance.',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            if (_showResults)
              FilledButton.icon(
                onPressed: _handleNewPrediction,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('New Entry'),
                style: FilledButton.styleFrom(
                  backgroundColor: context.primary,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.errorSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.error.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.error_outline, color: context.error, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: context.error,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Provider.of<PredictionProvider>(context, listen: false)
                  .clearError();
            },
            icon: const Icon(Icons.close, size: 18),
            color: context.error,
          ),
        ],
      ),
    );
  }
}
