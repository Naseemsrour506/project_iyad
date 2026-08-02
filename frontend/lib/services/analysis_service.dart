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
}
