import '../core/api_constants.dart';
import '../models/message_model.dart';
import 'api_service.dart';

class MessagesService {
  const MessagesService({required ApiService api}) : _api = api;

  final ApiService _api;

  /// `GET /api/messages`, optionally filtered with `?child_id=`.
  Future<List<AnalyzedMessageModel>> fetchMessages({int? childId}) async {
    final List<Map<String, dynamic>> json = await _api.getList(
      ApiConstants.messages,
      query: childId == null ? null : <String, dynamic>{'child_id': childId},
    );

    return json.map(AnalyzedMessageModel.fromJson).toList();
  }
}
