import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// ── Home Screen ────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  final void Function(int)? onNavigate;
  final VoidCallback? onSignIn;
  final VoidCallback? onSignUp;
  final bool isLoggedIn;

  const HomeScreen({
    super.key,
    this.onNavigate,
    this.onSignIn,
    this.onSignUp,
    required this.isLoggedIn,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _workflowKey = GlobalKey();
  final GlobalKey _pricingKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoggedIn) {
      return Scaffold(
        body: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPublicHeader(),
              _buildPublicHero(),
              const SizedBox(height: 48),
              _buildDashboardMockup(),
              const SizedBox(height: 64),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(key: _featuresKey, child: _buildHighlights()),
                    const SizedBox(height: 64),
                    Container(key: _workflowKey, child: _buildWorkflow()),
                    const SizedBox(height: 64),
                    _buildIntegrations(),
                    const SizedBox(height: 64),
                    Container(key: _pricingKey, child: _buildPricingTiers()),
                  ],
                ),
              ),
              const SizedBox(height: 64),
              _buildPublicFooter(),
            ],
          ),
        ),
      );
    }

    // Authenticated Home Dashboard
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(),
          const SizedBox(height: 32),
          _buildHighlights(),
          const SizedBox(height: 32),
          _buildWorkflow(),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF06152B), // very deep navy
                Color(0xFF0F3A75), // rich blue-navy
                Color(0xFF005CE6), // bright blue
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: context.primaryDark.withOpacity(0.25),
                blurRadius: 36,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00F2FE),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'AI ENGINE V2.4 ACTIVATED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Next-Gen Churn Prediction & Retention Playbooks',
                          style: TextStyle(
                            fontSize: isWide ? 46 : 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'An integrated customer health center combining CatBoost machine learning, NLP sentiment analysis, and automated retention actions. Inspired by the best-in-class architectures of Gainsight, Vitally, and ChurnZero.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            _heroActionButton(
                              icon: Icons.person_search_outlined,
                              label: 'Analyze Single Customer',
                              onTap: () => widget.onNavigate?.call(1),
                              backgroundColor: Colors.white,
                              foregroundColor: context.primary,
                            ),
                            _heroActionButton(
                              icon: Icons.upload_file_outlined,
                              label: 'Batch Cohort Scoring',
                              onTap: () => widget.onNavigate?.call(2),
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              borderColor: Colors.white.withOpacity(0.4),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isWide) const SizedBox(width: 32),
                  if (isWide)
                    Expanded(
                      flex: 4,
                      child: _heroMetricsPanel(),
                    ),
                ],
              ),
              const SizedBox(height: 36),
              _buildHeroHighlights(),
            ],
          ),
        );
      },
    );
  }

  Widget _heroActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color backgroundColor,
    required Color foregroundColor,
    Color? borderColor,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: borderColor == null
                ? null
                : Border.all(color: borderColor, width: 1.5),
            boxShadow: backgroundColor == Colors.white
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: foregroundColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroMetricsPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard_customize_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                'RETENTION METRICS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _heroMetricCard(
            icon: Icons.speed_outlined,
            title: '99.98% Model ROC-AUC',
            subtitle: 'CatBoost accuracy verifying data signals.',
            color: Colors.white,
            background: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 12),
          _heroMetricCard(
            icon: Icons.offline_bolt_outlined,
            title: 'Actionable Playbooks',
            subtitle: 'Instant mitigation guides per customer.',
            color: Colors.white,
            background: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 12),
          _heroMetricCard(
            icon: Icons.psychology_outlined,
            title: 'NLP Sentiment Tagging',
            subtitle: 'Sentence embeddings track customer voice.',
            color: Colors.white,
            background: Colors.white.withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  Widget _heroMetricCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
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
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.75),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHighlights() {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 800;
      if (!isWide) return const SizedBox.shrink();
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _highlightChip(
            icon: Icons.bolt,
            title: 'Gainsight & Vitally Framework',
            subtitle: 'Customer health scorecard architecture',
          ),
          const SizedBox(width: 14),
          _highlightChip(
            icon: Icons.sentiment_satisfied_alt,
            title: 'Hotjar Feedback Analyzer',
            subtitle: 'Emotional mapping and feedback CSAT tagging',
          ),
          const SizedBox(width: 14),
          _highlightChip(
            icon: Icons.bar_chart_outlined,
            title: 'Akkio-Style Diagnostics',
            subtitle: 'Interactive feature explanations per prediction',
          ),
        ],
      );
    });
  }

  Widget _highlightChip({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlights() {
    final features = [
      {
        'icon': Icons.insights_outlined,
        'title': 'Gainsight Churn Analytics',
        'subtitle': 'Robust tracking of customer segments, billing histories, and activity tiers.',
      },
      {
        'icon': Icons.psychology_outlined,
        'title': 'Akkio-Style ML Metrics',
        'subtitle': 'Deep classification using boosted trees, providing probability outputs.',
      },
      {
        'icon': Icons.emoji_emotions_outlined,
        'title': 'Hotjar Sentiment Scoring',
        'subtitle': 'Understands complaints and reviews, indexing satisfaction into emoji indicators.',
      },
      {
        'icon': Icons.playlist_add_check_circle_outlined,
        'title': 'Vitally Playbooks',
        'subtitle': 'Automates tasks and checklists. Turn alerts directly into resolutions.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feature Suites Inspired by Leaders',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: context.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 950;
            
            final cardsGrid = Wrap(
              spacing: 16,
              runSpacing: 16,
              children: features.map((item) {
                return SizedBox(
                  width: isWide
                      ? (constraints.maxWidth * 0.58 - 16) / 2
                      : (constraints.maxWidth > 600 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: context.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: context.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );

            final illustration = Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.border.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(context.isDark ? 0.05 : 0.01),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/analytics_features.png',
                  fit: BoxFit.contain,
                  height: 320,
                ),
              ),
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 12, child: cardsGrid),
                  const SizedBox(width: 32),
                  Expanded(flex: 8, child: illustration),
                ],
              );
            } else {
              return Column(
                children: [
                  cardsGrid,
                  const SizedBox(height: 32),
                  illustration,
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildWorkflow() {
    final steps = [
      {
        'step': '1',
        'title': 'Ingest Customer Signal',
        'subtitle': 'Upload a database CSV file or insert custom parameters to trigger classification.',
      },
      {
        'step': '2',
        'title': 'Execute Diagnostics',
        'subtitle': 'Understand exact feature contributions, probability scores, and sentence sentiments.',
      },
      {
        'step': '3',
        'title': 'Deploy Action Playbook',
        'subtitle': 'Instantly activate tailored checklist tasks in Zendesk, HubSpot, and Salesforce.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Workflow Architecture',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: context.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 950;
            
            final stepsList = Column(
              children: steps.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: context.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              item['step'] as String,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: context.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['subtitle'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.textSecondary,
                                  height: 1.5,
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
            );

            final illustration = Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.border.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(context.isDark ? 0.05 : 0.01),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/retention_workflow.png',
                  fit: BoxFit.contain,
                  height: 320,
                ),
              ),
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 8, child: illustration),
                  const SizedBox(width: 32),
                  Expanded(flex: 12, child: stepsList),
                ],
              );
            } else {
              return Column(
                children: [
                  illustration,
                  const SizedBox(height: 32),
                  stepsList,
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildIntegrations() {
    final tools = [
      {
        'icon': Icons.notifications_active_outlined,
        'title': 'Instant Slack & Teams Alerting',
        'subtitle': 'Send automated warning payloads to your channel when a high-value account falls into critical risk tiers.',
      },
      {
        'icon': Icons.sync_alt_outlined,
        'title': 'Bi-Directional CRM Sync',
        'subtitle': 'Create and assign high-priority follow-up tasks directly in Salesforce, HubSpot, or Dynamics 365.',
      },
      {
        'icon': Icons.contact_mail_outlined,
        'title': 'Automated Outreach Campaigns',
        'subtitle': 'Instantly trigger personalized survey emails to gather direct customer feedback and mitigate issues early.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enterprise Integration & Playbooks',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: context.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 950;
            
            final toolsList = Column(
              children: tools.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: context.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: context.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['subtitle'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.textSecondary,
                                  height: 1.5,
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
            );

            final illustration = Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.border.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(context.isDark ? 0.05 : 0.01),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/integration_playbooks.png',
                  fit: BoxFit.contain,
                  height: 320,
                ),
              ),
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 12, child: toolsList),
                  const SizedBox(width: 32),
                  Expanded(flex: 8, child: illustration),
                ],
              );
            } else {
              return Column(
                children: [
                  toolsList,
                  const SizedBox(height: 32),
                  illustration,
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildPublicHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: context.surface.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: context.border, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: context.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.analytics, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Churn Intelligence',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: context.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          if (MediaQuery.of(context).size.width > 900) ...[
            _headerLink('Features', () => _scrollTo(_featuresKey)),
            const SizedBox(width: 24),
            _headerLink('How It Works', () => _scrollTo(_workflowKey)),
            const SizedBox(width: 24),
            _headerLink('Pricing', () => _scrollTo(_pricingKey)),
            const SizedBox(width: 32),
          ],

          OutlinedButton(
            onPressed: widget.onSignIn,
            style: OutlinedButton.styleFrom(
              foregroundColor: context.textPrimary,
              side: BorderSide(color: context.border),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: widget.onSignUp,
            style: FilledButton.styleFrom(
              backgroundColor: context.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Get Started',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerLink(String text, VoidCallback onTap) {
    return HeaderLinkWidget(text: text, onTap: onTap);
  }

  Widget _buildPublicHero() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 950;
        
        final textContent = Column(
          crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: context.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.primary.withOpacity(0.12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: context.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI CUSTOMER RETENTION PLATFORM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: context.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Stop Customer Churn Before It Happens',
              textAlign: isWide ? TextAlign.left : TextAlign.center,
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: context.textPrimary,
                height: 1.15,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Empower your customer success managers with advanced CatBoost predictive analytics and NLP sentiment diagnostic scoring. Synthesize feedback and billing data to trigger mitigation playbooks in real-time.',
              textAlign: isWide ? TextAlign.left : TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: context.textSecondary,
                height: 1.65,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: isWide ? WrapAlignment.start : WrapAlignment.center,
              children: [
                _heroActionButton(
                  icon: Icons.rocket_launch,
                  label: 'Start Free 14-Day Trial',
                  onTap: () => widget.onSignUp?.call(),
                  backgroundColor: context.primary,
                  foregroundColor: Colors.white,
                ),
                _heroActionButton(
                  icon: Icons.play_circle_outline,
                  label: 'Watch Platform Walkthrough',
                  onTap: () => _scrollTo(_featuresKey),
                  backgroundColor: Colors.transparent,
                  foregroundColor: context.primary,
                  borderColor: context.primary.withOpacity(0.3),
                ),
              ],
            ),
          ],
        );

        final illustration = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/retention_hero.png',
              fit: BoxFit.contain,
              height: isWide ? 380 : 260,
            ),
          ),
        );

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(left: 32, right: 32, top: 32),
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 56),
          decoration: BoxDecoration(
            gradient: context.heroGradient,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: context.border.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: isWide
              ? Row(
                  children: [
                    Expanded(flex: 11, child: textContent),
                    const SizedBox(width: 48),
                    Expanded(flex: 9, child: illustration),
                  ],
                )
              : Column(
                  children: [
                    textContent,
                    const SizedBox(height: 48),
                    illustration,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildDashboardMockup() {
    final isDark = context.isDark;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        constraints: const BoxConstraints(maxWidth: 1000),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.border, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            children: [
              Container(
                height: 50,
                color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(width: 24),
                    const Icon(Icons.shield_outlined, size: 14, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      'app.churnintelligence.com/workspace',
                      style: TextStyle(fontSize: 11, color: context.textTertiary),
                    ),
                    const Spacer(),
                    const Icon(Icons.notifications_none, size: 16),
                    const SizedBox(width: 14),
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: context.primary.withOpacity(0.2),
                      child: Icon(Icons.person, size: 10, color: context.primary),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: context.border),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 480,
                    color: isDark ? Colors.white.withOpacity(0.01) : Colors.black.withOpacity(0.005),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        _mockSidebarIcon(Icons.dashboard, isSelected: true),
                        _mockSidebarIcon(Icons.person_search_outlined),
                        _mockSidebarIcon(Icons.group_work_outlined),
                        _mockSidebarIcon(Icons.history_outlined),
                        _mockSidebarIcon(Icons.settings_outlined),
                      ],
                    ),
                  ),
                  VerticalDivider(width: 1, color: context.border),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Workspace Overview',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'ML diagnostic score active.',
                                    style: TextStyle(fontSize: 11, color: context.textSecondary),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: context.successSurface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Container(width: 6, height: 6, decoration: BoxDecoration(color: context.success, shape: BoxShape.circle)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'API Online',
                                      style: TextStyle(fontSize: 10, color: context.success, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: _mockStatCard('Risk Account Ratio', '14.2%', Colors.orange, Icons.trending_up)),
                              const SizedBox(width: 14),
                              Expanded(child: _mockStatCard('Sentiment Score', '8.4 / 10', const Color(0xFF10B981), Icons.sentiment_satisfied)),
                              const SizedBox(width: 14),
                              Expanded(child: _mockStatCard('ML Confidence', '99.8%', Colors.blue, Icons.psychology)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: context.surfaceVariant.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: context.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Diagnostic: Acme Corp',
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text('High Risk', style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Text('Probability:', style: TextStyle(fontSize: 10, color: context.textSecondary)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Stack(
                                              children: [
                                                Container(height: 8, decoration: BoxDecoration(color: context.border, borderRadius: BorderRadius.circular(4))),
                                                FractionallySizedBox(
                                                  widthFactor: 0.82,
                                                  child: Container(
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      gradient: const LinearGradient(colors: [Colors.orange, Colors.red]),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('82%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.textPrimary)),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      _mockChecklistItem('Verify monthly usage drop of -25%', checked: true),
                                      _mockChecklistItem('Schedule account sync before Q3 review', checked: true),
                                      _mockChecklistItem('Propose 15% pricing discount package', checked: false),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: context.surfaceVariant.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: context.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Feature Importance',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary),
                                      ),
                                      const SizedBox(height: 14),
                                      _mockImportanceBar('Contract Period', 0.85, Colors.purple),
                                      _mockImportanceBar('Total Charges', 0.65, Colors.blue),
                                      _mockImportanceBar('Customer Service Calls', 0.50, Colors.teal),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mockSidebarIcon(IconData icon, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Icon(
        icon,
        size: 20,
        color: isSelected ? context.primary : context.textSecondary.withOpacity(0.5),
      ),
    );
  }

  Widget _mockStatCard(String label, String value, Color accent, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: context.textSecondary)),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: context.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mockChecklistItem(String title, {required bool checked}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_box : Icons.check_box_outline_blank,
            size: 14,
            color: checked ? context.primary : context.textTertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                color: checked ? context.textSecondary : context.textPrimary,
                decoration: checked ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mockImportanceBar(String name, double factor, Color barColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: TextStyle(fontSize: 10, color: context.textSecondary)),
              Text('${(factor * 100).toInt()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.textPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(height: 5, decoration: BoxDecoration(color: context.border, borderRadius: BorderRadius.circular(3))),
              FractionallySizedBox(
                widthFactor: factor,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(3)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingTiers() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'TRANSPARENT PRICING',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Predictive power for every stage of growth.',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: context.textPrimary,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start free for 14 days. Scale plans as your customer base expands.',
                  style: TextStyle(fontSize: 13, color: context.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _pricingCard(
                    title: 'Growth Plan',
                    price: '\$49',
                    description: 'For small CS teams launching retention policies.',
                    features: [
                      'Up to 1,000 customers monitored',
                      'Standard CatBoost ML models',
                      'Manual playbook assignment',
                      'Email support within 24h',
                    ],
                    onTap: widget.onSignUp,
                    width: isWide ? (constraints.maxWidth - 40) / 3 : constraints.maxWidth,
                  ),
                  _pricingCard(
                    title: 'Scale Plan',
                    price: '\$99',
                    description: 'For scaling customer success organizations.',
                    features: [
                      'Up to 10,000 customers monitored',
                      'Advanced NLP sentiment tagging',
                      'Automated trigger playbooks',
                      'Salesforce & Zendesk Sync status',
                      'Priority support within 4h',
                    ],
                    isRecommended: true,
                    onTap: widget.onSignUp,
                    width: isWide ? (constraints.maxWidth - 40) / 3 : constraints.maxWidth,
                  ),
                  _pricingCard(
                    title: 'Enterprise Plan',
                    price: 'Custom',
                    description: 'For high-volume datasets and customized pipelines.',
                    features: [
                      'Unlimited monitored customers',
                      'Custom localized ML model training',
                      'Full read/write integrations',
                      'SLA guarantees & dedicated CSM',
                      '24/7 Phone & Slack Support',
                    ],
                    onTap: widget.onSignUp,
                    width: isWide ? (constraints.maxWidth - 40) / 3 : constraints.maxWidth,
                  ),
                ],
              );
            },
          ),
        ],
      );
  }

  Widget _pricingCard({
    required String title,
    required String price,
    required String description,
    required List<String> features,
    required VoidCallback? onTap,
    required double width,
    bool isRecommended = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isRecommended ? context.primary.withOpacity(0.02) : context.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isRecommended ? context.primary : context.border,
          width: isRecommended ? 2.5 : 1.5,
        ),
        boxShadow: isRecommended
            ? [
                BoxShadow(
                  color: context.primary.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRecommended) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'RECOMMENDED',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: context.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimary,
                ),
              ),
              if (price != 'Custom') ...[
                const SizedBox(width: 4),
                Text(
                  '/ CSM / month',
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: context.border),
          const SizedBox(height: 24),
          ...features.map((feat) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: isRecommended ? context.primary : context.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feat,
                        style: TextStyle(fontSize: 12.5, color: context.textPrimary),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: isRecommended ? context.primary : context.surfaceVariant,
                foregroundColor: isRecommended ? Colors.white : context.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                price == 'Custom' ? 'Contact Sales' : 'Start Free Trial',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicFooter() {
   return Container(
      width: double.infinity,
      color: context.isDark ? Colors.white.withOpacity(0.01) : Colors.black.withOpacity(0.005),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: isWide ? 4 : 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: context.primaryGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.analytics, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Churn Intelligence',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'AI-driven workspace for enterprise retention metrics.',
                          style: TextStyle(fontSize: 12, color: context.textSecondary, height: 1.5),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          '© 2026 Mortala Production. All rights reserved.',
                          style: TextStyle(fontSize: 10, color: context.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  if (isWide) const SizedBox(width: 48),
                  if (isWide) ...[
                    Expanded(
                      flex: 2,
                      child: _footerColumn('Product', ['Features', 'Integrations', 'Security', 'Pricing']),
                    ),
                    Expanded(
                      flex: 2,
                      child: _footerColumn('Resources', ['API Docs', 'Guides', 'Support Portal', 'System Status']),
                    ),
                    Expanded(
                      flex: 2,
                      child: _footerColumn('Company', ['About Us', 'Careers', 'Blog', 'Press Inquiries']),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _footerColumn(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {},
                  child: Text(
                    link,
                    style: TextStyle(fontSize: 11.5, color: context.textSecondary),
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

class HeaderLinkWidget extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  
  const HeaderLinkWidget({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  State<HeaderLinkWidget> createState() => _HeaderLinkWidgetState();
}

class _HeaderLinkWidgetState extends State<HeaderLinkWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _isHovered 
                ? context.primary.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered 
                  ? context.primary.withOpacity(0.18)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _isHovered ? context.primary : context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
