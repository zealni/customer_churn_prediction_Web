import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/prediction.dart';
import '../services/api_service.dart';

/// ── Prediction Provider ────────────────────────────────────────────────────
/// State management for prediction operations
class PredictionProvider extends ChangeNotifier {
  final ApiService _apiService;

  // State
  bool _isLoading = false;
  String? _error;
  PredictionResult? _lastPrediction;
  BatchPredictionResult? _batchResult;
  List<PredictionResult> _history = [];
  HealthCheck? _healthStatus;
  ModelMetrics? _metrics;
  bool _isApiConnected = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  PredictionResult? get lastPrediction => _lastPrediction;
  BatchPredictionResult? get batchResult => _batchResult;
  List<PredictionResult> get history => List.unmodifiable(_history);
  HealthCheck? get healthStatus => _healthStatus;
  ModelMetrics? get metrics => _metrics;
  bool get isApiConnected => _isApiConnected;

  PredictionProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// ── Check API Health ─────────────────────────────────────────────────────
  Future<void> checkApiHealth() async {
    try {
      _healthStatus = await _apiService.checkHealth();
      _isApiConnected = _healthStatus?.isHealthy ?? false;
      _error = null;
    } catch (e) {
      _isApiConnected = false;
      _healthStatus = null;
    }
    notifyListeners();
  }

  /// ── Load Metrics ─────────────────────────────────────────────────────────
  Future<void> loadMetrics() async {
    try {
      _metrics = await _apiService.getMetrics();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  /// ── Single Prediction ────────────────────────────────────────────────────
  Future<PredictionResult?> predictCustomer(Customer customer) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.predictCustomer(customer);
      _lastPrediction = result;
      await loadHistory();

      

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// ── Batch Prediction ─────────────────────────────────────────────────────
  Future<BatchPredictionResult?> predictBatch(
      List<Customer> customers) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.predictBatch(customers);
      _batchResult = result;

      await loadHistory();

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }


  /// ── Load History ─────────────────────────────────────────────────────────
  Future<void> loadHistory() async {
    try {
      _history = await _apiService.getHistory();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// ── Clear Error ──────────────────────────────────────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// ── Clear Results ────────────────────────────────────────────────────────
  void clearLastPrediction() {
    _lastPrediction = null;
    notifyListeners();
  }

  void clearBatchResult() {
    _batchResult = null;
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  Future<void> deleteHistoryBatch(List<int> ids) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteHistoryBatch(ids);
      await loadHistory();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteDuplicates() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteDuplicates();
      await loadHistory();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
