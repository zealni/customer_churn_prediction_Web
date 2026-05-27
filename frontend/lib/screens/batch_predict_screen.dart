import 'dart:convert';
import 'package:csv/csv.dart' as csvlib;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/prediction.dart';
import '../providers/prediction_provider.dart';
import '../utils/constants.dart';
import '../utils/file_exporter.dart';
import '../widgets/prediction_card.dart';

/// ── Batch Prediction Screen ────────────────────────────────────────────────
class BatchPredictScreen extends StatefulWidget {
  const BatchPredictScreen({super.key});

  @override
  State<BatchPredictScreen> createState() => _BatchPredictScreenState();
}

class _BatchPredictScreenState extends State<BatchPredictScreen> {
  List<Customer>? _parsedCustomers;
  String? _fileName;
  String? _parseError;
  String _sortColumn = 'customer_id';
  bool _sortAscending = true;
  String _filterTier = 'ALL';

  Future<void> _pickAndParseCsv() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        setState(() => _parseError = 'Could not read file');
        return;
      }

      final csvString = utf8.decode(file.bytes!);
      final rows = csvlib.csv.decode(csvString);

      if (rows.length < 2) {
        setState(() => _parseError = 'CSV must have header + at least 1 row');
        return;
      }

      final headers = rows.first.map((e) => e.toString().trim()).toList();
      final customers = <Customer>[];

      for (int i = 1; i < rows.length; i++) {
        if (rows[i].isEmpty ||
            rows[i].every((cell) => cell.toString().trim().isEmpty)) {
          continue;
        }

        final Map<String, dynamic> rowMap = {};
        for (int j = 0; j < headers.length && j < rows[i].length; j++) {
          var value = rows[i][j];
          if (value is String) {
            final num? parsed = num.tryParse(value);
            if (parsed != null) value = parsed;
          }
          rowMap[headers[j]] = value;
        }

        try {
          customers.add(Customer.fromJson(rowMap));
        } catch (e) {
          // Skip invalid rows
        }
      }

      if (customers.isEmpty) {
        setState(
            () => _parseError = 'No valid customers found in CSV');
        return;
      }

      setState(() {
        _parsedCustomers = customers;
        _fileName = file.name;
        _parseError = null;
      });
    } catch (e) {
      setState(() => _parseError = 'Error parsing CSV: $e');
    }
  }

  void _runBatchPrediction() async {
    if (_parsedCustomers == null || _parsedCustomers!.isEmpty) return;
    final provider =
        Provider.of<PredictionProvider>(context, listen: false);
    await provider.predictBatch(_parsedCustomers!);
  }

  void _exportResults(BatchPredictionResult batchResult) {
    final csv = StringBuffer();
    csv.writeln(
        'customer_id,churn_probability,churn_prediction,risk_tier,sentiment_label,sentiment_confidence,recommended_action');
    for (final r in batchResult.results) {
      csv.writeln(
          '${r.customerId},${r.churnProbability},${r.churnPrediction},${r.riskTier},${r.sentimentLabel},${r.sentimentConfidence},"${r.recommendedAction}"');
    }
    exportCsvToBrowser('batch_prediction_results.csv', csv.toString());
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('CSV results exported successfully!'),
        backgroundColor: context.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  List<PredictionResult> _getFilteredResults(
      BatchPredictionResult batchResult) {
    var results = batchResult.results.toList();

    // Filter
    if (_filterTier != 'ALL') {
      results =
          results.where((r) => r.riskTier == _filterTier).toList();
    }

    // Sort
    results.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case 'probability':
          cmp = a.churnProbability.compareTo(b.churnProbability);
          break;
        case 'risk_tier':
          final order = {'HIGH': 3, 'MEDIUM': 2, 'LOW': 1};
          cmp = (order[a.riskTier] ?? 0).compareTo(order[b.riskTier] ?? 0);
          break;
        case 'sentiment':
          cmp = a.sentimentLabel.compareTo(b.sentimentLabel);
          break;
        default:
          cmp = a.customerId.compareTo(b.customerId);
      }
      return _sortAscending ? cmp : -cmp;
    });

    return results;
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
              _buildHeader(),
              const SizedBox(height: 28),

              // Error banner
              if (provider.error != null || _parseError != null)
                _buildErrorBanner(provider.error ?? _parseError!),
              if (provider.error != null || _parseError != null)
                const SizedBox(height: 16),

              // Upload section
              if (provider.batchResult == null) ...[
                _buildUploadSection(),
                const SizedBox(height: 20),
                if (_parsedCustomers != null) _buildPreviewSection(provider),
              ],

              // Results
              if (provider.batchResult != null) ...[
                _buildSummaryCards(provider.batchResult!),
                const SizedBox(height: 24),
                _buildResultsTable(provider.batchResult!),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.file_present_outlined,
              color: context.primary, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Batch Prediction Engine',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Process bulk customer cohorts, evaluate risk percentages, and extract actionable checklists.',
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Consumer<PredictionProvider>(
          builder: (context, provider, _) {
            if (provider.batchResult != null) {
              return Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _exportResults(provider.batchResult!),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Export Results'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () {
                      provider.clearBatchResult();
                      setState(() {
                        _parsedCustomers = null;
                        _fileName = null;
                      });
                    },
                    icon: const Icon(Icons.autorenew, size: 16),
                    label: const Text('New Batch'),
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
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: context.border,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
          )
        ],
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: context.primary.withOpacity(0.35),
          radius: 20,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          width: double.infinity,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: (_fileName != null ? context.success : context.primary).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _fileName != null ? Icons.task_alt : Icons.upload_file_outlined,
                  size: 42,
                  color: _fileName != null ? context.success : context.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _fileName ?? 'Drag & drop or browse your CSV file',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _fileName != null
                    ? '${_parsedCustomers?.length ?? 0} customer records verified & loaded'
                    : 'Supported format: Standard CSV structure with tenure, monthly charges, and feedback text.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: context.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _pickAndParseCsv,
                icon: const Icon(Icons.file_open_outlined, size: 16),
                label: Text(_fileName != null ? 'Choose Different File' : 'Select CSV File'),
                style: FilledButton.styleFrom(
                  backgroundColor: context.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewSection(PredictionProvider provider) {
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
              Icon(Icons.visibility_outlined, size: 20, color: context.primary),
              const SizedBox(width: 10),
              Text(
                'Data Preview (Top 5 Rows)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: provider.isLoading ? null : _runBatchPrediction,
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_circle_outline, size: 16),
                label: Text(provider.isLoading ? 'Analyzing Cohort...' : 'Execute Analysis'),
                style: FilledButton.styleFrom(
                  backgroundColor: context.success,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
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
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                  fontSize: 12,
                ),
                dataTextStyle: TextStyle(
                  color: context.textSecondary,
                  fontSize: 12,
                ),
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Gender')),
                  DataColumn(label: Text('Tenure')),
                  DataColumn(label: Text('Contract')),
                  DataColumn(label: Text('Monthly')),
                  DataColumn(label: Text('Internet')),
                ],
                rows: _parsedCustomers!
                    .take(5)
                    .map(
                      (c) => DataRow(cells: [
                        DataCell(Text(c.customerID, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(c.gender)),
                        DataCell(Text('${c.tenure} months')),
                        DataCell(Text(c.contract)),
                        DataCell(Text('\$${c.monthlyCharges}')),
                        DataCell(Text(c.internetService)),
                      ]),
                    )
                    .toList(),
              ),
            ),
          ),
          if (_parsedCustomers!.length > 5) ...[
            const SizedBox(height: 10),
            Text(
              'Showing 5 of ${_parsedCustomers!.length} loaded rows',
              style: TextStyle(
                fontSize: 12,
                color: context.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, int> _buildActionCounts(BatchPredictionResult batchResult) {
    final counts = <String, int>{};
    for (final result in batchResult.results) {
      final action = result.recommendedAction.trim().isEmpty
          ? 'No recommendation'
          : result.recommendedAction.trim();
      counts[action] = (counts[action] ?? 0) + 1;
    }
    return counts;
  }

  List<MapEntry<String, int>> _topActions(BatchPredictionResult batchResult,
      [int limit = 3]) {
    final counts = _buildActionCounts(batchResult);
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  Widget _buildActionSummary(BatchPredictionResult batchResult) {
    final topActions = _topActions(batchResult);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Top Triggered Playbooks',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: context.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'AI categorizations based on active mitigation playbook recommendations.',
          style: TextStyle(
            fontSize: 12.5,
            color: context.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        if (topActions.isNotEmpty)
          Column(
            children: topActions.map((entry) {
              final percentage = entry.value / batchResult.totalPredictions;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${entry.value} cs',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: context.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
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
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSummaryCards(BatchPredictionResult batchResult) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final cardWidth = isWide
            ? (constraints.maxWidth - 36) / 4
            : constraints.maxWidth;

        return Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _summaryCard(
                  'Total Scored',
                  batchResult.totalPredictions.toString(),
                  Icons.people_outline,
                  context.primary,
                  cardWidth,
                ),
                _summaryCard(
                  'High Risk Escalations',
                  batchResult.highRiskCount.toString(),
                  Icons.warning_amber_rounded,
                  context.error,
                  cardWidth,
                ),
                _summaryCard(
                  'Medium Risk Reviews',
                  batchResult.mediumRiskCount.toString(),
                  Icons.info_outline,
                  context.warning,
                  cardWidth,
                ),
                _summaryCard(
                  'Low Risk Accounts',
                  batchResult.lowRiskCount.toString(),
                  Icons.check_circle_outline,
                  context.success,
                  cardWidth,
                ),
              ],
            ),
            _buildActionSummary(batchResult),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
      String label, String value, IconData icon, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
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

  Widget _buildResultsTable(BatchPredictionResult batchResult) {
    final filteredResults = _getFilteredResults(batchResult);

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
          // Filters
          Row(
            children: [
              Text(
                'Scored Customer Registry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const Spacer(),
              // Filter chips
              ...['ALL', 'HIGH', 'MEDIUM', 'LOW'].map((tier) {
                final isSelected = _filterTier == tier;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: FilterChip(
                    label: Text(tier, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _filterTier = tier);
                    },
                    selectedColor: tier == 'ALL'
                        ? context.primary.withOpacity(0.12)
                        : context.riskColor(tier).withOpacity(0.12),
                    checkmarkColor: tier == 'ALL'
                        ? context.primary
                        : context.riskColor(tier),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? (tier == 'ALL' ? context.primary : context.riskColor(tier))
                          : context.textSecondary,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? (tier == 'ALL' ? context.primary : context.riskColor(tier))
                          : context.border,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 20),
          // Table container
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
                sortColumnIndex: [
                  'customer_id',
                  'probability',
                  'risk_tier',
                  'sentiment'
                ].indexOf(_sortColumn),
                sortAscending: _sortAscending,
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
                    label: const Text('Customer ID'),
                    onSort: (_, asc) => setState(() {
                      _sortColumn = 'customer_id';
                      _sortAscending = asc;
                    }),
                  ),
                  DataColumn(
                    label: const Text('Risk Prob'),
                    numeric: true,
                    onSort: (_, asc) => setState(() {
                      _sortColumn = 'probability';
                      _sortAscending = asc;
                    }),
                  ),
                  DataColumn(
                    label: const Text('Risk Tier'),
                    onSort: (_, asc) => setState(() {
                      _sortColumn = 'risk_tier';
                      _sortAscending = asc;
                    }),
                  ),
                  DataColumn(
                    label: const Text('Sentiment'),
                    onSort: (_, asc) => setState(() {
                      _sortColumn = 'sentiment';
                      _sortAscending = asc;
                    }),
                  ),
                  const DataColumn(label: Text('Mitigation Recommendation')),
                  const DataColumn(label: Text('Action')),
                ],
                rows: filteredResults.map((r) {
                  return DataRow(cells: [
                    DataCell(Text(r.customerId,
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(r.probabilityPercent,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: context.riskColor(r.riskTier),
                        ))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
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
                        icon: Icon(Icons.analytics_outlined,
                            size: 18, color: context.primary),
                        onPressed: () => _showDetailDialog(r),
                        tooltip: 'Review Playbook',
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Showing ${filteredResults.length} of ${batchResult.totalPredictions} records',
                style: TextStyle(
                  fontSize: 12,
                  color: context.textTertiary,
                ),
              ),
            ],
          ),
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

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: context.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: context.error, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    // Dash algorithm
    const dashWidth = 8.0;
    const dashSpace = 5.0;
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = dashWidth;
        final nextDistance = distance + length;
        final extract = metric.extractPath(
          distance,
          nextDistance > metric.length ? metric.length : nextDistance,
        );
        canvas.drawPath(extract, paint);
        distance += length + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
