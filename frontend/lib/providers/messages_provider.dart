import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/analysis_result_model.dart';
import '../models/message_model.dart';
import '../services/analysis_service.dart';
import '../services/messages_service.dart';

/// Holds both message history and the most recent analysis result, since the
/// two always move together: analyzing a message adds it to the history.
class MessagesProvider extends ChangeNotifier {
  MessagesProvider({
    required MessagesService messagesService,
    required AnalysisService analysisService,
  }) : _messagesService = messagesService,
       _analysisService = analysisService;

  final MessagesService _messagesService;
  final AnalysisService _analysisService;

  List<AnalyzedMessageModel> _messages = <AnalyzedMessageModel>[];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasLoadedOnce = false;

  /// null means "all children".
  int? _selectedChildFilter;

  bool _isAnalyzing = false;
  bool _isUploadingCsv = false;
  AnalysisResultModel? _lastResult;
  BatchAnalysisResultModel? _lastUploadResult;
  String? _analysisError;

  List<AnalyzedMessageModel> get messages =>
      List<AnalyzedMessageModel>.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasLoadedOnce => _hasLoadedOnce;
  int? get selectedChildFilter => _selectedChildFilter;
  bool get isEmpty => _hasLoadedOnce && _messages.isEmpty;

  bool get isAnalyzing => _isAnalyzing;
  bool get isUploadingCsv => _isUploadingCsv;
  bool get isBusy => _isAnalyzing || _isUploadingCsv;
  AnalysisResultModel? get lastResult => _lastResult;
  BatchAnalysisResultModel? get lastUploadResult => _lastUploadResult;
  String? get analysisError => _analysisError;

  Future<void> loadMessages({bool force = false}) async {
    if (_isLoading) return;
    if (_hasLoadedOnce && !force) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _messages = await _messagesService.fetchMessages(
        childId: _selectedChildFilter,
      );
      _hasLoadedOnce = true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'אירעה שגיאה בטעינת ההיסטוריה.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Changes the child filter and reloads from the backend.
  Future<void> setChildFilter(int? childId) async {
    if (_selectedChildFilter == childId) return;

    _selectedChildFilter = childId;
    notifyListeners();
    await loadMessages(force: true);
  }

  /// Analyzes a message. Returns the result, or null when the call failed
  /// (the Hebrew reason is then available in [analysisError]).
  Future<AnalysisResultModel?> analyzeMessage({
    required int childId,
    required String message,
  }) async {
    _isAnalyzing = true;
    _analysisError = null;
    notifyListeners();

    try {
      final AnalysisResultModel result = await _analysisService.analyze(
        childId: childId,
        message: message,
      );

      _lastResult = result;
      _lastUploadResult = null;

      // The new message belongs in the history the next time it is opened.
      _hasLoadedOnce = false;
      return result;
    } on ApiException catch (error) {
      _analysisError = error.message;
      return null;
    } catch (_) {
      _analysisError = 'אירעה שגיאה בניתוח ההודעה.';
      return null;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<BatchAnalysisResultModel?> uploadCsvMessages({
    required int childId,
    required String filename,
    required List<int> fileBytes,
  }) async {
    _isUploadingCsv = true;
    _analysisError = null;
    notifyListeners();

    try {
      final BatchAnalysisResultModel result = await _analysisService.uploadCsv(
        childId: childId,
        filename: filename,
        fileBytes: fileBytes,
      );

      _lastUploadResult = result;
      _lastResult = result.results.isEmpty ? null : result.results.first;

      // Uploaded messages belong in the history the next time it is opened.
      _hasLoadedOnce = false;
      return result;
    } on ApiException catch (error) {
      _analysisError = error.message;
      return null;
    } catch (_) {
      _analysisError = 'אירעה שגיאה בהעלאת קובץ ה-CSV.';
      return null;
    } finally {
      _isUploadingCsv = false;
      notifyListeners();
    }
  }

  void clearLastResult() {
    _lastResult = null;
    _lastUploadResult = null;
    _analysisError = null;
    notifyListeners();
  }

  void reset() {
    _messages = <AnalyzedMessageModel>[];
    _isLoading = false;
    _errorMessage = null;
    _hasLoadedOnce = false;
    _selectedChildFilter = null;
    _isAnalyzing = false;
    _isUploadingCsv = false;
    _lastResult = null;
    _lastUploadResult = null;
    _analysisError = null;
    notifyListeners();
  }
}
