import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

/// ── Customer Input Form ────────────────────────────────────────────────────
/// Tabbed form for collecting all customer data fields
class CustomerForm extends StatefulWidget {
  final Customer? initialData;
  final bool isLoading;
  final void Function(Customer customer) onSubmit;

  const CustomerForm({
    super.key,
    this.initialData,
    this.isLoading = false,
    required this.onSubmit,
  });

  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  late Customer _customer;

  // Controllers
  final _customerIdController = TextEditingController();
  final _tenureController = TextEditingController();
  final _monthlyChargesController = TextEditingController();
  final _totalChargesController = TextEditingController();
  final _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _customer = widget.initialData ?? Customer();
    _initControllers();
  }

  void _initControllers() {
    _customerIdController.text = _customer.customerID;
    _tenureController.text =
        _customer.tenure > 0 ? _customer.tenure.toString() : '';
    _monthlyChargesController.text =
        _customer.monthlyCharges > 0
            ? _customer.monthlyCharges.toString()
            : '';
    _totalChargesController.text =
        _customer.totalCharges > 0 ? _customer.totalCharges.toString() : '';
    _feedbackController.text = _customer.customerFeedback;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customerIdController.dispose();
    _tenureController.dispose();
    _monthlyChargesController.dispose();
    _totalChargesController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _loadSampleData() {
    setState(() {
      _customer = Customer.sample();
      _initControllers();
    });
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _customer.customerID = _customerIdController.text;
      _customer.tenure = int.tryParse(_tenureController.text) ?? 0;
      _customer.monthlyCharges =
          double.tryParse(_monthlyChargesController.text) ?? 0;
      _customer.totalCharges =
          double.tryParse(_totalChargesController.text) ?? 0;
      _customer.customerFeedback = _feedbackController.text;
      widget.onSubmit(_customer);
    } else {
      // Find the first invalid tab and navigate to it
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fix the validation errors'),
          backgroundColor: context.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // ── Tab bar (Inspired by Vitally segmented sliders)
          Container(
            decoration: BoxDecoration(
              color: context.isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: context.primary,
              unselectedLabelColor: context.textSecondary,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(6),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: const [
                Tab(
                    icon: Icon(Icons.person_outline, size: 18),
                    text: 'Personal'),
                Tab(
                    icon: Icon(Icons.wifi_outlined, size: 18),
                    text: 'Services'),
                Tab(
                    icon: Icon(Icons.payment_outlined, size: 18),
                    text: 'Billing'),
                Tab(
                    icon: Icon(Icons.rate_review_outlined, size: 18),
                    text: 'Feedback'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Tab views
          SizedBox(
            height: 360,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPersonalTab(),
                _buildServicesTab(),
                _buildBillingTab(),
                _buildFeedbackTab(),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Action buttons
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: widget.isLoading ? null : _loadSampleData,
                icon: const Icon(Icons.auto_fix_high, size: 18),
                label: Text('Load Sample'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: widget.isLoading ? null : _handleSubmit,
                  icon: widget.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.analytics, size: 18),
                  label: Text(
                    widget.isLoading ? 'Analyzing...' : 'Predict Churn',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: context.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ── Personal Tab ─────────────────────────────────────────────────────────
  Widget _buildPersonalTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTextField(
            controller: _customerIdController,
            label: 'Customer ID',
            hint: 'e.g. 7590-VHVEG',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Gender',
                  value: _customer.gender,
                  items: ['Male', 'Female'],
                  icon: Icons.wc,
                  onChanged: (v) => setState(() => _customer.gender = v!),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildDropdown(
                  label: 'Senior Citizen',
                  value: _customer.seniorCitizen == 1 ? 'Yes' : 'No',
                  items: ['No', 'Yes'],
                  icon: Icons.elderly,
                  onChanged: (v) => setState(
                      () => _customer.seniorCitizen = v == 'Yes' ? 1 : 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Partner',
                  value: _customer.partner,
                  items: ['Yes', 'No'],
                  icon: Icons.people_outline,
                  onChanged: (v) =>
                      setState(() => _customer.partner = v!),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildDropdown(
                  label: 'Dependents',
                  value: _customer.dependents,
                  items: ['Yes', 'No'],
                  icon: Icons.child_care,
                  onChanged: (v) =>
                      setState(() => _customer.dependents = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _tenureController,
            label: 'Tenure (months)',
            hint: 'Number of months',
            icon: Icons.calendar_today,
            keyboardType: TextInputType.number,
            validator: Validators.tenure,
          ),
        ],
      ),
    );
  }

  /// ── Services Tab ─────────────────────────────────────────────────────────
  Widget _buildServicesTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Internet Service',
                  value: _customer.internetService,
                  items: ['DSL', 'Fiber optic', 'No'],
                  icon: Icons.wifi,
                  onChanged: (v) =>
                      setState(() => _customer.internetService = v!),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildDropdown(
                  label: 'Contract',
                  value: _customer.contract,
                  items: ['Month-to-month', 'One year', 'Two year'],
                  icon: Icons.description_outlined,
                  onChanged: (v) =>
                      setState(() => _customer.contract = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Phone Service',
                  value: _customer.phoneService,
                  items: ['Yes', 'No'],
                  icon: Icons.phone,
                  onChanged: (v) =>
                      setState(() => _customer.phoneService = v!),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildDropdown(
                  label: 'Multiple Lines',
                  value: _customer.multipleLines,
                  items: ['Yes', 'No', 'No phone service'],
                  icon: Icons.phone_forwarded,
                  onChanged: (v) =>
                      setState(() => _customer.multipleLines = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Online Security',
                  value: _customer.onlineSecurity,
                  items: ['Yes', 'No', 'No internet service'],
                  icon: Icons.security,
                  onChanged: (v) =>
                      setState(() => _customer.onlineSecurity = v!),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildDropdown(
                  label: 'Online Backup',
                  value: _customer.onlineBackup,
                  items: ['Yes', 'No', 'No internet service'],
                  icon: Icons.cloud_upload_outlined,
                  onChanged: (v) =>
                      setState(() => _customer.onlineBackup = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Device Protection',
                  value: _customer.deviceProtection,
                  items: ['Yes', 'No', 'No internet service'],
                  icon: Icons.phonelink_lock,
                  onChanged: (v) =>
                      setState(() => _customer.deviceProtection = v!),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildDropdown(
                  label: 'Tech Support',
                  value: _customer.techSupport,
                  items: ['Yes', 'No', 'No internet service'],
                  icon: Icons.support_agent,
                  onChanged: (v) =>
                      setState(() => _customer.techSupport = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Streaming TV',
                  value: _customer.streamingTV,
                  items: ['Yes', 'No', 'No internet service'],
                  icon: Icons.tv,
                  onChanged: (v) =>
                      setState(() => _customer.streamingTV = v!),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildDropdown(
                  label: 'Streaming Movies',
                  value: _customer.streamingMovies,
                  items: ['Yes', 'No', 'No internet service'],
                  icon: Icons.movie_outlined,
                  onChanged: (v) =>
                      setState(() => _customer.streamingMovies = v!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ── Billing Tab ──────────────────────────────────────────────────────────
  Widget _buildBillingTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildDropdown(
            label: 'Paperless Billing',
            value: _customer.paperlessBilling,
            items: ['Yes', 'No'],
            icon: Icons.email_outlined,
            onChanged: (v) =>
                setState(() => _customer.paperlessBilling = v!),
          ),
          const SizedBox(height: 14),
          _buildDropdown(
            label: 'Payment Method',
            value: _customer.paymentMethod,
            items: [
              'Electronic check',
              'Mailed check',
              'Bank transfer (automatic)',
              'Credit card (automatic)',
            ],
            icon: Icons.payment,
            onChanged: (v) =>
                setState(() => _customer.paymentMethod = v!),
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _monthlyChargesController,
            label: 'Monthly Charges (\$)',
            hint: 'e.g. 79.85',
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
            validator: Validators.monthlyCharges,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _totalChargesController,
            label: 'Total Charges (\$)',
            hint: 'e.g. 3046.05',
            icon: Icons.account_balance_wallet_outlined,
            keyboardType: TextInputType.number,
            validator: Validators.totalCharges,
          ),
        ],
      ),
    );
  }

  /// ── Feedback Tab ─────────────────────────────────────────────────────────
  Widget _buildFeedbackTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Feedback',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This will be analyzed by our NLP engine using Sentence Transformers for sentiment analysis.',
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _feedbackController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText:
                  'Enter customer feedback, complaints, or comments...',
              hintStyle: TextStyle(color: context.textTertiary),
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 12, bottom: 80),
                child: Icon(Icons.rate_review_outlined, size: 20),
              ),
              filled: true,
              fillColor: context.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.border),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Quick feedback templates
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _feedbackChip('😊 Great service, very satisfied'),
              _feedbackChip('😐 Service is okay, nothing special'),
              _feedbackChip('😤 Too expensive, poor connection'),
              _feedbackChip('📞 Bad support, long wait times'),
              _feedbackChip('🐌 Very slow internet, frequent outages'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _feedbackChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 11)),
      onPressed: () {
        _feedbackController.text = text.substring(2).trim();
      },
      backgroundColor: context.surfaceVariant,
      side: BorderSide(color: context.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  /// ── Reusable Widgets ─────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        labelStyle: const TextStyle(fontSize: 13),
        hintStyle: TextStyle(color: context.textTertiary, fontSize: 13),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : items.first,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        labelStyle: const TextStyle(fontSize: 13),
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item, style: const TextStyle(fontSize: 13)),
              ))
          .toList(),
      onChanged: onChanged,
      isExpanded: true,
      style: TextStyle(
        fontSize: 13,
        color: context.textPrimary,
      ),
    );
  }
}
