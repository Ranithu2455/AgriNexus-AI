import 'dart:io';

import '../api/api_client.dart';
import '../api/token_storage.dart';
import '../models/user.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _client = ApiClient.instance;
  final _tokenStorage = TokenStorage.instance;

  Future<AppUser> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final data = await _client.post(
      '/users/register',
      auth: false,
      body: {
        'email': email,
        'password': password,
        'full_name': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  Future<void> login({required String email, required String password}) async {
    final data = await _client.post(
      '/users/login',
      auth: false,
      body: {'email': email, 'password': password},
    );
    await _tokenStorage.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
  }

  Future<void> logout() async {
    try {
      await _client.post('/users/logout');
    } catch (_) {
      // Even if the server call fails, clear local tokens so the user is
      // logged out on-device.
    }
    await _tokenStorage.clear();
  }

  Future<bool> isLoggedIn() async {
    return (await _tokenStorage.getAccessToken()) != null;
  }

  Future<AppUser> getCurrentUser() async {
    final data = await _client.get('/users/me');
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  Future<FarmerProfile> updateProfile({
    String? fullName,
    String? district,
    String? location,
    String? farmerInfo,
  }) async {
    final data = await _client.put('/users/me/profile', body: {
      if (fullName != null) 'full_name': fullName,
      if (district != null) 'district': district,
      if (location != null) 'location': location,
      if (farmerInfo != null) 'farmer_info': farmerInfo,
    });
    return FarmerProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<FarmerProfile> uploadProfileImage(File image) async {
    final data = await _client.uploadFile(
      '/users/me/profile/image',
      file: image,
      fieldName: 'file',
    );
    return FarmerProfile.fromJson(data as Map<String, dynamic>);
  }
}
