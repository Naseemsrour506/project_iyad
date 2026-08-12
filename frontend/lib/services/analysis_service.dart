import '../core/api_constants.dart';
import '../models/analysis_result_model.dart';
import 'api_service.dart';

class AnalysisService {
  const AnalysisService({required ApiService api}) : _api = api;

  final ApiService _api;

  /// `POST /api/analyze` — the backend also stores the message and creates an
  /// alert automatically when the risk level is `High`.
  Future<AnalysisResultModel> analyze({
    required int childId,
    required String message,
  }) async {
    final Map<String, dynamic> json = ApiService.asObject(
      await _api.post(
        ApiConstants.analyze,
        body: <String, dynamic>{'child_id': childId, 'message': message},
      ),
    );

    return AnalysisResultModel.fromJson(json);
  }

  /// `POST /api/messages/upload`.
  Future<BatchAnalysisResultModel> uploadCsv({
    required int childId,
    required String filename,
    required List<int> fileBytes,
  }) async {
    final Map<String, dynamic> json = ApiService.asObject(
      await _api.postMultipartFile(
        ApiConstants.messagesUpload,
        fields: <String, String>{'child_id': childId.toString()},
        fileField: 'file',
        filename: filename,
        fileBytes: fileBytes,
      ),
    );

    return BatchAnalysisResultModel.fromJson(json);
  }
}
