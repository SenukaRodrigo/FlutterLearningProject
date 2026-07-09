import 'package:flutter/foundation.dart';

import '../../../../data/repositories/user_repository.dart';
import '../../../../domain/models/user.dart';

/// Presentation state for the Profile tab.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this._repository) {
    load();
  }

  final UserRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  User? _user;
  User? get user => _user;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _user = await _repository.fetchCurrentUser();

    _isLoading = false;
    notifyListeners();
  }
}
