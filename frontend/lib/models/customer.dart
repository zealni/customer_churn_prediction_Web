import 'dart:convert';

/// ── Customer Data Model ────────────────────────────────────────────────────
class Customer {
  String customerID;
  String gender;
  int seniorCitizen;
  String partner;
  String dependents;
  int tenure;
  String contract;
  String internetService;
  String phoneService;
  String multipleLines;
  String onlineSecurity;
  String onlineBackup;
  String deviceProtection;
  String techSupport;
  String streamingTV;
  String streamingMovies;
  String paperlessBilling;
  String paymentMethod;
  double monthlyCharges;
  double totalCharges;
  String customerFeedback;

  Customer({
    this.customerID = '',
    this.gender = 'Male',
    this.seniorCitizen = 0,
    this.partner = 'No',
    this.dependents = 'No',
    this.tenure = 0,
    this.contract = 'Month-to-month',
    this.internetService = 'Fiber optic',
    this.phoneService = 'No',
    this.multipleLines = 'No',
    this.onlineSecurity = 'No',
    this.onlineBackup = 'No',
    this.deviceProtection = 'No',
    this.techSupport = 'No',
    this.streamingTV = 'No',
    this.streamingMovies = 'No',
    this.paperlessBilling = 'Yes',
    this.paymentMethod = 'Electronic check',
    this.monthlyCharges = 0.0,
    this.totalCharges = 0.0,
    this.customerFeedback = '',
  });

  Map<String, dynamic> toJson() => {
        'customerID': customerID.isEmpty ? 'CUST-${DateTime.now().millisecondsSinceEpoch}' : customerID,
        'gender': gender,
        'SeniorCitizen': seniorCitizen,
        'Partner': partner,
        'Dependents': dependents,
        'tenure': tenure,
        'Contract': contract,
        'InternetService': internetService,
        'PhoneService': phoneService,
        'MultipleLines': multipleLines,
        'OnlineSecurity': onlineSecurity,
        'OnlineBackup': onlineBackup,
        'DeviceProtection': deviceProtection,
        'TechSupport': techSupport,
        'StreamingTV': streamingTV,
        'StreamingMovies': streamingMovies,
        'PaperlessBilling': paperlessBilling,
        'PaymentMethod': paymentMethod,
        'MonthlyCharges': monthlyCharges,
        'TotalCharges': totalCharges,
        'CustomerFeedback': customerFeedback,
      };

  String toJsonString() => jsonEncode(toJson());

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerID: json['customerID'] ?? '',
      gender: json['gender'] ?? 'Male',
      seniorCitizen: json['SeniorCitizen'] ?? 0,
      partner: json['Partner'] ?? 'No',
      dependents: json['Dependents'] ?? 'No',
      tenure: json['tenure'] ?? 0,
      contract: json['Contract'] ?? 'Month-to-month',
      internetService: json['InternetService'] ?? 'Fiber optic',
      phoneService: json['PhoneService'] ?? 'No',
      multipleLines: json['MultipleLines'] ?? 'No',
      onlineSecurity: json['OnlineSecurity'] ?? 'No',
      onlineBackup: json['OnlineBackup'] ?? 'No',
      deviceProtection: json['DeviceProtection'] ?? 'No',
      techSupport: json['TechSupport'] ?? 'No',
      streamingTV: json['StreamingTV'] ?? 'No',
      streamingMovies: json['StreamingMovies'] ?? 'No',
      paperlessBilling: json['PaperlessBilling'] ?? 'Yes',
      paymentMethod: json['PaymentMethod'] ?? 'Electronic check',
      monthlyCharges: (json['MonthlyCharges'] ?? 0).toDouble(),
      totalCharges: (json['TotalCharges'] ?? 0).toDouble(),
      customerFeedback: json['CustomerFeedback'] ?? '',
    );
  }

  /// Creates a sample customer for demo purposes
  factory Customer.sample() {
    return Customer(
      customerID: '7590-VHVEG',
      gender: 'Female',
      seniorCitizen: 0,
      partner: 'Yes',
      dependents: 'No',
      tenure: 1,
      contract: 'Month-to-month',
      internetService: 'DSL',
      phoneService: 'No',
      multipleLines: 'No',
      onlineSecurity: 'No',
      onlineBackup: 'Yes',
      deviceProtection: 'No',
      techSupport: 'No',
      streamingTV: 'No',
      streamingMovies: 'No',
      paperlessBilling: 'Yes',
      paymentMethod: 'Electronic check',
      monthlyCharges: 29.85,
      totalCharges: 29.85,
      customerFeedback: 'Service is okay but sometimes slow',
    );
  }
}
