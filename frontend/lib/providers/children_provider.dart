import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/child_model.dart';
import '../services/children_service.dart';

class ChildrenProvider extends ChangeNotifier {
  ChildrenProvider({required ChildrenService childrenService})
    : _childrenService = childrenService;

  final ChildrenService _childrenService;

  List<ChildModel> _children = <ChildModel>[];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _hasLoadedOnce = false;

  List<ChildModel> get children => List<ChildModel>.unmodifiable(_children);
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get hasLoadedOnce => _hasLoadedOnce;
  bool get isEmpty => _hasLoadedOnce && _children.isEmpty;

  ChildModel? childById(int childId) {
    for (final ChildModel child in _children) {
      if (child.childId == childId) return child;
    }
    return null;
  }

  /// Name for a child id, used by history and alert lists.
  String childName(int childId) =>
      childById(childId)?.fullName ?? 'ילד #$childId';

  Future<void> loadChildren({bool force = false}) async {
    if (_isLoading) return;
    if (_hasLoadedOnce && !force) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _children = await _childrenService.fetchChildren();
      _hasLoadedOnce = true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'אירעה שגיאה בטעינת הילדים.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a child and refreshes the list. Returns null on success, or a
  /// Hebrew error message on failure.
  Future<String?> addChild({required String fullName, required int age}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _childrenService.createChild(fullName: fullName, age: age);
      _children = await _childrenService.fetchChildren();
      _hasLoadedOnce = true;
      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'אירעה שגיאה בהוספת הילד.';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void reset() {
    _children = <ChildModel>[];
    _isLoading = false;
    _isSubmitting = false;
    _errorMessage = null;
    _hasLoadedOnce = false;
    notifyListeners();
  }
}
