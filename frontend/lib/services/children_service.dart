import '../core/api_constants.dart';
import '../models/child_model.dart';
import 'api_service.dart';

class ChildrenService {
  const ChildrenService({required ApiService api}) : _api = api;

  final ApiService _api;

  /// `GET /api/children` — only the current parent's children.
  Future<List<ChildModel>> fetchChildren() async {
    final List<Map<String, dynamic>> json = await _api.getList(
      ApiConstants.children,
    );
    return json.map(ChildModel.fromJson).toList();
  }

  /// `GET /api/children/{child_id}`.
  Future<ChildModel> fetchChild(int childId) async {
    return ChildModel.fromJson(
      await _api.getObject(ApiConstants.child(childId)),
    );
  }

  /// `POST /api/children` — `parent_id` is derived from the JWT by the backend
  /// and must not be sent by the client.
  Future<ChildModel> createChild({
    required String fullName,
    required int age,
  }) async {
    final Map<String, dynamic> json = ApiService.asObject(
      await _api.post(
        ApiConstants.children,
        body: <String, dynamic>{'full_name': fullName, 'age': age},
      ),
    );

    return ChildModel.fromJson(json);
  }
}
