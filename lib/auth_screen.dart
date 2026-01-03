import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'session.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  bool _submitting = false;
  bool _rememberMe = true;
  bool _checkingStored = true;
  String? _error;

  static const String _apiBase = 'http://160.191.101.179:8000'; // backend base

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final data = json.decode(payload);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return null;
    } catch (_) {
      return null;
    }
  }

  void _storeSessionFromToken(String token) {
    final payload = _decodeJwtPayload(token);
    final sub = payload?['sub']?.toString();
    final email = payload?['email']?.toString();
    final id = sub == null ? null : int.tryParse(sub);
    Session.setSession(jwt: token, id: id, mail: email);
  }

  Future<void> _persistToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final expiry = DateTime.now().add(const Duration(days: 90));
    await prefs.setString('jwt_token', token);
    await prefs.setInt('jwt_expiry', expiry.millisecondsSinceEpoch);
  }

  Future<void> _clearPersistedToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('jwt_expiry');
  }

  Future<void> _tryRestoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final expiryMs = prefs.getInt('jwt_expiry');
      final expiry = expiryMs == null ? null : DateTime.fromMillisecondsSinceEpoch(expiryMs);

      final tokenValid = token != null && expiry != null && expiry.isAfter(DateTime.now());
      if (tokenValid) {
        _storeSessionFromToken(token!);
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Home()));
        return;
      }

      // Token missing or expired: clean up and show auth form
      await _clearPersistedToken();
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Auto-login failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _checkingStored = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tryRestoreSession();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    final hasJwt = Session.token != null && Session.token!.isNotEmpty;
    final path = _isLogin
      ? (hasJwt ? '/auth/login/token' : '/auth/login')
      : '/auth/signup';
    final body = _isLogin
      ? {'email': email, 'password': password}
      : {'email': email, 'password': password, 'display_name': name.isEmpty ? null : name};
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (hasJwt) headers['Authorization'] = 'Bearer ${Session.token}';

    try {
      final resp = await http.post(
        Uri.parse('$_apiBase$path'),
        headers: headers,
        body: json.encode(body),
      );

      if (resp.statusCode == 200) {
        String? token;
        try {
          final data = json.decode(resp.body);
          if (data is Map && data['access_token'] is String) {
            token = data['access_token'] as String;
          }
        } catch (_) {}

        if (token != null) {
          _storeSessionFromToken(token);
          if (_rememberMe) {
            await _persistToken(token);
          } else {
            await _clearPersistedToken();
          }
        } else {
          Session.clear();
        }

        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Home()));
      } else {
        String message = 'Request failed (${resp.statusCode})';
        try {
          final data = json.decode(resp.body);
          if (data is Map && data['detail'] != null) message = data['detail'].toString();
        } catch (_) {}
        if (mounted) {
          setState(() {
            _error = message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingStored) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Log In' : 'Sign Up')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isLogin)
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter email';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter password';
                    if (v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: _rememberMe,
                  onChanged: _submitting
                      ? null
                      : (v) {
                          if (v == null) return;
                          setState(() => _rememberMe = v);
                        },
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Stay logged in for 3 months'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isLogin ? 'Log In' : 'Sign Up'),
                  ),
                ),
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _error = null;
                          });
                        },
                  child: Text(_isLogin ? 'Need an account? Sign up' : 'Have an account? Log in'),
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                // OAuth placeholders – wire real flows later
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.account_circle),
                    label: const Text('Continue with Google'),
                    onPressed: () {
                      setState(() => _error = 'Google OAuth flow not implemented in UI yet');
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.facebook),
                    label: const Text('Continue with Facebook'),
                    onPressed: () {
                      setState(() => _error = 'Facebook OAuth flow not implemented in UI yet');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
