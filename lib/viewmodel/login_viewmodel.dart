import 'package:flutter/foundation.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/core/network.dart';
import 'package:ziesocial/model/user_model.dart';

class LoginViewModel extends ChangeNotifier {
  final ApiClient _apiClient;

  LoginViewModel(this._apiClient);

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _user;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        body: {
          'email': email,
          'password': password,
        },
      );
      _user = UserModel.fromJson(response['user']);
      return true;
    } catch (e) {
      String msg = e.toString();
      if (msg.startsWith('Exception: ')) {
        msg = msg.substring('Exception: '.length);
      } else if (msg.startsWith('FormatException: ')) {
        msg = msg.substring('FormatException: '.length);
      }
      _errorMessage = msg;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}