import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/prediction.dart';
import '../providers/prediction_provider.dart';
import '../utils/constants.dart';
import '../utils/file_exporter.dart';
import '../widgets/prediction_card.dart';

/// ── Dashboard Screen ───────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 0;
  int _rowsPerPage = 5;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<PredictionProvider>(context, listen: false);
      provider.checkApiHealth();
      provider.loadMetrics();
      provider.loadHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PredictionProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(provider),
              const SizedBox(height: 28),
              
              // Key Status Panels
              _buildStatusCards(provider),
              const SizedBox(height: 24),
              
              // Mitigation playbook recommendations summary
              _buildActionSummary(provider),
              const SizedBox(height: 24),
              
              // Charts & Log list
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 860) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildRiskDistribution(provider)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildRecentHistory(provider)),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _buildRiskDistribution(provider),
                      const SizedBox(height: 20),
                      _buildRecentHistory(provider),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildHistoryManagement(provider),
              const SizedBox(height: 24),
              
              // Model specifications
              _buildModelInfo(provider),
            ],
          ),
        );
      },
    );
  }

  void _downloadCSV(List<PredictionResult> history) {
    if (history.isEmpty) return;
    
    final header = "Customer ID,Churn Probability,Risk Tier,Sentiment,Action,Timestamp\n";
    final rows = history.map((r) => "${r.customerId},${r.churnProbability},${r.riskTier},${r.sentimentLabel},\"${r.recommendedAction}\",${r.timestamp ?? ''}").join("\n");
    
    exportCsvToBrowser('churn_history.csv', header + rows);
  }

  Widget _buildHeader(PredictionProvider provider) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.analytics_outlined,
              color: context.primary, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Retention Operations Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Live overview of customer sentiment, classification distribution, and active playbooks.',
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {
            provider.checkApiHealth();
            provider.loadMetrics();
            provider.loadHistory();
          },
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Refresh'),
          style: OutlinedButton.styleFrom(
            foregroundColor: context.textPrimary,
            side: BorderSide(color: context.border),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: provider.history.isEmpty ? null : () => _downloadCSV(provider.history),
          icon: const Icon(Icons.download, size: 16),
          label: const Text('Export History'),
          style: FilledButton.styleFrom(
            backgroundColor: context.primary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCards(PredictionProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final cardWidth = isWide ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _statusCard(
              'Prediction Engine',
              provider.isApiConnected ? 'ONLINE' : 'OFFLINE',
              provider.isApiConnected ? Icons.cloud_done : Icons.cloud_off,
              provider.isApiConnected ? context.success : context.error,
              cardWidth,
            ),
            _statusCard(
              'Database Records Scored',
              provider.history.length.toString(),
              Icons.analytics_outlined,
              context.primary,
              cardWidth,
            ),
            _statusCard(
              'Model Architecture',
              provider.metrics?.model ?? 'CatBoost v1.2',
              Icons.psychology_outlined,
              context.accent,
              cardWidth,
            ),
          ],
        );
      },
    );
  }

  Map<String, int> _buildDashboardActionCounts(PredictionProvider provider) {
    final counts = <String, int>{};
    for (final result in provider.history) {
      final action = result.recommendedAction.trim().isEmpty
          ? 'No recommendation'
          : result.recommendedAction.trim();
      counts[action] = (counts[action] ?? 0) + 1;
    }
    return counts;
  }

  List<MapEntry<String, int>> _topDashboardActions(PredictionProvider provider,
      [int limit = 3]) {
    final counts = _buildDashboardActionCounts(provider);
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  Widget _buildActionSummary(PredictionProvider provider) {
    final actionCounts = _buildDashboardActionCounts(provider);
    final topActions = _topDashboardActions(provider);
    final averageRisk = provider.history.isNotEmpty
        ? provider.history
                .map((r) => r.churnProbability)
                .reduce((a, b) => a + b) /
            provider.history.length
        : 0.0;
    
    // Aggregate sentiments
    int positive = 0;
    int negative = 0;
    int neutral = 0;
    for (final r in provider.history) {
      final s = r.sentimentLabel.toLowerCase();
      if (s.contains('pos')) {
        positive++;
      } else if (s.contains('neg')) {
        negative++;
      } else {
        neutral++;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.playlist_add_check_circle_outlined, size: 20, color: context.primary),
              const SizedBox(width: 8),
              Text(
                'Aggregated Executive Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Horizontal summary cards
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _summaryPill(
                title: 'Cohort Risk Avg',
                value: '${(averageRisk * 100).toStringAsFixed(1)}%',
                icon: Icons.speed_outlined,
                color: context.warning,
              ),
              _summaryPill(
                title: 'Active Playbooks',
                value: actionCounts.length.toString(),
                icon: Icons.assignment_outlined,
                color: context.primary,
              ),
              _summaryPill(
                title: 'Sentiment Balance',
                value: '$positive😊 / $neutral😐 / $negative😤',
                icon: Icons.face_outlined,
                color: context.accent,
              ),
            ],
          ),
          
          if (topActions.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Most Triggered Mitigation Procedures',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: topActions.map((entry) {
                final percentage = entry.value / provider.history.length;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: context.isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${entry.value} cases',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: context.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage,
                                minHeight: 4,
                                backgroundColor: context.border.withOpacity(0.4),
                                valueColor: AlwaysStoppedAnimation<Color>(context.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryPill({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusCard(
      String label, String value, IconData icon, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskDistribution(PredictionProvider provider) {
    final history = provider.history;
    final high = history.where((r) => r.riskTier == 'HIGH').length;
    final medium = history.where((r) => r.riskTier == 'MEDIUM').length;
    final low = history.where((r) => r.riskTier == 'LOW').length;
    final total = history.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline, size: 20, color: context.primary),
              const SizedBox(width: 8),
              Text(
                'Risk Allocation Distribution',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (total == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 36, color: context.textTertiary),
                    const SizedBox(height: 12),
                    Text(
                      'No calculations recorded yet.',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: high.toDouble(),
                            color: context.error,
                            title: high > 0 ? '$high' : '',
                            titleStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            radius: 46,
                          ),
                          PieChartSectionData(
                            value: medium.toDouble(),
                            color: context.warning,
                            title: medium > 0 ? '$medium' : '',
                            titleStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            radius: 46,
                          ),
                          PieChartSectionData(
                            value: low.toDouble(),
                            color: context.success,
                            title: low > 0 ? '$low' : '',
                            titleStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            radius: 46,
                          ),
                        ],
                        sectionsSpace: 3,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _legendItem('Critical Risk', high, total, context.error),
                      const SizedBox(height: 8),
                      _legendItem('Moderate Risk', medium, total, context.warning),
                      const SizedBox(height: 8),
                      _legendItem('Low/Healthy', low, total, context.success),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, int count, int total, Color color) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0';
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ($pct%)',
          style: TextStyle(
            fontSize: 12,
            color: context.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentHistory(PredictionProvider provider) {
    final history = provider.history.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_toggle_off_outlined, size: 20, color: context.primary),
              const SizedBox(width: 8),
              Text(
                'Recent Evaluation Activity',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimary,
                ),
              ),
              const Spacer(),
              if (history.isNotEmpty)
                TextButton(
                  onPressed: () {
                    provider.clearHistory();
                  },
                  child: const Text(
                    'Clear Logs',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (history.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.storage_outlined, size: 36, color: context.textTertiary),
                    const SizedBox(height: 12),
                    Text(
                      'No calculations logged.',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...history.map((r) => _historyItem(r)),
        ],
      ),
    );
  }

  Widget _historyItem(PredictionResult result) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.border),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: context.riskColor(result.riskTier),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                result.customerId,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              result.probabilityPercent,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: context.riskColor(result.riskTier),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: context.riskColor(result.riskTier).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                result.riskTier,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: context.riskColor(result.riskTier),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelInfo(PredictionProvider provider) {
    final metrics = provider.metrics;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terminal_outlined, size: 20, color: context.primary),
              const SizedBox(width: 8),
              Text(
                'Prediction Engine Specification & Metadata',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (metrics == null)
            Text(
              'Connecting to prediction engine...',
              style: TextStyle(color: context.textSecondary, fontSize: 13),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _infoChip('Classification Model', metrics.model),
                _infoChip('NLP Sentiment Tagging', metrics.nlpEngine),
                _infoChip('ROC-AUC Score', metrics.rocAucDisplay),
                _infoChip('Input Parameters', '${metrics.totalFeatures} dimensions'),
                _infoChip('Release Version', metrics.version),
              ],
            ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: context.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryManagement(PredictionProvider provider) {
    final allHistory = provider.history;
    final filtered = allHistory.where((item) {
      final query = _searchQuery.toLowerCase();
      return item.customerId.toLowerCase().contains(query) ||
          item.recommendedAction.toLowerCase().contains(query) ||
          item.riskTier.toLowerCase().contains(query);
    }).toList();

    final totalItems = filtered.length;
    final maxPages = (totalItems / _rowsPerPage).ceil();
    if (_currentPage >= maxPages && _currentPage > 0) {
      _currentPage = maxPages - 1;
    }
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage) > totalItems
        ? totalItems
        : (startIndex + _rowsPerPage);
    final paginatedItems = totalItems > 0
        ? filtered.sublist(startIndex, endIndex)
        : <PredictionResult>[];

    return Container(
      width: double.infinity,
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
              Icon(Icons.history_edu_outlined, size: 20, color: context.primary),
              const SizedBox(width: 8),
              Text(
                'Prediction History Database Workspace',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: provider.isLoading || allHistory.isEmpty
                    ? null
                    : () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: context.background,
                            title: const Text('Delete Duplicate Entries?'),
                            content: const Text(
                                'This will scan all history and keep only the latest prediction for each unique Customer ID.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete Duplicates'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await provider.deleteDuplicates();
                          setState(() {
                            _selectedIds.clear();
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Duplicates successfully cleared!'),
                                backgroundColor: context.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                icon: const Icon(Icons.cleaning_services_outlined, size: 14),
                label: const Text('Remove Duplicates'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.warning,
                  side: BorderSide(color: context.warning.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: provider.isLoading || allHistory.isEmpty
                    ? null
                    : () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: context.background,
                            title: const Text('Clear Entire History?'),
                            content: const Text(
                                'This will delete ALL database logs permanently. This cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: context.error,
                                ),
                                child: const Text('Clear All'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          final allDbIds = allHistory.map((e) => e.id).whereType<int>().toList();
                          if (allDbIds.isNotEmpty) {
                            await provider.deleteHistoryBatch(allDbIds);
                          } else {
                            provider.clearHistory();
                          }
                          setState(() {
                            _selectedIds.clear();
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('History cleared successfully!'),
                                backgroundColor: context.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                icon: const Icon(Icons.delete_sweep_outlined, size: 14),
                label: const Text('Clear All'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.error,
                  side: BorderSide(color: context.error.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Customer ID, risk level, playbook...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.border),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                      _currentPage = 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 14),
              AnimatedOpacity(
                opacity: _selectedIds.isNotEmpty ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: FilledButton.icon(
                  onPressed: _selectedIds.isEmpty || provider.isLoading
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: context.background,
                              title: const Text('Delete Selected Records?'),
                              content: Text(
                                  'Are you sure you want to delete the ${_selectedIds.length} selected prediction logs?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: context.error,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await provider.deleteHistoryBatch(_selectedIds.toList());
                            setState(() {
                              _selectedIds.clear();
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Selected items deleted!'),
                                  backgroundColor: context.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text('Delete Selected (${_selectedIds.length})'),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.error,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.folder_off_outlined, size: 40, color: context.textTertiary),
                    const SizedBox(height: 12),
                    Text(
                      'No matching records found.',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    context.isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                  ),
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                    fontSize: 12,
                  ),
                  dataTextStyle: TextStyle(
                    color: context.textSecondary,
                    fontSize: 12,
                  ),
                  columns: [
                    DataColumn(
                      label: Row(
                        children: [
                          Checkbox(
                            value: paginatedItems.every((item) => item.id != null && _selectedIds.contains(item.id)),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  for (final item in paginatedItems) {
                                    if (item.id != null) _selectedIds.add(item.id!);
                                  }
                                } else {
                                  for (final item in paginatedItems) {
                                    if (item.id != null) _selectedIds.remove(item.id);
                                  }
                                }
                              });
                            },
                          ),
                          const Text('Select'),
                        ],
                      ),
                    ),
                    const DataColumn(label: Text('Customer ID')),
                    const DataColumn(label: Text('Risk Prob')),
                    const DataColumn(label: Text('Risk Tier')),
                    const DataColumn(label: Text('Sentiment')),
                    const DataColumn(label: Text('Mitigation Recommendation')),
                    const DataColumn(label: Text('Workspace')),
                  ],
                  rows: paginatedItems.map((r) {
                    final isSelected = r.id != null && _selectedIds.contains(r.id);
                    return DataRow(
                      selected: isSelected,
                      cells: [
                        DataCell(
                          Checkbox(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (r.id != null) {
                                  if (val == true) {
                                    _selectedIds.add(r.id!);
                                  } else {
                                    _selectedIds.remove(r.id);
                                  }
                                }
                              });
                            },
                          ),
                        ),
                        DataCell(Text(r.customerId, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(r.probabilityPercent,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: context.riskColor(r.riskTier),
                            ))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.riskColor(r.riskTier).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${r.riskIcon} ${r.riskTier}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: context.riskColor(r.riskTier),
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(
                          '${r.sentimentIcon} ${r.sentimentLabel}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        )),
                        DataCell(
                          SizedBox(
                            width: 250,
                            child: Text(
                              r.recommendedAction,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          IconButton(
                            icon: Icon(Icons.analytics_outlined, size: 18, color: context.primary),
                            onPressed: () => _showDetailDialog(r),
                            tooltip: 'Review Playbook',
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Showing ${startIndex + 1}-$endIndex of $totalItems entries',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textTertiary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Rows per page: ',
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
                DropdownButton<int>(
                  value: _rowsPerPage,
                  items: [5, 10, 20, 50].map((int val) {
                    return DropdownMenuItem<int>(
                      value: val,
                      child: Text('$val', style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _rowsPerPage = val;
                        _currentPage = 0;
                      });
                    }
                  },
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 0
                      ? () {
                          setState(() {
                            _currentPage--;
                          });
                        }
                      : null,
                ),
                Text(
                  'Page ${_currentPage + 1} of ${maxPages == 0 ? 1 : maxPages}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < maxPages - 1
                      ? () {
                          setState(() {
                            _currentPage++;
                          });
                        }
                      : null,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showDetailDialog(PredictionResult result) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: context.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Playbook Workspace: ${result.customerId}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: context.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PredictionCard(result: result),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
